package Devel::DumpTrace;
## no critic (NoStrict,StringyEval)

use 5.008000;
use Hash::SafeKeys;
use PadWalker;
use Scalar::Util 1.14;
use Text::Shorten;
use Devel::DumpTrace::CachedDisplayedArray;
use Devel::DumpTrace::CachedDisplayedHash;
use IO::Handle;
use File::Temp;
use Carp;
use Fcntl qw(:flock :seek);
use strict;
use warnings;

our $VERSION = '0.26';

my $Time_HiRes_avail;
my $color_avail;

BEGIN {
    # compile Devel::DumpTrace::Const AFTER the environment is processed
    if (defined $ENV{DUMPTRACE}) {
        my $kv_splitter = $ENV{DUMPTRACE}=~/;/ ? ';' : ',';
	foreach my $kv (split $kv_splitter, $ENV{DUMPTRACE}) {
	    my ($k,$v) = split /=/, $kv, 2;
	    $ENV{"DUMPTRACE_$k"} = $v;
	}
    }

    $Time_HiRes_avail = eval 'use Time::HiRes qw(time);1' || 0;
    $color_avail = eval
        'use Term::ANSIColor;$Term::ANSIColor::VERSION>=3.00' || 0;

    # idea from Devel::GlobalDestruction 0.13
    # replace $_GLOBAL_DESTRUCTION used in earlier versions
    if (defined ${^GLOBAL_PHASE}) {
        eval 'sub __inGD(){${^GLOBAL_PHASE}eq q{DESTRUCT}&&__END()};1';
    } else {
        require B;
        eval 'sub __inGD(){${B::main_cv()}==0&&__END();};1';
    }
}
use Devel::DumpTrace::Const;

our $ARRAY_ELEM_SEPARATOR = ',';
our $HASH_ENTRY_SEPARATOR = ';';
our $HASH_PAIR_SEPARATOR = '=>';
our $XEVAL_SEPARATOR = ':';
our $SEPARATOR = "-------------------------------------------\n";

my $pid = $$;
our $DUMPTRACE_FH;
our $DUMPTRACE_COLOR;
our $SMART_ABBREV = 1;
our $DB_ARGS_DEPTH = 3;
our %EXCLUDE_PKG = ();
our %INCLUDE_PKG = ('main' => 1);
our @EXCLUDE_PATTERN = ('^Devel::DumpTrace', '^Text::Shorten');
our @INCLUDE_PATTERN = ();
our (%DEFERRED, $PAD_MY, $PAD_OUR, $TRACE);
our $_THREADS = 0;
our $_INIT = 0;

my (@matches, %sources);
my @_INC = @lib::ORIG_INC ? @lib::ORIG_INC : @INC;

# these variables are always qualified into the 'main' package,
# regardless of the current package
my %ALWAYS_MAIN = (ENV => 1, INC => 1, ARGV => 1, ARGVOUT => 1,
		   SIG => 1, STDIN => 1, STDOUT => 1, STDERR => 1,);

# used by _qquote below
my %esc = ("\a" => '\a', "\b" => '\b', "\t" => '\t', "\n" => '\n',
	   "\f" => '\f', "\r" => '\r', "\e" => '\e',);

# use PPI by default, if available
$Devel::DumpTrace::NO_PPI
    || $ENV{DUMPTRACE_NOPPI}
    || eval 'use Devel::DumpTrace::PPI;1';

{
    *Devel::Trace::TRACE = \$TRACE;
    tie $TRACE, 'Devel::DumpTrace::VerboseLevel';
    if (defined $ENV{DUMPTRACE_LEVEL}) {
	$TRACE = $ENV{DUMPTRACE_LEVEL};
    } else {
	$TRACE = 'default';
    }

    *DB::DB = \&DB__DB unless defined &DB::DB;

    if (defined $ENV{DUMPTRACE_FH}) {
	if (uc $ENV{DUMPTRACE_FH} eq 'STDOUT') {
	    $DUMPTRACE_FH = *STDOUT;
	} elsif (uc $ENV{DUMPTRACE_FH} eq 'TTY') {
	    my $tty = $^O eq 'MSWin32' ? 'CON' : '/dev/tty';
	    unless (open $DUMPTRACE_FH, '>>', $tty) {
		warn "Failed to open tty as requsted by ",
	 	    "DUMPTRACE_FH=$ENV{DUMPTRACE_FH}. Failover to STDERR\n";
		    $DUMPTRACE_FH = *STDERR;
	    }
	} else {
	    ## no critic (BriefOpen)
	    unless (open $DUMPTRACE_FH, '>', $ENV{DUMPTRACE_FH}) {
		die "Can't use $ENV{DUMPTRACE_FH} as trace output file: $!\n",
		    "Devel::DumpTrace module is quitting.\n";
	    }
	}
    } else {
	$DUMPTRACE_FH = *STDERR;
    }
    $DUMPTRACE_FH->autoflush(1);
    $DUMPTRACE_COLOR = $ENV{DUMPTRACE_COLOR} || '';
    if ($DUMPTRACE_COLOR) {
        if ($color_avail) {
            if ($DUMPTRACE_COLOR =~ /^\d+$/) {
                my $bg = $DUMPTRACE_COLOR >> 4;
                my $fg = $DUMPTRACE_COLOR & 7;
                my $bold = ($DUMPTRACE_COLOR & 8) != 0;
                my @c = ("black","red","green","yellow",
                         "blue","magenta","cyan","white");
                $DUMPTRACE_COLOR = ($bold ? "bold " : "") . $c[$fg]
                    . ($bg ? " on_" . $c[$bg & 7] : "");
            }
            $DUMPTRACE_COLOR = Term::ANSIColor::color($DUMPTRACE_COLOR);
            our $DUMPTRACE_RESET = Term::ANSIColor::color('reset');
        } else {
            carp "DUMPTRACE_COLOR spec ignored: ",
                 "Term::ANSIColor not available";
            $DUMPTRACE_COLOR = '';
        }
    } else {
        $DUMPTRACE_COLOR = "";
    }
    $SMART_ABBREV = 0 if $ENV{DUMPTRACE_DUMB_ABBREV};
}

sub import {
    my ($class, @args) = @_;

    push @EXCLUDE_PATTERN, map '^' . substr($_,1) . '$', grep { /^-/ } @args;
    push @INCLUDE_PATTERN, map '^' . substr($_,1) . '$', grep { /^\+/ }@args;
    # these packages will be included/excluded at CHECK time, after
    # all packages have been loaded

    push @EXCLUDE_PATTERN,
        map { '^' . $_ . '$' } split /,/, $ENV{DUMPTRACE_EXCLPKG} || '';
    push @INCLUDE_PATTERN,
        map { '^' . $_ . '$' } split /,/, $ENV{DUMPTRACE_INCLPKG} || '';

    @args = grep { /^[^+-]/ } @args;
    if (grep { $_ eq ':test' } @args) {

        # :test
        #    import some low level routines to the calling
        #    namespace for testing.

        @args = grep { $_ ne ':test' } @args;
        no strict 'refs';
        my $p = caller;
        foreach my $name (qw(save_pads evaluate_and_display_line dump_scalar
                             hash_repr array_repr handle_deferred_output
                             evaluate save_previous_regex_matches)) {
            *{$p . '::' . $name} = *$name;
        }
        *{$p . '::substitute'} = *perform_variable_substitutions;
        *{$p . '::xsubstitute'} = *perform_extended_variable_substitutions;
    }
    if (@args > 0) {
	$TRACE = join ',', @args;
    }
    return;
}

our $ZZ = 0;

sub DB__DB {
    return if __inGD();
    return unless $Devel::DumpTrace::TRACE;

    my ($p, $f, $l) = caller();
    my (undef, undef, undef, $sub) = caller(1);
    $sub ||= '__top__';
    $sub =~ s/::$/::__top__/;

    if ($DB::single < 2) {
	return if _exclude_pkg($f,$p,$l);
	return if _display_style() == DISPLAY_NONE;
    }

    handle_deferred_output($sub, $f);
    my $code = get_source($f,$l);

    save_pads(1);
    save_previous_regex_matches();
    evaluate_and_display_line($code, $p, $f, $l, $sub);
    return;
}

sub get_source {
    my ($file, $line) = @_;
    no strict 'refs';

    if (!defined $sources{$file}) {
	# die "source not available for $file ...\n";
	my $source_key = "::_<" . $file;
	eval {
	    $sources{$file} = [ @{$source_key} ]
	};
	if ($@) {
	    # this happens when we are poking around the symbol table?
	    # are we corrupting the source file data somehow?

	    $sources{$file} = [
		("SOURCE NOT AVAILABLE FOR file $file: $@") x 999
	    ];
	    if (open my $grrrrr, '<', $file) {
		$sources{$file} = [ "", <$grrrrr> ];
		warn "Source for \"$file\" not loaded ",
		    "automatically at debugger level ...\n";
		close $grrrrr;
	    }
	}
    }
    return $sources{$file}->[$line];
}

sub _exclude_pkg {
    my($file,$pkg,$line) = @_;

    return 0 if $INCLUDE_PKG{$pkg} || $INCLUDE_PKG{$file};
    foreach (@INCLUDE_PATTERN) {
	if ($pkg =~ $_) {
	    $INCLUDE_PKG{$pkg} = 1;
	    return 0;
	}
    }

    return 1 if $EXCLUDE_PKG{$pkg} || $EXCLUDE_PKG{$file};
    foreach (@EXCLUDE_PATTERN) {
	if ($pkg =~ $_) {
	    return $EXCLUDE_PKG{$pkg}=1 if $pkg =~ $_;
	}
    }
    return 0 if _package_style() > DISPLAY_NONE;

    # exclude files from @_INC when _package_style() is 0
    foreach my $inc (@_INC) {
	if (index($inc,"/") >= 0 && index($file,$inc) == 0) {
	    return $EXCLUDE_PKG{$file} = $EXCLUDE_PKG{$pkg} = 1;
	}
    }
    $INCLUDE_PKG{$pkg} = 1;

    return 0;
}

# map $TRACE variable to a display style
sub _display_style_old {
    return DISPLAY_TERSE if $TRACE eq 'default'; # 5.8.8 bug?
    return (DISPLAY_TERSE,
	    DISPLAY_TERSE,
	    DISPLAY_TERSE,
	    DISPLAY_TERSE,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY)[$TRACE % 10];
}
sub _display_style_new {
    return (DISPLAY_TERSE,
	    DISPLAY_TERSE,
	    DISPLAY_TERSE,
	    DISPLAY_TERSE,
	    DISPLAY_TERSE,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY,
	    DISPLAY_GABBY)[$TRACE % 10];
}

# map $TRACE variable to an abbreviation style
sub _abbrev_style_old {
    return (ABBREV_SMART,
	    ABBREV_SMART,
	    ABBREV_MILD_SM,
	    ABBREV_NONE,
	    ABBREV_MILD_SM,
	    ABBREV_NONE,
	    ABBREV_NONE,
	    ABBREV_NONE,
	    ABBREV_NONE,
	    ABBREV_NONE,)[$TRACE % 10]
}
sub _abbrev_style_new {
    return (ABBREV_SMART,
	    ABBREV_SMART,
	    ABBREV_STRONG,
	    ABBREV_MILD_SM,
	    ABBREV_MILD,
	    ABBREV_NONE,
	    ABBREV_SMART,
	    ABBREV_STRONG,
	    ABBREV_MILD_SM,
	    ABBREV_NONE,)[$TRACE % 10]
}

BEGIN {
    *_display_style = *_display_style_old;
    *_abbrev_style = *_abbrev_style_old;
}

sub _package_style {
    return $TRACE >= 100;
}

sub save_pads {
    my $n = shift || 0;
    my $target_depth = current_depth() - $n - 1;

    if ($target_depth < 0) {
	Carp::cluck "save_pads: request for negative frame ",
	current_depth(), " $target_depth $n at ";
	return;
    }
    if ($n < 0) {
	Carp::cluck "save_pads: request for shallow frame ",
	    current_depth(), " $target_depth $n at ";
	return;
    }

    eval {
	$PAD_MY = PadWalker::peek_my($n + 1);
	$PAD_OUR = PadWalker::peek_our($n + 1);
	1;
    } or do {
	Carp::confess("$@ from PadWalker: \$n=$n is too large.\n",
		      "Target depth was $target_depth\n");
    };

    # add extra data to the pads so that they can be refreshed
    # at an arbitrary point in the future
    $PAD_MY->{__DEPTH__} = $PAD_OUR->{__DEPTH__} = current_depth() - $n - 1;

    return;
}

sub current_depth {
    my $n = 0;
    $n++ while caller($n);
    return $n-1;
}

sub refresh_pads {
    return if __inGD();
    my $current = current_depth();
    my $target = $PAD_MY->{__DEPTH__};
    if ($current >= $target) {
	save_pads($current - $target);
    }
    # $current < $target
    return;
}

our $last_dumptrace = '';
my @dt_prefix = ("      ",            ### not used
                 ">     ",            ### not used
                 ">>    ",            # to display current file/line/sub
                 ">>>   ",            # raw statement
                 ">>>>  ",            # with var substitution, before execution
                 ">>>>> ",            # with var substitution after execution
                 "     \t         ",  ### not used
                 ">    \t         ",  ### not used
                 ">>   \t         ",  ### not used
                 ">>>  \t         ",  # raw statetment
                 ">>>> \t         ",  # with var substitution, before execution
                 ">>>>>\t         ",  # with var substitution after execution
                 "");

sub dumptrace {
    my ($n, $tab, @output) = @_;
    my $dt = join ('', @output);
    my $out = $dt_prefix[$n+6*!!$tab] . $dt;
    if ($last_dumptrace && $dt eq $last_dumptrace) {
        # duplicate
        return;
    }

    $last_dumptrace = $dt;
    if ($DUMPTRACE_COLOR) {
        our $DUMPTRACE_RESET;
        $out = join $/, map( $DUMPTRACE_COLOR . $_ . $DUMPTRACE_RESET,
                               split($/,$out)), "";
    }
    our $LOCKOBJ && lock(my $lock = \$LOCKOBJ);
    print {$DUMPTRACE_FH} $out;
}

sub evaluate_and_display_line {
    my ($code, $p, $f, $l, $sub) = @_;
    my $style = _display_style();

    if ($style > DISPLAY_TERSE) {
	separate();
        dumptrace(2,0, current_position_string($f,$l,$sub), "\n");
        dumptrace(3,1,$code);
    }

    # look for assignment operator.
    $DEFERRED{"$sub : $f"} ||= [];
    if ($code    =~ m{[-+*/&|^.%]?=[^=>]}
	|| $code =~ m{[\b*&|/<>]{2}=\b}   ) {

	my ($expr1, $op, $expr2) = ($`, $&, $');   # ');

	if ($style < DISPLAY_GABBY) {
	    $expr2 = perform_extended_variable_substitutions($op . $expr2, $p);
	} else {
	    $expr2 = perform_variable_substitutions($op . $expr2, $p);
	}

	push @{$DEFERRED{"$sub : $f"}},
	{ PACKAGE => $p,
	  MY_PAD  => $PAD_MY,
	  OUR_PAD => $PAD_OUR,
	  SUB     => $sub,
	  FILE    => $f,
	  LINE    => $l,
          DISPLAY_FILE_AND_LINE => $style <= DISPLAY_TERSE,
	  EXPRESSION => [ $expr1, $expr2 ]
	};

	if ("$expr1$expr2" ne $code) {
	    if ($style >= DISPLAY_GABBY) {
                dumptrace(4,1,$expr1,$expr2);
	    }
	}
	return;
    } else {
	push @{$DEFERRED{"$sub : $f"}}, undef;
    }

    my $xcode;

    # if this is a simple lexical declaration and NOT an assignment,
    # then don't perform variable substitution:
    #          my $k;
    #          my ($a,$b,@c);
    #          our $ZZZ;

    if ($code    =~ /^ \s* (my|our) \s*
                    [\$@%*\(] /x           # lexical declaration
	&& $code =~ / (?<!;) .* ;
                    \s* (\# .* )? $/x   # single statement, single line
	&& $code !~ /=/) {                # NOT an assignment

	$xcode = $code;

    } else {

	$xcode = perform_variable_substitutions($code, $p);

    }

    if ($style >= DISPLAY_GABBY) {
	if ($xcode ne $code) {
	    dumptrace(4,1,$xcode);
	}
    } elsif ($style == DISPLAY_TERSE) {
        dumptrace(4,0, current_position_string($f,$l,$sub),
                       "\t         $xcode");
    }
    return;
}

sub separate {
    our $SEPARATOR_USED;
    $SEPARATOR_USED++ && dumptrace(-1, 0, $SEPARATOR);
    return;
}

# a guard against deep recursion in  dump_scalar  subroutine
my %_dump_scalar_seen = ();

sub _reset_dump {
    %_dump_scalar_seen = ();
}

sub dump_scalar {
    my $scalar = $_[0];
    # was  my $scalar = shift   and was   my ($scalar) = @_;
    # but they caused "Modification of a read-only value attempted"
    # error with Perl 5.8.8

    return 'undef' if !defined $scalar;
    if (ref $scalar) {
	if ($_dump_scalar_seen{$scalar}) {
	    return "... $scalar (prev. referenced)";
	}
	$_dump_scalar_seen{$scalar}++;
	my $z;
	if (Scalar::Util::reftype($scalar) eq 'ARRAY') {
	    $z = '[' . array_repr($scalar) . ']';
	} elsif (Scalar::Util::reftype($scalar) eq 'HASH') {
	    $z = '{' . hash_repr($scalar) . '}';
	} elsif (Scalar::Util::reftype($scalar) eq 'GLOB') {
	    $z = $scalar;
	} else {
	    $z = "$scalar";
	}
	delete $_dump_scalar_seen{$scalar};
	return $z;
    }
    if (Scalar::Util::looks_like_number($scalar)) {
	$scalar =~ s/^\s+//;
	$scalar =~ s/\s+$//;
	return _abbreviate_scalar($scalar);
    }
    if (ref \$scalar eq 'GLOB') {
	return $scalar;
    }
    my $qq = _qquote($scalar);
    if ($qq ne $scalar) {
	return _abbreviate_scalar(qq("$qq"));
    }
    return _abbreviate_scalar(qq('$scalar'));
}

sub _abbreviate_scalar {
    my ($value) = @_;
    if (_abbrev_style() >= ABBREV_NONE) {
	return $value;
    }
    if (_abbrev_style() > ABBREV_STRONG) {
	# mild abbreviation: no token longer than 80 chars
	return Text::Shorten::shorten_scalar($value, 80);
    } else {
	# strong abbreviation: no token longer than 20 chars
	return Text::Shorten::shorten_scalar($value, 20);
    }
}

# shamelessly lifted from Data::Dumper::qquote
#
# converts a string of arbitrary characters to an ASCII string that
# produces the original string under double quote interpolation
sub _qquote {
    local($_) = shift;
    s/([\\\"\@\$])/\\$1/g;
    my $bytes; { use bytes; $bytes = length }
    ($bytes > length) && s/([^\x00-\x7f])/'\x{'.sprintf("%x",ord($1)).'}'/ge;
    /[^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~]/ || return $_;

    my $high = shift || '';
    s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

    if (ord('^')==94)  {
	# no need for 3 digits in escape for these
	s/([\0-\037])(?!\d)/'\\'.sprintf('%o',ord($1))/eg;
	s/([\0-\037\177])/'\\'.sprintf('%03o',ord($1))/eg;
	# all but last branch below not supported --BEHAVIOR SUBJECT TO CHANGE--
	if ($high eq 'iso8859') {
	    s/([\200-\240])/'\\'.sprintf('%o',ord($1))/eg;
	} elsif ($high eq 'utf8') {
#     use utf8;
#     $str =~ s/([^\040-\176])/sprintf "\\x{%04x}", ord($1)/ge;
	} elsif ($high eq '8bit') {
	    # leave it as it is
	} else {
	    s/([\200-\377])/'\\'.sprintf('%03o',ord($1))/eg;
	    s/([^\040-\176])/sprintf "\\x{%04x}", ord($1)/ge;
	}
    } else { # ebcdic
	s{([^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~])(?!\d)}
	{my $v = ord($1); '\\'.sprintf(($v <= 037 ? '%o' : '%03o'), $v)}eg;
	s{([^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~])}
	{'\\'.sprintf('%03o',ord($1))}eg;
    }
    return $_;
}

sub hash_repr {
    my ($hashref, @keys) = @_;

    return '' if !defined $hashref;
    @keys = () unless $SMART_ABBREV;
    my $ref = ref $hashref && ref $hashref ne 'HASH'
	? ref($hashref) . ': ' : '';
    my $maxlen = _abbrev_style() < ABBREV_NONE
	? _abbrev_style() > ABBREV_STRONG ? 79 : 19 : -1;
    my $cache_key = join ':',
        $maxlen, $HASH_ENTRY_SEPARATOR, $HASH_PAIR_SEPARATOR;
    my $hash;

    # When the hash table gets large, tie it to 
    # Devel::DumpTrace::CachedDisplayedHash and
    # see if we can avoid some expensive calls
    # to  Text::Shorten::shorten_hash .

    if ((Scalar::Util::reftype($hashref)||'') ne 'HASH') {
	# this can happen with globs, e.g.,  $$glob->{attribute} = value;
	return "$hashref";
    }

    if (@keys == 0 &&
        Devel::DumpTrace::CachedDisplayedHash->is($hashref)) {

	my $result = (tied %{$hashref})->get_cache($cache_key);
	if (defined $result) {
	    return $ref . join $HASH_ENTRY_SEPARATOR,
	        map { join $HASH_PAIR_SEPARATOR, @{$_} } _condsort(@{$result});
	}
	$hash = (tied %{$hashref})->{PHASH};
    } elsif (!tied(%{$hashref}) 
	     && @keys == 0
	     && !__hashref_is_symbol_table($hashref) 

	     # use safekeys in case this DB hook is inside an `each` iterator
	     && 100 < scalar safekeys %$hashref) {

	my $cdh = tie %{$hashref}, 'Devel::DumpTrace::CachedDisplayedHash',
                      %{$hashref};
        $hash = $cdh->{PHASH};
    } else {
	# Hash::SafeKeys::safekeys will not reset an active `each` iterator
        my $it = Hash::SafeKeys::save_iterator_state($hashref);
	$hash = { map { dump_scalar($_) => dump_scalar($hashref->{$_}) } 
		  keys %$hashref };
        Hash::SafeKeys::restore_iterator_state($hashref,$it);
    }

    my @r;
    if (_abbrev_style() < ABBREV_NONE) {
	local $Text::Shortern::HASHREPR_SORTKEYS
	    = $Devel::DumpTrace::HASHREPR_SORT;
	@r = Text::Shorten::shorten_hash(
	    $hash, $maxlen,
	    $HASH_ENTRY_SEPARATOR,
	    $HASH_PAIR_SEPARATOR, @keys );
    } else {
	# safekeys does not reset an active `each` iterator (RT#77673)
        my $it = Hash::SafeKeys::save_iterator_state($hash);
	@r = map { [ $_ => $hash->{$_} ] } _condsort(keys %$hash);
        Hash::SafeKeys::restore_iterator_state($hash,$it);
    }

    if (@keys == 0 && Devel::DumpTrace::CachedDisplayedHash->is($hashref)) {
	(tied %{$hashref})->store_cache($cache_key, \@r);
    }

    if (!defined $HASH_PAIR_SEPARATOR) {
	Carp::cluck("setting \$HASH_PAIR_SEPARATOR definition ...");
	$HASH_PAIR_SEPARATOR = " =======> ";
    }

    return $ref . join ($HASH_ENTRY_SEPARATOR,
    map { join ($HASH_PAIR_SEPARATOR,
		map{defined($_)?$_:'undef'}@{$_}) } @r );
}

# sort an array iff $Devel::DumpTrace::HASHREPR_SORT is set.
sub _condsort {
    $Devel::DumpTrace::HASHREPR_SORT ? sort @_ : @_;
}

sub __hashref_is_symbol_table {
    # if we pass a reference to a symbol table in repr_hash,
    # we don't want to tie it to a D::DT::CachedDisplayedHash.
    #
    # Don't know if this is the best method or if it is
    # perfectly reliable, but it is getting there ...

    use B;
    my ($hashref) = @_;
    my $sv = B::svref_2object($hashref);
    return ref($sv) eq 'B::HV' && $sv->NAME;
}

sub array_repr {
    my ($arrayref, @keys) = @_;

    return '' if !defined $arrayref;
    @keys = () unless $SMART_ABBREV;
    my $ref = ref $arrayref && ref $arrayref ne 'ARRAY'
	? ref($arrayref) . ': ' : '';
    my $maxlen = _abbrev_style() < ABBREV_NONE
	? _abbrev_style() > ABBREV_STRONG ? 79 : 19 : -1;
    my $cache_key = join ':', $maxlen, $ARRAY_ELEM_SEPARATOR;
    my $array;

    # When the array gets large, tie it to 
    # Devel::DumpTrace::CachedDisplayedArray and
    # see if we can avoid some expensive calls
    # to  Text::Shorten::shorten_array .

    if (@keys == 0
        && Devel::DumpTrace::CachedDisplayedArray->is($arrayref)) {

	my $result = (tied @{$arrayref})->get_cache($cache_key);
	if (defined $result) {
	    return $ref . join $ARRAY_ELEM_SEPARATOR, @$result;
	}
	$array = (tied @{$arrayref})->{PARRAY};
    } elsif (@keys==0 && !tied(@{$arrayref}) && 100 < scalar @{$arrayref}) {
	eval {
	    tie @{$arrayref}, 'Devel::DumpTrace::CachedDisplayedArray',
	    	@{$arrayref};
	    $array = (tied @{$arrayref})->{PARRAY};
	} or do {
	    $array = [ map { dump_scalar($_) } @{$arrayref} ];
	};
    } else {
	$array = [ map { dump_scalar($_) } @{$arrayref} ];
    }

    my @r;
    if ($maxlen > 0) {
	@r = Text::Shorten::shorten_array(
	    $array, $maxlen, $ARRAY_ELEM_SEPARATOR, @keys);
    } else {
	@r = @{$array};
    }
    if (@keys == 0
        && Devel::DumpTrace::CachedDisplayedArray->is($arrayref)) {
	(tied @{$arrayref})->store_cache($cache_key, \@r);
    }
    return $ref . join $ARRAY_ELEM_SEPARATOR, @r;
}

sub handle_ALL_deferred_output {
    foreach my $context (keys %DEFERRED) {
	my ($sub, $file) = split / : /, $context, 2;
	handle_deferred_output($sub, $file);
    }
    separate() if _display_style() > DISPLAY_TERSE;
    return;
}

sub handle_deferred_output {
    my ($sub, $file) = @_;
    my $deferred = pop @{$DEFERRED{"$sub : $file"}};
    delete $DEFERRED{"$sub : $file"};

    if (defined $deferred) {

	my ($expr1, $expr2) = @{$deferred->{EXPRESSION}};
	my $deferred_pkg = $deferred->{PACKAGE};
	$PAD_MY = $deferred->{MY_PAD};
	$PAD_OUR = $deferred->{OUR_PAD};
	refresh_pads();
	$PAD_MY->{__STALE__} = $deferred->{MY_PAD};
	$PAD_OUR->{__STALE__} = $deferred->{OUR_PAD};
	my ($line);
	if ($deferred->{DISPLAY_FILE_AND_LINE}) {
	    $file = $deferred->{FILE};
	    $line = $deferred->{LINE};
	}
        my $output = $expr2;
        if (defined($line)) {
            $output = current_position_string($file,$line,$deferred->{SUB})
                . "\t" .
                perform_extended_variable_substitutions($expr1, $deferred_pkg)
                . $output;
        } else {
            $output = "\t         "
                . perform_variable_substitutions($expr1, $deferred_pkg)
                . $output;
        }
        dumptrace(5,0,$output);
    }
    return;
}

sub perform_variable_substitutions {
    my ($xcode, $pkg) = @_;
    $xcode =~ s{  ([\$\@\%])\s*           # sigil
                  ([\w:]+)                # package (optional) and var name
                  (\s*->)?                # optional dereference op
                  (\s*[\[\{])?            # optional subscript
               }{ 
		   evaluate($1,$2,$3||'',$4||'',$pkg) 
               }gex;

    return $xcode;
}

my %output_count;
sub current_position_string {
    my ($file, $line, $sub) = @_;
    if (OUTPUT_COUNT) {
	my $cnt = ++$output_count{$file}{$line};
	$line .= "\[$cnt\]";
    }
    if (OUTPUT_TIME) {
	if ($Time_HiRes_avail) {
	    $file = sprintf "%.3f:%s", Time::HiRes::time()-$^T, $file;
	} else {
	    $file = sprintf "t=%d:%s", time-$^T, $file;
	}
    }
    if (OUTPUT_SUB) {
	$sub ||= '__top__';
	# $file already probably contains package information.
	# Keeping it in $sub is _usually_ redundant and makes the
	# line too long.
	$sub =~ s/.*:://;

	if (OUTPUT_PID) {
            my $p = $$;
            if ($_THREADS) {
                $p .= eval { "-t" . threads->tid() }; warn $@ if $@;
            }
	    return "$p:$file:$line:[$sub]:";
	} else {
	    return "$file:$line:[$sub]:";
	}
    } elsif (OUTPUT_PID) {
        my $p = $$;
        if ($_THREADS) {
            $p .= eval { "-t" . threads->tid() }; warn $@ if $@;
        }
	return "$p:$file:$line:";
    } else {
	return "$file:$line:";
    }
}

sub perform_extended_variable_substitutions {
    my ($xcode, $pkg) = @_;
    $xcode =~ s{  ([\$\@\%])\s*    # sigil
                  ([\w:]*\w)(?!:)  # var name, may incl. pkg, ends in alphanum
                  (\s*->)?         # optional dereference op
                  (\s*[\[\{])?     # optional subscript
               }{ $1 . $2 . $XEVAL_SEPARATOR
	          . evaluate($1,$2,$3||'',$4||'',$pkg)
               }gex;
    return $xcode;
}

sub get_DB_args {
    my $depth = 1 + shift;
    my @z;
    for (my $i=$depth; $i<=$depth; $i++) {
	if ($i>=0) {
	    package DB; 
	    my @y = caller($depth); 
	    return if @y==0;
	}

	# best efforts here. Sometimes this assignment gives a
	# "Bizarre copy of ARRAY in aassign" error message
	# (when $depth is too deep and @DB::args is not defined?).
	eval 'no warnings q/internal/; @z = @DB::args';
    }
    return @z;
}

# McCabe score: 49
sub evaluate {
    my ($sigil, $varname, $deref_op, $index_op, $pkg, @keys) = @_;
# return unless defined($sigil) && $sigil ne '';
    my $v;
    _reset_dump();

    no strict 'refs';

    $deref_op ||= '';
    $index_op ||= '';
    $index_op =~ s/^\s+//;

    if ($ALWAYS_MAIN{$varname} || $varname =~ /^\d+$/) {
	$pkg = 'main';
    }
    $pkg .= '::';
    if ($varname =~ /::/ || $pkg eq '<magic>::') {
	$pkg = '';
    }

    if ($deref_op) {
	my $sigvar = "\$$varname";
	(my $pkgvar = $sigvar) =~ s/\$/\$$pkg/;

	if (defined $PAD_MY->{$sigvar}) {
	    $v = $PAD_MY->{$sigvar};
	} elsif (defined $PAD_OUR->{$sigvar}) {
	    $v = $PAD_OUR->{$sigvar};
	} elsif (defined $PAD_MY->{__STALE__}{$sigvar}) {
	    $v = $PAD_MY->{__STALE__}{$sigvar};
	} elsif (defined $PAD_OUR->{__STALE__}{$sigvar}) {
	    $v = $PAD_OUR->{__STALE__}{$sigvar};
	} else {
	    $v = eval "\\$pkgvar";
	}
	if ($index_op eq '[') {
	    return '[' . array_repr(${$v}, @keys) . ']->[';
	}
	if ($index_op eq '{') {
	    return '{' . hash_repr(${$v}, @keys) . '}->{';
	}

	my $reftype = Scalar::Util::reftype(${$v});
	if (!defined($reftype) || $reftype eq '') {
	    return '(' . dump_scalar($v) . ')->';
	} elsif ($reftype eq 'HASH') {
	    return '{' . hash_repr(${$v}, @keys) . '}->';
	} elsif ($reftype eq 'ARRAY') {
	    return '[' . array_repr(${$v}, @keys) . ']->';
	} else {
	    return '(' . dump_scalar($v) . ')->';
	}
    }

    if ($index_op eq '{') {
	my $sigvar = "\%$varname";
	(my $pkgvar = $sigvar) =~ s/\%/\%$pkg/;
	if (defined($PAD_MY->{$sigvar})) {
	    $v = $PAD_MY->{$sigvar};
	} elsif (defined($PAD_OUR->{$sigvar})) {
	    $v = $PAD_OUR->{$sigvar};
	} else {
	    $v = eval "\\$pkgvar";
	}
	return '(' . hash_repr($v, @keys) . '){';
    }
    if ($sigil eq '@') {
	my $sigvar = "\@$varname";
	(my $pkgvar = $sigvar) =~ s/\@/\@$pkg/;

	if ($varname eq '_') {
	    # calling  caller  (1) with arg, (2) in list context,
	    # (3) from DB package will populate @DB::args, which is
	    # what we really want.
	    my $depth = $DB_ARGS_DEPTH;
	    no warnings 'uninitialized';
	    while ((caller $depth)[CALLER_SUB] =~ /^\(eval/) {
		$depth++;
	    }
	    $v = [ get_DB_args($depth) ];
	} elsif (defined($PAD_MY->{$sigvar})) {
	    $v = $PAD_MY->{$sigvar};
	} elsif (defined($PAD_OUR->{$sigvar})) {
	    $v = $PAD_OUR->{$sigvar};
	} else {
	    eval {
		$v = eval "\\" . $pkgvar;
	    };
	    if (!defined $v) {
		print {$DUMPTRACE_FH} "Devel::DumpTrace: ", 
		    "Couldn't find $sigvar/$pkgvar in any appropriate scope.\n";
		$v = [];
	    }
	}
	if ($index_op eq '[') {
	    return '(' . array_repr($v, @keys) . ')[';
	}
	return '(' . array_repr($v, @keys) . ')';
    }
    if ($sigil eq '%') {
	my $sigvar = "\%$varname";
	(my $pkgvar = $sigvar) =~ s/\%/\%$pkg/;
	if (defined($PAD_MY->{$sigvar})) {
	    $v = $PAD_MY->{$sigvar};
	} elsif (defined($PAD_OUR->{$sigvar})) {
	    $v = $PAD_OUR->{$sigvar};
	} else {
	    $v = eval "\\$pkgvar";
	}
	return '(' . hash_repr($v) . ')';
    }
    if ($sigil eq '$') {
	if ($index_op eq '[') {
	    my $sigvar = "\@$varname";
	    (my $pkgvar = $sigvar) =~ s/\@/\@$pkg/;
	    if ($varname eq '_') {
		my $depth = $DB_ARGS_DEPTH;
		$v = [ get_DB_args($depth) ];
	    } elsif (defined($PAD_MY->{$sigvar})) {
		$v = $PAD_MY->{$sigvar};
	    } elsif (defined($PAD_OUR->{$sigvar})) {
		$v = $PAD_OUR->{$sigvar};
	    } else {
		eval { $v = eval "\\$pkgvar" };
		if (!defined $v) {
		    print {$DUMPTRACE_FH} "Devel::DumpTrace: ",
		        "Couldn't find $sigvar/$pkgvar in any appropriate scope.\n";
		    $v = [];
		}
	    }
	    return '(' . array_repr($v, @keys) . ')[';
	} elsif ($varname =~ /^\d+$/) {
	    # special regex match var $1,$2,...
            # they were loaded into @matches in save_previous_regex_matches()
	    $v = $matches[$varname];
	    return dump_scalar($v);
	} else {

	    my $sigvar = "\$$varname";
	    if ($varname eq '_') {
		$pkg = 'main::';
	    }
	    (my $pkgvar = $sigvar) =~ s/\$/\$$pkg/;

	    if (defined($PAD_MY->{$sigvar})) {
		$v = ${$PAD_MY->{$sigvar}};
	    } elsif (defined($PAD_OUR->{$sigvar})) {
		$v = ${$PAD_OUR->{$sigvar}};
	    } else {
		$v = eval "$pkgvar";
	    }
	    return dump_scalar($v);
	}
    }

    Carp::confess 'No interpolation done for input: ',
        "<sigil:$sigil ; varname:$varname ; deref:$deref_op ; ",
        "index:$index_op ; pkg:$pkg>\n"
}

sub save_previous_regex_matches {
    @matches = ($0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
		$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,
		$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,);

    # XXX - if someone needs more than $30, submit a feature request
    # (http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-DumpTrace,
    # or email to bug-Devel-DumpTrace@rt.cpan.org)
    # and I'll figure something out ...

    return;
}

# RT#76864
{
    # Devel::DumpTrace is typically loaded before any other module
    # (from the -d:DumpTrace switch). Running this  thread-specific
    # code in a  CHECK  block gives the traced program a chance to
    # load  threads  later.
    no warnings 'void';
    CHECK {
        if ($INC{'threads.pm'}) {
            $_THREADS = 1;
            require threads::shared;
            our $LOCKOBJ = 1;  # to synchronize access to output stream
            threads::shared::share(\$LOCKOBJ);
        }
    };
}

sub __END {
    no warnings 'redefine';
    *DB::DB = sub { };
    *__inGD = sub () { 1 };
    untie $TRACE;
    handle_ALL_deferred_output() unless $_THREADS && threads->tid();
    1;
}

END { &__END; }


##################################################################
# Devel::DumpTrace::VerboseLevel: tie class for $Devel::DumpTrace::TRACE.
#
# This class allows us to say, for example,
#
#   $TRACE = 'verbose'
#
# and have the keyword 'verbose' translated into the value "5".
#

sub Devel::DumpTrace::VerboseLevel::TIESCALAR {
    my ($pkg) = @_;
    my $scalar;
    return bless \$scalar, $pkg;
}

sub Devel::DumpTrace::VerboseLevel::FETCH {
    my $self = shift;
    return ${$self};
}

sub Devel::DumpTrace::VerboseLevel::STORE {
    my ($self, $value) = @_;

    #Carp::cluck $self,"->STORE($value) called !\n";
    return if !defined $value;

    my $old = ${$self};
    my ($style, $package) = split /,/, $value;
    $style =~ s/^\s+//;
    $style =~ s/\s+$//;
    no warnings 'uninitialized';
    $style = {verbose=>5, normal=>3, default=>3,
	      quiet=>1, on=>3, off=>'00'}->{lc $style} || $style;
    if ($style !~ /^\d+$/) {
	carp "Unrecognized debugging level $style\n";
	$style = 3;
    }
    ${$self} = $style;
    if (defined $package) {
	$package =~ s/^\s+//;
	$package =~ s/\s+$//;
	if ($package) {
	    ${$self} += 100;
	}
    }
    return $old;
}

1;

__END__

=head1 NAME

Devel::DumpTrace - Evaluate and print out each line before it is executed.

=head1 VERSION

0.26

=head1 SYNOPSIS

    perl -d:DumpTrace program.pl
    perl -d:DumpTrace=verbose program.pl
    perl -d:DumpTrace=quiet program.pl
    perl -d:DumpTrace=<n> program.pl

    perl -d:DumpTrace::PPI program.pl
    perl -d:DumpTrace::noPPI program.pl

=head1 DESCRIPTION

L<Similar to Devel::Trace|Devel::Trace>, this module will cause a message
to be printed to standard error for each line of source code that is
executed. In addition, this module will attempt to identify variable names
in the source code and substitute the values of those variables. In this
way you can say the path of execution through your program as well
as see the value of your variables at each step of the program.

For example, if your program looks like this:

    #!/usr/bin/perl
    # a demonstration of Devel::DumpTrace
    $a = 1;
    $b = 3;
    $c = 2 * $a + 7 * $b;
    @d = ($a, $b, $c + $b);

then the C<DumpTrace> output will look like:

    $ perl -d:DumpTrace demo.pl
    >>>>> demo.pl:3:        $a:1 = 1;
    >>>>> demo.pl:4:        $b:3 = 3;
    >>>>> demo.pl:5:        $c:23 = 2 * $a:1 + 7 * $b:3;
    >>>>> demo.pl:6:        @d:(1,3,26) = ($a:1, $b:3, $c:23 + $b:3);

There are also more I<verbose> modes which will produce even more
detailed output:

    $ perl -d:DumpTrace=verbose demo.pl
    >>  demo.pl:3:
    >>>              $a = 1;
    >>>>>            1 = 1;
    -------------------------------------------
    >>  demo.pl:4:
    >>>              $b = 3;
    >>>>>            3 = 3;
    -------------------------------------------
    >>  demo.pl:5:
    >>>              $c = 2 * $a + 7 * $b;
    >>>>             $c = 2 * 1 + 7 * 3;
    >>>>>            23 = 2 * 1 + 7 * 3;
    -------------------------------------------
    >>  demo.pl:6:
    >>>              @d = ($a, $b, $c + $b);
    >>>>             @d = (1, 3, 23 + 3);
    >>>>>            (1,3,26) = (1, 3, 23 + 3);
    -------------------------------------------

See C<$Devel::DumpTrace::TRACE> under the L</"VARIABLES"> section
for more details about the different levels of verbosity.

This distribution comes with both a basic parser and a
L<PPI-based parser|Devel::DumpTrace::PPI> (which relies on L<PPI>
to understand your source code). If the L<PPI|PPI>
module is installed on your system, then this module will automatically
use the PPI-based parser to analyze the traced code. You can
force this module to use the basic parser by running with the
C<-d:DumpTrace::noPPI> argument or by setting the C<DUMPTRACE_NOPPI>
environment variable:

    # use PPI if available, otherwise use basic parser
    $ perl -d:DumpTrace program.pl

    # use PPI, fail if it is not available
    $ perl -d:DumpTrace::PPI program.pl

    # always uses basic parser
    $ perl -d:DumpTrace::noPPI program.pl
    $ DUMPTRACE_NOPPI=1 perl -d:DumpTrace program.pl

See the L</"BUGS AND LIMITATIONS"> section for important, er, limitations
of this module, especially for the basic parser.

=head1 SUBROUTINES/METHODS

None of interest.

=head1 VARIABLES

=head2 C<$Devel::DumpTrace::TRACE>

Controls whether and how much output is produced by this module.
Setting C<$Devel::DumpTrace::TRACE> to zero will disable the module.
Since this module can produce a lot of output and has other overhead
that can considerably slow down your program
(by a factor of 50 or more), you may find it
useful to toggle this variable for critical sections of your code
rather than leave it set for the entire program. For example:

    BEGIN { $Devel::DumpTrace::TRACE = 0 }

    &some_non_critical_code_that_more_or_less_works();

    $Devel::DumpTrace::TRACE = 'normal';
    &the_critial_code_you_want_to_debug();
    $Devel::DumpTrace::TRACE = 0;

    &some_more_non_critical_code();

or to enable tracing in a C<local> block:

    {
        local $Devel::DumpTrace::TRACE = 1;
        &the_critical_code;
    }


In general higher values of C<$Devel::DumpTrace::TRACE> will cause
more output to be produced.
Let's consider this simple program to see how the different
C<$Devel::DumpTrace::TRACE> settings affect the output:

    @a = (1 .. 40);
    $b = $a[4];

=over 4

=item C<$Devel::DumpTrace::TRACE> == 1

is the quietest mode. One line of output for each statement evaluated.
The name of each variable in the source code and its value are included
in the same line of output. Values of long scalars, long arrays, or
long hash tables are heavily abbreviated:

    $ perl -d:DumpTrace=1 littledemo.pl
    >>>>> littledemo.pl:1:[__top__]:  @a:(1,2,3,4,5,6,...,40) = (1 .. 40);
    >>>>> littledemo.pl:2:[__top__]:  $b:5 = $a:(1,2,3,4,5,6,...,40)[4];

=item C<$Devel::DumpTrace::TRACE> == 2

uses a single line of output for each statement evaluated. The name
of each variable in the source code and its source code are included
in the same line of output. Values of long scalar, arrays, and hashes
are less heavily abbreviated.

    $ perl -I. -d:DumpTrace=2 littledemo.pl
    >>>>> littledemo.pl:1:[__top__]:  @a:(1,2,3,4,5,6,7,8,9,10,11,12,13,14, \
        15,16,17,18,19,20,21,22,23,24,25,26,27,...,40) = (1 .. 40);
    >>>>> littledemo.pl:2:[__top__]:  $b:5 = $a:(1,2,3,4,5,6,7,8,9,10,11,12, \
        13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,...,40)[4];

=item C<$Devel::DumpTrace::TRACE> == 3

produces one line of output for each statement evaluated.
The name of each variable in the source code and its
source code are included in the same line of output.
Values of long scalar, arrays, and hashes are B<not>
abbreviated at all. B<This is the default setting for the
module>.

    $ perl -I. -d:DumpTrace=3 littledemo.pl
    >>>>> littledemo.pl:1:[__top__]:  @a:(1,2,3,4,5,6,7,8,9,10,11,12,13,14, \
       15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37, \
       38,39,40) = (1 .. 40);
    >>>>> littledemo.pl:2:[__top__]:  $b:5 = $a:(1,2,3,4,5,6,7,8,9,10,11,12, \
       13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35, \
       36,37,38,39,40)[4];

=item C<$Devel::DumpTrace::TRACE> == 4

produces up to four lines of output for each statement evaluated:

=over 4

=item * the source (file and line number) of the statement being evaluated

=item * the origianl source code for the statement being evaluated

=item * a valuation of the code B<before> the statement has been evaluated
by the Perl interpreter.

=item * a valuation of the code B<after> the statement has been evaluated
by the Perl interpreter

=back

A separator line will also be displayed between statements.
Long scalar, arrays, and hashes may be abbreviated. Example output:

    $ perl -d:DumpTrace=4 littledemo.pl
    >>  littledemo.pl:1:[__top__]:
    >>>              @a = (1 .. 40);
    >>>>>            (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20, \
        21,22,23,24,25,26,27,...,40) = (1 .. 40);
    -------------------------------------------
    >>  littledemo.pl:2:[__top__]:
    >>>              $b = $a[4] + $a[5];
    >>>>             $b = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19, \
        20,21,22,23,24,25,26,27,...,40)[4];
    >>>>>            5 = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19, \
        20,21,22,23,24,25,26,27,...,40)[4];
    -------------------------------------------

=item C<$Devel::DumpTrace::TRACE> == 5

Like C<$TRACE> 4, but long scalars, arrays, and hashes are B<not> abbreviated.

    $ perl -I. -d:DumpTrace=5 littledemo.pl
    >>  littledemo.pl:1:[__top__]:
    >>>              @a = (1 .. 40);
    >>>>>            (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21, \
        22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40) = (1 .. 40);
    -------------------------------------------
    >>  littledemo.pl:2:[__top__]:
    >>>              $b = $a[4] + $a[5];
    >>>>             $b = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19, \
        20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40)[4];
    >>>>>            5 = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19, \
        20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40)[4];

=back

As these demos suggest, you can pass the C<$TRACE> variable through the
command line using the syntax C<< -d:DumpTrace=I<level> >>. In place of a
number, you may also use the keywords C<quiet> or C<verbose> which will
set the C<$TRACE> variable to 1 and 5, respectively.

By default C<Devel::DumpTrace> does not evaluate statements in any "system"
modules, which are defined as any module from a file that resides under
an absolute path in your system's C<@INC> list of directories. If the
C<$TRACE> variable is set to a value larger than 100, then this module
B<will> drill down into such modules. See also L</"EXCLUDE_PKG"> and
L</"INCLUDE_PKG"> for another way to exercise control over what packages
this module will explore.

For convenience, the C<$Devel::DumpTrace::TRACE> variable is aliased to
the C<$Devel::Trace::TRACE> variable. This way you can enable settings
in your program that can be used by both L<Devel::Trace|Devel::Trace>
and C<Devel::DumpTrace>.

=head2 C<$Devel::DumpTrace::DUMPTRACE_FH>

By default, all output from the C<Devel::DumpTrace> module
is written to standard error. This behavior can be changed
by setting C<$Devel::DumpTrace::DUMPTRACE_FH> to the desired
I/O handle:

    BEGIN {
       # if Devel::DumpTrace is loaded, direct output to trace.txt
       if ($INC{'Devel/DumpTrace.pm'}) {
          open $Devel::DumpTrace::DUMPTRACE_FH, '>', '/path/trace.txt';
       }
    }

The output stream for the C<Devel::DumpTrace> module can also be controlled
with the environment variable C<DUMPTRACE_FH>. If this variable is set
to C<STDOUT>, then output will be directed to standard output. If this
variable contains another value that looks like a filename, this module
will open a file with that name and write the trace output to that file.

B<< Backwards-incompatible change: >> in v0.06, this variable was called 
C<XTRACE_FH>.

=head2 C<$Devel::DumpTrace::ARRAY_ELEM_SEPARATOR = ','>

=head2 C<$Devel::DumpTrace::HASH_ENTRY_SEPARATOR = ';'>

=head2 C<< $Devel::DumpTrace::HASH_PAIR_SEPARATOR = '=>' >>

The C<Devel::DumpTrace> module uses the preceding default values as delimiters
when creating string representations of arrays, hashes, and array/hash
references. If you wish to use different delimiters for whatever reason
(maybe your arrays have a lot of elements with commas in them),
you can change these values.

=head2 C<< $Devel::DumpTrace::XEVAL_SEPARATOR = ':' >>

In normal (non-verbose) mode, C<Devel::DumpTrace> will display this token
between the name of a variable and its value (e.g., C<$c:23>). The
default token is a colon (C<:>), but you may change it by changing
the value of the variable C<$Devel::DumpTrace::XEVAL_SEPARATOR>.

=head2 %Devel::DumpTrace::EXCLUDE_PKG, %Devel::DumpTrace::INCLUDE_PKG

Sets of packages that this module will never/always explore.
These settings take precedence over the setting of the
C<$Devel::DumpTrace::TRACE> variable, and the settings of
C<%Devel::DumpTrace::INCLUDE_PKG> take precendence over the settings
of C<%Devel::DumpTrace::EXCLUDE_PKG> (that is, a package that is
specified in both C<%EXCLUDE_PKG> and C<%INCLUDE_PKG> will
be I<included>).

=head2 @Devel::DumpTrace::EXCLUDE_PATTERN, @Devel::DumpTrace::INCLUDE_PATTERN

List of regular expressions representing the packages that this
module will never/always trace through.

Patterns can be from the command line or at module import time by
passing arguments that begin with C<+> to include packages or
C<-> to exclude packages:

    # always trace through  Foo::xxx  packages
    perl -d:DumpTrace=+Foo::.* my_script.pl

    # trace through Foo::Bar but not through Foo::Baz
    perl -d:DumpTrace=+Foo::Bar,-Bar::Foo my_script.pl

Any pattern from user input will be implicitly anchored (bracketed
by C<^> and C<$>), so you must explicitly include wildcards
to match a general pattern of package names.

    # don't trace any package containing /Foo/ except for Xyz::Foo
    perl -d:DumpTrace=-.*Foo.*,+Xyz::Foo my_script.pl

Settings in C<@INCLUDE_PATTERN> take precendence over C<@EXCLUDE_PATTERN>,
so a package that matches a pattern in C<@INCLUDE_PATTERN> will always
be traced, even if it also matches one or more patterns in
<@EXCLUDE_PATTERN>.

    # -Foo::Bar is ignored, because Foo::Bar also matches included .*::Bar
    perl -d:DumpTrace=-Foo::Bar,+.*::Bar my_script.pl

=head1 CONFIGURATION AND ENVIRONMENT

C<Devel::DumpTrace> uses the C<DUMPTRACE_FH> and C<DUMPTRACE_LEVEL>
environment variables to configure some package variables.
See L</"VARIABLES">.
For Perl v5.8.8, which has a bug when the C<-d> switch is used
like C<perl -d:Foo=xxx ...>, supplying the C<DUMPTRACE_LEVEL>
environment variable is a workaround to this bug.

The C<DUMPTRACE_NOPPI> variable can be set to force this module
to use the basic code parser and to ignore the L<PPI|PPI>-based
version.

If the C<DUMPTRACE_PID> environment variable is set to a true value,
this module will include process ID information with the file and line
number in all trace output. This setting can be helpful in debugging
multi-process programs (programs that C<fork>). Since v0.23, the
trace output when C<DUMPTRACE_PID> is set also includes thread ID
information.

If the C<DUMPTRACE_TIME> environment variable is set to a true value,
this module will include program runtime information with the file
and line number in all trace output. Depending on the evaluation needs
of each line of the code, the timestamp associated with a line may
be created either immediately before or immediately after the line
is executed.

If the C<DUMPTRACE_COUNT> environment variable is set to a true value,
this module will include a count with the file and line number in all
trace output, indicating how many times your program has visited a
particular line of code.

The default behaviour of C<Devel::DumpTrace> is to include the name of
the current subroutine each time the file and line number are displayed.
If C<DUMPTRACE_NO_SUB> environment variable is set to a true value,
then the subroutine name will not be displayed.

C<DUMPTRACE_TIME>, C<DUMPTRACE_PID>, C<DUMPTRACE_COUNT>, and
C<DUMPTRACE_NO_SUB>  may be used separately or in any combination.

When more than one environment variable needs to be set, the caller
can use the C<DUMPTRACE> environment variable to set multiple variables
concisely. If C<$ENV{DUMPTRACE}> is set, this module will split
the variable value into key value pairs and update the other relevant
environment variables. That is,

    DUMPTRACE=PID=1,FH=trace.out,EXCLPKG=My::Module

is equivalent to the longer

    DUMPTRACE_PID=1 DUMPTRACE_FH=trace.out DUMPTRACE_EXCL=My::Module

If C<DUMPTRACE_COLOR> is set, and if the L<Term::ANSIColor|Term::ANSIColor>
module can be loaded, then C<Devel::DumpTrace> output will be colored in
the specified color. If your program produces output and you are writing
C<Devel::DumpTrace> output to your console, the different color of the
DumpTrace output will help the actual output from the program stand out.

Example:

    DUMPTRACE_COLOR="bold yellow on_black" perl -d:DumpTrace myScript.pl

=cut

Documented in Devel/DumpTrace/PPI.pm:  $ENV{DUMPTRACE_DUMB_ABBREV}

=head1 INCOMPATIBILITIES

None known.

=head1 EXPORT

Nothing is exported from this module.

=head1 DIAGNOSTICS

All output from this module is for diagnostics.

=head1 DEPENDENCIES

L<PadWalker|PadWalker> for arbitrary access to lexical variables.

L<Scalar::Util|Scalar::Util> for the reference identification
convenience methods.

=head1 BUGS AND LIMITATIONS

=head2 Parser limitations

Some known cases where the output of this module will
be incorrect or misleading include:

=head3 Multiple statements on one line

    $b = 7;
    $a=4; $b=++$a;
    =================================
    >>>>>            4=4; 7=++undef;
    >>>>>            5=4; 7=++4;


All expressions on a line are evaluated, not just expressions in the statement
currently being executed.

=head3 Statements with chained assignments; complex assignment expressions

    ($a,$b) = ('','bar');
    $a = $b = 'foo';
    >>>>> 'foo' = 'bar' = 'foo';

    $rin=$ein=3;
    >>    select $rout=$in,undef,$eout=$ein,0;
    >>>   select $rout=3,undef,undef=3,0;
    >>>>> select 3=3,undef,undef=3,0;

Everything to the right of the I<first> assignment operator in a
statement is evaluated I<before> the statement is executed.

=head3 Displayed value of @_ variable is unreliable

The displayed value of C<@_> inside a subroutine is subject to
some of the issues described in L<perlfunc/"caller">:

    ... be aware that setting @DB::args is best effort, intended for
    debugging or generating backtraces, and should not be relied upon
    ... a side effect of the current implementation means that effects
    of shift @_ can normally be undone (but not pop @_ or other splicing,
    and not if a reference to @_ has been taken, and subject to the caveat
    about reallocated elements), so @DB::args is actually a hybrid of the
    current state and initial state of @_ . Buyer beware.

That is, the displayed value of C<@_> inside a subroutine may be
corrupted. Different versions of Perl may have different behavior.

=head3 C<grep EXPR,LIST> and C<map EXPR,LIST> statements

C<grep EXPR,LIST> and C<map EXPR,LIST> constructions are evaluated
a single time, after the entier C<LIST> has been evaluated, and this
module does not let you drill down to how each element of the list
was evaluated with the given C<EXPR>. The constructions 
C<grep BLOCK LIST> and C<map BLOCK LIST>, however, will display the
C<BLOCK> evaluation for each element of the C<LIST>.

=head2 Basic parser limitations

This distribution ships with a L<PPI|PPI>-based parser
and a more basic parser that will be used if C<PPI> is not
available (or if you explicitly request to use the basic
parser). This parser is quite crude compared to the PPI-based
parser, and suffers from these additional known issues:

=head3 Multiple lines for one statement

    $a = ($b + $c                # ==> oops, all this module sees is
         + $d + $e);             #     $a = ($b + $c

Only the first line of code in an expression is evaluated.

=head3 String literals that contain variable names

    print STDERR "\$x is $x\n";  # ==> print STDERR "\4 is 4\n";
    $email = 'mob@cpan.org';     # ==> $email = 'mob().org'

The parser is not sophisticated enough to tell whether a sigil is
inside non-interpolated quotes.

=head3 Implicit C<$_>, C<@_>

It would be nice if this parser could detect when Perl was
implicitly using some variables and display the implicit variable.

    /expression/;        # actually  $_ =~ /expression/
    my $self = shift;    # actually  my $self = shift(@_);

That is not currently a capability of this module.

=head3 Special Perl variables are not recognized

    $a = join $/, 'foo', 'bar';  # ==> $a = join $/, 'foo', 'bar'

Special variables with pure alphanumeric names like C<@ARGV>, C<$_>,
and C<$1> will still be interpolated. I<Do see>
L<perlfunc/"caller"> I<for some important caveats about how>
C<@_> I<is represented by this module>.

For some of these limitations, there are easy workarounds
(break up chained assignments, put all statements on separate lines, etc.)
if you think the extra information provided by this module is worth the
effort to make your code more friendly for this module.

=head2 Other bugs or feature requests

Please report any other bugs or feature requests to
C<bug-Devel-DumpTrace at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-DumpTrace>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::DumpTrace

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-DumpTrace>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-DumpTrace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-DumpTrace>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-DumpTrace/>

=back

=head1 SEE ALSO

L<dumpvar.pl|perl5db.pl>, as used by the Perl debugger.

L<Devel::Trace|Devel::Trace>, L<PadWalker|PadWalker>.

L<Devel::DumpTrace::PPI|Devel::DumpTrace::PPI> is part of this 
distribution and provides similar functionality using L<PPI|PPI> 
to parse the source code.

L<Devel::TraceVars|Devel::TraceVars> is a very similar effort to
C<Devel::DumpTrace>, but this
module handles arrays, hashes, references, objects, lexical C<our>
variables, and addresses more edge cases.

L<Tie::Trace|Tie::Trace> provides facilities to watch the values
of specific variables, including stack trace information about
where and how the variables values were changed.

Ideas from the L<Devel::GlobalDestruction> module were used to
manage output during the end game of the traced script.

=head1 AUTHOR

Marty O'Brien, E<lt>mob at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
