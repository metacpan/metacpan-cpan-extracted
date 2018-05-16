# DbgrProperties.pm -- Move all the property-handling code
# into this module.
#
# Copyright (c) 1998-2006 ActiveState Software Inc.
# All rights reserved.
# 
# Xdebug compatibility, UNIX domain socket support and misc fixes
# by Mattia Barbon <mattia@barbon.org>
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).

package DB::DbgrContext;

use strict qw(vars subs);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	     emitContextNames
	     emitContextProperties
	     getContextProperties
	     getProximityVarsViaPadWalker
	     hasPadWalker
	     GlobalVars
	     LocalVars
	     FunctionArguments
	     PunctuationVariables
	     );
our @EXPORT_OK = ();

use DB::DbgrCommon;
use DB::DbgrProperties;

use constant LocalVars => 0;
use constant GlobalVars => 1;
use constant FunctionArguments => 2;
use constant PunctuationVariables => 3;

our $ldebug = 0;

my %contextProperties = (
    Globals => GlobalVars,
    Locals => LocalVars,
    Arguments => FunctionArguments,
    Special => PunctuationVariables,
);
my @contextProperties = sort { $contextProperties{$a} <=> $contextProperties{$b} } keys %contextProperties;

my @_punctuationVariables = ('$_', '$?', '$@', '$.', '@+', '@-', '$+', '$!', '$$', '$0');
# $`, $& and $' are special-cased to avoid the performance penalty
my @_rxPunctuationVariables = ('`', '&', '\'');

sub emitContextNames($$) {
    my ($cmd, $transactionID) = @_;
    my $res = sprintf(qq(%s\n<response %s command="%s" 
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $transactionID);
    # todo: the spec suggests that locals be the default,
    # but globals (package globals) make more sense for Perl.
    for (my $i = 0; $i <= $#contextProperties; $i++) {
	$res .= sprintf(qq(<context name="%s" id="%d" />\n),
			$contextProperties[$i],
			$i);
    }
    $res .= "\n</response>\n";
    printWithLength($res);
}

# Return a ref to an array of [name, value, needValue] triples
#
# Some values can be evaluated in this scope, but non-package values
# and locals at the top-level will need to be evaluated in the
# debugger's main loop.

sub getContextProperties($$) {
    my ($context_id, $packageName) = @_;

    # Here just show the top-level.
    local $settings{max_depth}[0] = 0;
    if ($context_id == GlobalVars) {
	require B if $] >= 5.010;
	# Globals
	# Variables on the calling frame
	my $stash = \%{"${packageName}::"};
	my @results;
	for my $key (keys %$stash) {
	    next if $key =~ /^(?:_<|[^0a-zA-Z_])/;
	    next if $key =~ /::$/;
	    my $glob = \($stash->{$key});
	    my ($has_scalar, $is_glob);
	    if ($] >= 5.010) {
		my $gv = B::svref_2object($glob);
		$is_glob = $gv->isa("B::GV");
		$has_scalar = $is_glob && !$gv->SV->isa('B::SPECIAL');
	    } else {
		$is_glob = 1;
		$has_scalar = defined ${*{$glob}{SCALAR}};
	    }
	    my $array = $is_glob && *{$glob}{ARRAY};
	    my $hash = $is_glob && *{$glob}{HASH};
	    next unless $has_scalar || $array || $hash;
	    push @results, ["\$${key}", ${*{$glob}{SCALAR}}, 0] if $has_scalar;
	    push @results, ["\@${key}", $array, 0] if $array;
	    push @results, ["\%${key}", $hash, 0] if $hash;
	}
	return \@results;
    } elsif ($context_id == PunctuationVariables) {
	my @results;
	foreach my $pv (@_punctuationVariables) {
	    push (@results, [$pv, undef, 1]);
	}
	foreach my $pv (@_rxPunctuationVariables) {
	    # somebody might use @' and trigger the condition, I'm willing to risk it
	    push (@results, ["\$$pv", undef, exists $main::{$pv} ? 1 : 0]);
	}
	return \@results;
    } else {
	die sprintf("code:%d:error:%s",
		    302,
		    ("Not ready to evaluate "
		     . $contextProperties[$context_id]
		     . ' variables'));
    }
}

sub emitContextProperties($$$$;$) {
    my ($cmd,
	$transactionID,
	$context_id,
	$nameValuesARef,
	$maxDataSize) = @_;
    
    my $res = sprintf(qq(%s\n<response %s command="%s"
			 context_id="%d"
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $context_id,
		      $transactionID);
    my @results = @$nameValuesARef;
    my $numVars = scalar @results;
    for (my $i = 0; $i < $numVars; $i++) {
	my $result = $results[$i];
	my $name = $result->[0];
	my $val = $result->[1];
	eval {
	    my $property = getFullPropertyInfoByValue($name,
						      $name,
						      $val,
						      $maxDataSize,
						      0,
						      0);
	    # dblog("emitContextProperties: getFullPropertyInfoByValue => $property") if $ldebug;
	    $res .= $property;
	};
	if ($@) {
	    dblog("emitContextProperties: error [$@]") if $ldebug;
	}
    }
    $res .= "\n</response>";
    printWithLength($res);
}

sub _hasActiveArrayIterator {
    my ($b) = @_;
    for (my $magic = $b->MAGIC ; $magic; $magic = $magic->MOREMAGIC) {
        next if $magic->TYPE ne '@';
        # undocumented internals? which undocumented internals?
        return $Config::Config{ivsize} == 4 ||
                 ($] >= 5.027006 &&
                  $Config::Config{sizesize} == $Config::Config{ivsize}) ?
            $magic->LENGTH :
            unpack('j', $magic->PTR) != 0;
    }
    return 0;
}

sub _hasActiveIterator {
    my ($sigil, $vref) = @_;
    require B;
    if ($sigil eq '$' && (my $kind = ref $$vref)) {
        if ($kind eq 'ARRAY') {
            return _hasActiveArrayIterator(B::svref_2object($$vref));
        } elsif ($kind eq 'HASH') {
            return B::svref_2object($$vref)->RITER != -1;
        }
    } elsif ($sigil eq '@') {
        return _hasActiveArrayIterator(B::svref_2object($vref));
    } elsif ($sigil eq '%') {
        return B::svref_2object($vref)->RITER != -1;
    }
}

sub getProximityVarsViaPadWalker($$$$) {
    my ($pkg, $filename, $line, $stackDepth) = @_;
    $stackDepth += 2; # Because we're two levels above the user code here.
    my $my_var_hash = PadWalker::peek_my($stackDepth);
    my $our_var_hash = PadWalker::peek_our($stackDepth);
    my %merged_vars = (%$my_var_hash, %$our_var_hash);
    our @dbline;
    local *dbline = $main::{'_<' . $filename};
    my $sourceText = join("\n", @dbline);

    my @results = ();
    while(my($k, $v) = each %merged_vars) {
	my $sigil = substr($k, 0, 1);
	if (!_hasActiveIterator($sigil, $v)) {
	    push(@results, [$k, $sigil eq '$' ? $$v : $v, 0]);
	} elsif ($ldebug) {
	    dblog("Skipping $k because it has an active iterator");
	}
    }
    if (! exists $merged_vars{'$_'}) {
	my $dollar_under_val = eval('$_');
	if (defined $dollar_under_val) {
	    push(@results, ['$_', $dollar_under_val, 0]);
	}
    }
    return \@results;
}

{
    # needs to be defined in package DB, otherwise eval "" sees a package
    # which is not "DB" and uses it to get the lexical context
    package DB;

    sub getProximityVarsViaB($$$$) {
	package DB::DbgrContext;
	my ($pkg, $filename, $line, $stackDepth) = @_;
	# there is no accurate way of getting these without PadWalker, and
	# there is not way to get the values without PadWalker anyway
	return [] if $stackDepth != 0;
	require B;
	undef *lex_var_hook;
	my $b_cv = eval "sub DB::lex_var_hook {};
			 B::svref_2object(\\&DB::lex_var_hook)->OUTSIDE->OUTSIDE";
	my ($evaltext, %vars, @vars) = ('');
	for ( ; $b_cv && !$b_cv->isa('B::SPECIAL'); $b_cv = $b_cv->OUTSIDE) {
	    my $pad = $b_cv->PADLIST->ARRAYelt(0);
	    for my $i (1 .. ($] < 5.022 ? $pad->FILL : $pad->MAX)) {
		my $v = $pad->ARRAYelt($i);
		next if $v->isa('B::SPECIAL') || !$v->LEN;
		my $name = $] < 5.022 ? ${$v->object_2svref} : $v->PV;
		next if $vars{$name};
		$vars{$name} = 1;
		push @vars, $name;
		# take a reference to avoid resetting hash iterators
		$evaltext .= "scalar eval '\\$name',\n";
	    }
	}
	DB::simple_eval("use strict; \@DB::lex_vars_list = ($evaltext)");
	my @results;
	for my $i (0 .. $#DB::lex_vars_list) {
	    next unless my $value = $DB::lex_vars_list[$i];
	    my $sigil = substr($vars[$i], 0, 1);
	    if (!_hasActiveIterator($sigil, $value)) {
		push @results, [$vars[$i], $sigil eq '$' ? $$value : $value, 0];
	    } elsif ($ldebug) {
		dblog("Skipping $vars[$i] because it has an active iterator");
	    }
	}
	return \@results;
    }
}

# -1: unknown, 0: no, 1:yes  #### Do not init as 1, only -1 or 0.
# bug 93570 - allow padwalker detection/use to be disabled
my $havePadWalker = $ENV{DBGP_PERL_IGNORE_PADWALKER} ? 0 : -1;

sub hasPadWalker {
    if ($havePadWalker == -1) {
        local $@;
        eval {
            require PadWalker;
            PadWalker->VERSION(0.08);
            $havePadWalker = 1;
        };
        if ($@) {
            $havePadWalker = 0;
        }
    }
    return $havePadWalker;
}

1;
