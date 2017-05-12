# -*- Mode: perl -*-

use strict;
use 5.005;

package Getargs::Long;

use vars qw($VERSION @ISA @EXPORT);
$VERSION = sprintf "%d.%02d%02d", q/1.10.7/ =~ /(\d+)/g;

BEGIN
{
  die "This module is known to exercise a bug in 5.6.0. Please upgrade your perl.\n"
    if $] eq '5.006';
}

use Log::Agent;
use Data::Dumper;

require Exporter;
use vars qw(@EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(getargs cgetargs xgetargs cxgetargs);

#
# %ignore
#
# Cache whether argument names are to be handled case-insensitively or not,
# on a package basis.  Default is case-sensitive processing.
#
my %ignore = ();

#
# ->import
#
# Trap Exporter's one to handle 'ignorecase' here (or lack thereof).
# Then use ->export_to_level() to tell Exporter to continue the export
# as if its import method had been called directly via inheritance.
#
sub import {
	my $module = shift;
	my @syms = grep($_ ne 'ignorecase', @_);
	my $callpkg = caller;

	if (@syms == @_) {			# There was no "ignorecase" seen
		delete $ignore{$callpkg};
		logdbg 'info', "will process arguments case-sensitively in $callpkg";
	} else {
		$ignore{$callpkg} = 1;
		logdbg 'info', "will process arguments case-insensitively in $callpkg";
	}

	Getargs::Long->export_to_level(1, $module, @syms);
}

#
# %subcache
#
# Cache validation routine, indexed by "package::routine".
#
my %subcache = ();

#
# getargs
#
# Parse arguments for subroutine, and validate them if typechecking requested.
# Optional arguments with no default return undef.  Mandatory arguments cannot
# be undefined.
#
sub getargs (\@@) { _getargs(scalar(caller), 0, "", @_) }

#
# cgetargs
#
# Same as getargs, but cache data for next call.
#
# When called from within an eval, caching is not possible, so this routine
# must not be called.
#
sub cgetargs (\@@) {
	my $sub = (caller(1))[3];	# Anomaly in caller(), will also get pkg name
	logcroak "can't call cgetargs from within an eval"
		if $sub =~ /^\(eval/;
	_getargs(scalar(caller), 0, $sub, @_)
}

#
# xgetargs
#
# Like getargs(), but with extended specifications allowing to specify
# defaults for non-mandatory arguments.
#
sub xgetargs (\@@) { _getargs(scalar(caller), 1, "", @_) }

#
# cxgetargs
#
# Like cgetargs(), but with extended specifications allowing to specify
# defaults for non-mandatory arguments.  Be careful: those defaults are
# deep-cloned and "frozen", so to speak.
#
# When called from within an eval, caching is not possible, so this routine
# must not be called.
#
sub cxgetargs (\@@) {
	my $sub = (caller(1))[3];	# Anomaly in caller(), will also get pkg name
	logcroak "can't call cxgetargs from within an eval"
		if $sub =~ /^\(eval/;
	_getargs(scalar(caller), 1, $sub, @_)
}

#
# _getargs
#
# Factorized work for *getargs() routines
#
# Our signature is:
#
#    _getargs(
#		# arguments added by our wrappers
#		$callpkg, $extended, $subname,
#		# argument list to parse
#		\@x,
#		# optional switches
#		{
#			-strict			=> 1,		# unknown switches are fatal
#			-inplace		=> 1,		# edit \@x inplace: remove parsed args
#			-ignorecase		=> 1,		# override package's global
#			-extra			=> 0,		# suppress return of extra arguments
#		},
#		# argument definition list
#		<variable>
#	);
#
# With:
#   $callpkg        Calling package
#   $extended       Are they using x*getargs()?
#   $subname        Cache key, if we use it
#
# Returns the list of values in the same order given in the definition list
# (the <variable> part), followed by the extra arguments we did not recognize,
# with leading '-' removal and transformation to lowercase if ignorecase is on.
#
sub _getargs {
	my ($callpkg, $extended, $subname, $args) = splice(@_, 0, 4);

	logconfess "first argument must be a reference to the argument list"
		unless ref $args eq 'ARRAY';

	#
	# Check cache if told to do so.
	#

	if ($subname ne '') {
		my $sref = $subcache{$subname};
		if (defined $sref) {
			logdbg 'info', "calling cached subroutine $sref";
			return &$sref($args);
		} else {
			logdbg 'info', "no cached subroutine yet for $subname";
		}
	}

	#
	# Nothing in cache, or cache was disabled.
	#

	my $case_insensitive = $ignore{$callpkg} ? 1 : 0;
	logdbg 'info', "case_insensitive=$case_insensitive for package $callpkg";

	#
	# If next argument is a HASH, then it's a set of extra switches that
	# may alter our behaviour.  Parse them manually.
	#
	# Following are the defaults:
	#

	my $strict = 1;			# Fatal error on unknown switches
	my $inplace = 0;		# No inplace editing of arguments
	my $extra;				# Don't return extra args by default

	if (ref $_[0] eq 'HASH') {
		my $swref = shift;

		my %set = (
			-strict			=> \$strict,
			-ignorecase		=> \$case_insensitive,
			-inplace		=> \$inplace,
			-extra			=> \$extra,
		);

		while (my ($sw, $val) = each %$swref) {
			my $vset = $set{lc($sw)};
			logcroak "unknown switch $sw" unless ref $vset;
			$$vset = $val;
		}

		#
		# If they did not set -extra, compute suitable default: false
		# when -strict, true otherwise.
		#

		$extra = $strict ? 0 : 1 unless defined $extra;

		#
		# If strict, we ignore true settings for -inplace and -extra
		#

		if ($strict) {
			if ($inplace) {
				logcarp "ignoring -inplace when -strict";
				$inplace = 0;
			}
			if ($extra) {
				logcarp "ignoring -extra when -strict";
				$extra = 0;
			}
		}
	}

	#
	# If we have one argument, it may be '[list]' or 'x'.
	# In extended mode, we must have an even amount of arguments.
	#

	my @specs;				# User specification list
	my $all_optional = 0;	# True if all arguments are optional

	if (@_ == 1 && ref $_[0]) {
		logcroak "must use an array reference for optional args"
			unless ref $_[0] eq 'ARRAY';
		@specs = @{$_[0]};
		$all_optional = 1;
	} else {
		@specs = @_;
		logcroak "must supply an even amount of arguments in extend mode"
			if $extended && (@specs % 2);
	}

	#
	# Parse our argument list and compile it into @args
	#

	my %seen;
	my @args;				# List of [name, type, is_optional, default]

	for (my $i = 0, my $step = $extended ? 2 : 1; $i < @specs; $i += $step) {
		my $arg = $specs[$i];
		my ($name, $type, $optional, $dflt);
		if ($extended) {
			$name = $arg;
			my $spec = $specs[$i+1];
			if (ref $spec) {
				# Given as an array ref -> optional, with possible default
				logcroak "specs for optional '$name' are $spec, expected ARRAY"
					unless ref $spec eq 'ARRAY';
				($type, $dflt) = @$spec;
				$optional = 1;
			} else {
				# simple scalar is type, argument is mandatory
				$type = $spec;
				$optional = 0;
			}
		} else {
			# Can be either "name" or "name=Type"
			($name, $type) = $arg =~ /^-?(\w+)=(\S+)/;
			$name = $arg unless defined $name;
			$optional = $all_optional;
		}

		$name = lc($name) if $case_insensitive;
		$name =~ s/^-//;

		logcroak "argument name cannot be empty" if $name eq '';
		logcroak "argument name must be scalar, not $name" if ref $name;
		logcroak "duplicate argument definition for '$name'" if $seen{$name}++;

		push(@args, [
			$name,
			defined($type) ? $type : undef,
			$optional,
			defined($dflt) ? $dflt : undef
		]);
	}

	#
	# If caching, generate the subroutine that will perform the checks.
	#
	# We use logxcroak to report errors to the caller of the caller
	# of *getargs, i.e. the caller of the routine for which we're checking
	# the arguments.
	#

	if ($subname ne '') {
		my $lc = $case_insensitive ? 'lc' : '';
		my $sub = &q(<<'EOS');
:sub {
:	my $aref_orig = shift;
:	my @result;
:	my $cur;
:	my $isthere;
:	my $ctype;
:	local $Getargs::Long::dflt;
:	my $i = 0;
EOS
		$sub .= &q(<<EOS);
:	logxcroak 3, "expected an even number of arguments" if \@\$aref_orig % 2;
:
:	my \%args = map {
:		(\$i++ % 2) ? \$_ : $lc(/^-/ ? substr(\$_, 1) : \$_) } \@\$aref_orig;
EOS

		# Sanity check: no argument can be given twice
		$sub .= &q(<<EOS);
:	spot_dups(\$aref_orig, $case_insensitive, 3)
:		if 2 * scalar(keys \%args) != \@\$aref_orig;
:
EOS
		# Work on a copy if extra and no inplace
		if ($extra && !$inplace) {
			$sub .= &q(<<'EOS');
:	my $aref = [@$aref_orig];
EOS
		} else {
			$sub .= &q(<<'EOS');
:	my $aref = $aref_orig;
EOS
		}

		# Index arguments if inplace editing or extra
		if ($inplace || $extra) {
			$sub .= &q(<<'EOS');
:
:	my $idx;
:	my %idx;
:	for (my $j = 0; $j < @$aref; $j += 2) {
:		my $key = $aref->[$j];
:		$key =~ s/^-//;
EOS
			$sub .= &q(<<'EOS') if $case_insensitive;
:		$key = lc($key);
EOS
			$sub .= &q(<<'EOS');
:		$idx{$key} = $j;
:	}
:
EOS
		}

		foreach my $arg (@args) {
			my ($name, $type, $optional, $dflt) = @$arg;
			my $has_default = defined $dflt;
			local $^W = 0;		# Shut up Test::Harness
			$sub .= &q(<<EOS);
:	# Argument [name=$name, type=$type, optional=$optional, dflt=$dflt]
:	\$cur = undef;
:	\$isthere = 0;
:	if (exists \$args{$name}) {
:		\$isthere = 1;
:		my \$val = delete \$args{$name};
:		\$cur = \\\$val;
EOS
			$sub .= &q(<<EOS) if $inplace || $extra;
:		# Splice argument out
:		\$idx = \$idx{$name};
EOS
			$sub .= &q(<<'EOS') if $inplace || $extra;
:		splice(@$aref, $idx, 2);
:		while (my ($k, $v) = each %idx) {
:			$idx{$k} -= 2 if $v > $idx;
:		}
EOS
			$sub .= &q(<<'EOS');
:	}
EOS
			if ($optional) {
				if ($has_default) {
					$sub .= &q(<<EOS);
:	else {
:		eval {
:			package Getargs::Long::_;
:			no strict;
:			\$Getargs::Long::dflt = 
EOS
					my $obj = Data::Dumper->new([$dflt], []);
					$obj->Purity(1);
					$sub .= $obj->Dumpxs;
					$sub .= &q(<<'EOS');
:		};
:		$cur = \$Getargs::Long::dflt;
:	}
EOS
				}
			} else {
				$sub .= &q(<<EOS);
:	logxcroak 3, "mandatory argument '$name' missing" unless \$isthere;
EOS
			}
			if ($type ne '') {
				if ($optional) {
					$sub .= &q(<<EOS);
:	logxcroak 3, "argument '$name' cannot be undef"
:		if \$isthere && !defined \$\$cur;
EOS
				} else {
					$sub .= &q(<<EOS);
:	logxcroak 3, "argument '$name' cannot be undef" unless defined \$\$cur;
EOS
				}
				my $opt_is_there = $optional ? "\$isthere &&" : "";
				if ($type =~ /^[isn]$/) {		# Make sure it's a scalar
					# XXX Check that i is integer, s string and n natural
					$sub .= &q(<<EOS);
:	logxcroak 3,
:		"argument '$name' must be scalar (type '$type') but is \$\$cur"
:		if $opt_is_there ref \$\$cur;
EOS
				} else {
					$sub .= &q(<<EOS);
:	\$ctype = \$isthere ? ref \$\$cur : undef;
:	logxcroak 3, "argument '$name' must be of type $type but is \$ctype"
:		if $opt_is_there (UNIVERSAL::isa(\$\$cur, 'UNIVERSAL') ?
:			!\$\$cur->isa('$type') :
:			\$ctype ne '$type');
EOS
				}
			}
			$sub .= &q(<<'EOS');
:	push(@result, defined($cur) ? $$cur : undef);
:
EOS
		}

		# If we're strict, we must report unprocessed switches
		$sub .= &q(<<'EOS') if $strict;
:
:	spot_unknown(\%args, 3) if scalar keys %args;
:
EOS

		# Add extra unprocessed switches to the result list
		$sub .= &q(<<'EOS') if $extra;
:	push(@result, @$aref);
EOS
		$sub .= &q(<<'EOS');
:	return @result;
:}
EOS
		logdbg 'debug', "anonymous subroutine: $sub";
		my $code = eval $sub;
		if (chop($@)) {
			logerr "can't create subroutine for checking args of $subname: $@";
			logwarn "ignoring caching directive for $subname";
		} else {
			$subcache{$subname} = $code;
			logdbg 'info', "calling newly built subroutine $code";
			return &$code($args);
		}
	}

	#
	# No caching made, perform validation by interpreting the structure
	#
	# There is some unfortunate code duplication between the following checks
	# and the above routine-construction logic.  Some place are identical,
	# but the main argument processing loop is noticeably different, even
	# though the same logic is used.
	#

	logdbg 'info', "interpreting structure to validate arguments";

	my @result;
	my $cur;
	my $ctype;

	my $i = 0;
	my %args;

	$args = [@$args] if $extra && !$inplace;	# Work on a copy

	logxcroak 2, "expected an even number of arguments" if @$args % 2;

	if ($case_insensitive) {
		%args = map { ($i++ % 2) ? $_ : lc(/^-/ ? substr($_, 1) : $_) } @$args;
	} else {
		%args = map { ($i++ % 2) ? $_ :   (/^-/ ? substr($_, 1) : $_) } @$args;
	}

	# Sanity check: no argument can be given twice
	spot_dups($args, $case_insensitive, 2)
		if 2 * scalar(keys %args) != @$args;

	# Index arguments if inplace editing or extra
	my %idx;
	if ($inplace || $extra) {
		for (my $j = 0; $j < @$args; $j += 2) {
			my $key = $args->[$j];
			$key =~ s/^-//;
			$key = lc($key) if $case_insensitive;
			$idx{$key} = $j;
		}
	}

	# Process each argument
	foreach my $arg (@args) {
		my ($name, $type, $optional, $dflt) = @$arg;
		my $cur;
		my $isthere = 0;
		if (exists $args{$name}) {
			$isthere = 1;
			my $val = delete $args{$name};
			$cur = \$val;

			# Splice argument out if requested
			if ($inplace || $extra) {
				my $idx = $idx{$name};
				splice(@$args, $idx, 2);
				while (my ($k, $v) = each %idx) {
					$idx{$k} -= 2 if $v > $idx;
				}
			}
		} elsif ($optional) {
			$cur = \$dflt if defined $dflt;
		} else {
			logxcroak 2, "mandatory argument '$name' missing";
		}

		push(@result, defined($cur) ? $$cur : undef);
		next if !defined $type || $type eq '';

		if ($optional) {
			logxcroak 2, "argument '$name' cannot be undef"
				if $isthere && !defined $$cur;
		} else {
			logxcroak 2,
				"argument '$name' cannot be undef" unless defined $$cur;
		}

		# XXX Check that i is integer, s string and n natural
		if ($type =~ /^[isn]$/) {		# Make sure it's a scalar
			logxcroak 2,
				"argument '$name' must be scalar (type '$type') but is $$cur"
				if (!$optional || $isthere) && ref $$cur;
		} else {
			my $ctype = $isthere ? ref $$cur : undef;
			logxcroak 2, "argument '$name' must be of type $type but is $ctype"
				if (!$optional || $isthere) &&
					(UNIVERSAL::isa($$cur, 'UNIVERSAL') ?
						!$$cur->isa($type) :
						$ctype ne $type);
		}
	}

	# If we're strict, we must report unprocessed switches
	spot_unknown(\%args, 2) if $strict && scalar keys %args;

	# Add extra unprocessed switches to the result list
	push(@result, @$args) if $extra;

	return @result;
}

#
# spot_dups
#
# Given a list of arguments in $aref, where we know there are duplicate "keys",
# identify them and croak by listing the culprits.
#
sub spot_dups {
	my ($aref, $ignorecase, $level) = @_;
	my %seen;
	my @duplicates;
	for (my $i = 0; $i < @$aref; $i += 2) {
		my $key = $ignorecase ? lc($aref->[$i]) : $aref->[$i];
		$key =~ s/^-//;
		push(@duplicates, "-$key") if $seen{$key}++;
	}
	logconfess "bug in Getargs::Long -- should have found duplicates"
		unless @duplicates;
	logxcroak ++$level,
		"multiple switches given for: " . join(", ", @duplicates);
}

#
# spot_unknown
#
# Report keys held in supplied hashref as unknown switches.
#
sub spot_unknown {
	my ($href, $level) = @_;
	my @unprocessed = map { "-$_" } keys %$href;
	my $es = @unprocessed == 1 ? '' : 'es';
	logxcroak ++$level, "unknown switch$es: " . join(", ", @unprocessed);
}

sub q {
	local $_ = shift;
	s/^://gm;
	return $_;
}

1;

__END__

=head1 NAME

Getargs::Long - Named subroutine arguments, with optional type checking

=head1 SYNOPSIS

 use Getargs::Long;                     # case sensitive
 use Getargs::Long qw(ignorecase);      # case insensitive

 # Simple, args mandatory
 my ($val, $other) = getargs(@_, qw(val other));

 # Simple, args optional (in [] means optional)
 my ($val, $other) = getargs(@_, [qw(val other)]);

 # Simple with typechecking, args mandatory
 my ($val, $other) = getargs(@_, qw(val=Class::X other=ARRAY));

 # Simple with typechecking, args optional
 my ($val, $other) = getargs(@_, [qw(val=Class::X other=ARRAY)]);

 # Faster version, building dedicated argument parsing routine
 my ($val, $other) = cgetargs(@_, qw(val other));

 # Other cases, use full specs:
 my ($x, $y, $z, $a, $b, $c) = xgetargs(@_,

    # Non-mandatory, defaults to undef unless specified otherwise
    'x'     => ['i'],                   # integer, no default
    'y'     => ['ARRAY', ['a', 'b']],   # Has a default
    'z'     => [],                      # No typecheck, can be anything

    # Mandatory arguments
    'a'     => 'i',                     # integer (scalar)
    'b'     => 'TYPE',                  # TYPE or any heir of TYPE
    'c'     => undef,                   # unspecified type but mandatory
 );

 # Extract remaining unparsed args in @extra
 my ($val, $other, @extra) = getargs(@_, { -strict => 0 }, qw(val other));

 # Alter behaviour of the getargs() routines via switches in hashref
 my ($val, $other) = getargs(@_,
    {
        -strict         => 1,       # unknown switches are fatal
        -ignorecase     => 1,       # override package's global
        -inplace        => 1,       # edit @_ inplace: remove parsed args
        -extra          => 0,       # suppress return of extra arguments
    },
    qw(val other)
 );

=head1 DESCRIPTION

The C<Getargs::Long> module allows usage of named parameters in function
calls, along with optional argument type-checking.  It provides an easy
way to get at the parameters within the routine, and yields concise
descriptions for the common cases of all-mandatory and all-optional
parameter lists.

The validation of arguments can be done by a structure-driven routine
getargs() which is fine for infrequently called routines (but should be slower),
or via a dedicated routine created and compiled on the fly the fist time it is
needed, by using the cgetargs() family (expected to be faster).

The C<Log::Agent> module is used to report errors, which leaves to the
application the choice of the final logging method: to a file, to
STDERR, or to syslog.

=head1 EXAMPLES

Before going through the interface specification, a little example will
help illustrate both caller and callee sides.  Let's write a routine
that can be called as either:

 f(-x => 1, -y => 2, -z => 3);  # -switch form
 f(x => 1, y => 2, z => 3);     # concise form (- are optional)
 f(y => 1, x => 2);             # order changed, z may be omitted

Since we have an optional parameter I<z> but mandatory I<x> and I<y>, we
can't use the short form of getargs() and must therefore use xgetargs():

 sub f {
     my ($x, $y ,$z) = xgetargs(@_,
         -x => 'i',             # mandatory, integer
         -y => 'i',             # mandatory, integer
         -z => ['i', 0],        # optional integer, defaults to 0
     );
     # code use $x, $y, $z
 }

That's quite simple and direct if you think of [] as "optional".  Note that
we pass xgetargs() a I<reference> to @_.

If we had all arguments mandatory and wished to nonethless benefit from the
named specification at call time to avoid having the caller remember the
exact parameter ordering, we could write:

 sub f {
     my ($x, $y ,$z) = getargs(@_, qw(x=i y=i z=i));
     # code of f
 }

Without parameter type checking, that would be even more concise.  Besides,
if f() is frequently called, it might be more efficient to build a routine
dynamically to parse the arguments rather than letting getargs() parse the
same data structures again and again:

 sub f {
     my ($x, $y ,$z) = cgetargs(@_, qw(x y z));    # 'c' for cached/compiled
     # code of f
 }

If you call f() with an improper argument, logcroak() will be called to
issue an exception from the persepective of the caller, i.e. pointing to the
place f() is called instead of within f() at the getargs() call, which would
be rather useless.

Here are some more examples:

Example 1 -- All mandatory:

   sub f {
       my ($port, $server) = getargs(@_,
           qw(port=i server=HTTP::Server));
   }

   f(-server => $server, port => 80);  # or -port, since - is optional
   f(port => 80, server => $server);
   f(server => $server);               # WRONG: missing mandatory -port
   f(server => 80, port => 80);        # WRONG: -server not an HTTP::Server
   f(server => undef, port => 80);     # WRONG: -server cannot be undef

Example 2 -- All optional

   sub cmd {
       my ($a, $o) = getargs(@_, [qw(a o=s)]);
   }

   cmd();                      # OK
   cmd(-a => undef);           # OK -a accepts anything, even undef
   cmd(-a => 1, -o => "..");   # OK
   cmd(-a => 1, -o => undef);  # WRONG: -o does not accept undef
   cmd(-x => 1);               # WRONG: -x is not a known argument name

Example 3  -- Mixed optional / mandatory

   sub f {
       my ($x, $z) = xgetargs(@_,
           -x  => 'i',                 # -x mandatory integer
           -z  => ['n', -20.4],        # -z optional, defaults to -20.4
       );
   }

   f(x => 1, z => {});     # WRONG: z is not a numerical value
   f(z => 1, x => -2);     # OK
   f(-z => 1);             # WRONG: mandatory x is missing
   f(-z => undef);         # WRONG: z cannot be undef

Example 4 -- Parsing options

   sub f {
       my ($x, $z) = xgetargs(@_,
           { -strict => 0, -ignorecase => 1 },
           -x  => 'i',                 # -x mandatory integer
           -z  => ['n', -20.4],        # -z optional, defaults to -20.4
       );
   }

   f(x => 1, foo => {});   # OK, -foo ignored since not strict
   f(-X => 1);             # OK, -X actually specifies -x with ignorecase

=head1 INTERFACE

All the routines take a mandatory first argument, called I<arglist>,
which is the array containing the named arguments for the routine
(i.e. a succession of I<name> => I<value> tuples).  This array is implicitely
passed as reference, and will usually be given as C<@_>.

All the routines take an optional I<options> argument which comes in the
second place.  It is an hash reference containing named options that
alter the behaviour of the routine.  More details given in the L<Options>
section.

All the routines return a list of the arguments in the order they are
specified, each I<slot> in the list being either the argument value, if
present, or C<undef> if missing (and not mandatory).

=head2 Simple Cases

Simple cases are handled by getargs(): named arguments should either be
I<all mandatory> or I<all optional>, and there is no provision for specifying
a default value for optional parameters.

The getargs() routine and its cousin cgetargs() have two different interfaces,
depending on whether the arguments are all mandatory or all optional.  We'll
only specify for getargs(), but the signature of cgetargs() is identical.

=over 4

=item getargs I<arglist>, I<options>, I<arg_spec1>, I<arg_spec2>, ...

We'll be ignoring the I<options> argument from our discussion.  See the
L<Options> section for details.

All the routine formal arguments specified by I<arg_spec1>, I<arg_spec2>,
etc... are mandatory.  If I<arg_spec1> is only a name, then it specifies
a mandatory formal argument of that name, which can be of any type, even
undef.  If the name is followed by C<=type> then C<type> specifies the
argument type: usually a reference type, unless 'i', 'n' or 's' is used
for integer, natural and string scalars.

Currently, types 'i', 'n' and 's' all mean the same thing: that the
argument must be a scalar.  A future implementation will probably ensure
'i' and 'n' hold integers and natural numbers respectively, 's' being
the placeholder for anything else that is defined.

For instance:

    foo               expects mandatory "foo" of "-foo" argument (undef ok)
    foo=s             idem, and argument cannot be undef or reference
    foo=i             value of argument -foo must be an integer
    foo=My::Package   foo is a blessed object, inheriting from My::Package
    foo=ARRAY         foo is an ARRAY reference

The rule for determing whether C<foo=X> means C<foo> is a reference C<X>
or C<foo> is an object whose class is an heir of C<X> depends on the
argument value at runtime: if it is an unblessed ref, strict reference
equality is expected.  If it is a blessed ref, type conformance is based
on inheritance, as you would expect.

Example:

    sub f {
        my ($port, $server) = getargs(@_,
            qw(port=i server=HTTP::Server));
    }

Some calls:

    f(-server => $server, port => 80);  # or -port, since - is optional
    f(port => 80, server => $server);
    f(server => $server);               # WRONG: missing mandatory -port
    f(server => 80, port => 80);        # WRONG: -server not an HTTP::Server
    f(server => undef, port => 80);     # WRONG: -server cannot be undef

By default, named argument processing is case-sensitive but there is an
option to ignore case.

=item getargs I<arglist>, I<options>, I<array_ref>

This form specifies that all the formal arguments specified in the
I<array_ref> are optional.  Think of the '[' and ']' (which you'll probably
use to supply the reference as a manifest constant) as syntactic markers
for optional things.  In the traditional Unix command line description,
something like:

    cmd [-a] [-o file]

typically denotes that options C<-a> and C<-o> are optional, and that C<-o>
takes one argument, a file name.  To specify the same things for routine
arguments using getargs():

    sub cmd {
        my ($a, $o) = getargs(@_, [qw(a o=s)]);
    }

Here however, the C<-a> argument can be anything: we're not specifying
switches, we're specifying I<named> arguments.  Big difference.

Some calls:

    cmd();                      # OK
    cmd(-a => undef);           # OK -a accepts anything, even undef
    cmd(-a => 1, -o => "..");   # OK
    cmd(-a => 1, -o => undef);  # WRONG: -o does not accept undef
    cmd(-x => 1);               # WRONG: -x is not a known argument name

It is important to note that there can only be tuples when using named
arguments, which means that the routine is called with an I<even> number
of arguments.  If you forget a C<,> separator between arguments, getargs()
will complain about an I<odd> number of arguments (provided the resulting
code still parses as valid Perl, naturally, or you'll never get a chance
to reach the execution of getargs() anyway).

=item cgetargs I<same args as getargs>

The cgetargs() routine behaves exactly as the getargs() routine: it takes
the same arguments, returns the same list.  The only difference is that
the first time it is called, it builds a routine to process the arguments,
and then calls it.

On subsequent calls to cgetargs() for the same routine, the cached argument
parsing routine is re-used to analyze the arguments.  For frequently called
routines, this might be a win, even though Perl still needs to construct the
argument list to cgetargs() and call it.

=back

=head2 Complex Cases

The xgetargs() routine and its cousin cxgetargs() (for the caching version)
allow for a more verbose description of named parameters which allows
specifying arguments that are mandatory or optional, and also give default
values to optional arguments.

=over 4

=item xgetargs I<arglist>, I<options>, I<name> => I<type>, ...

We'll be ignoring the I<options> argument from our discussion.  See L<Options>
for details.

There can be as many I<name> => I<type> tuples as necessary to describe all
the formal arguments of the routine.  The I<name> refers to the argument
name, and I<type> specifies both the mandatory nature and the expected type.
You may use I<name> or I<-name> to specify an argument called I<name>, and
the caller will also be able to spell it as he wishes.
The I<type> is encoded as follows:

    "i"      mandatory integer (scalar)
    "s"      mandatory string (scalar)
    "TYPE"   mandatory ref of type TYPE, or heir of type TYPE
    undef    unspecified type, but mandatory argument
    ["i"]    optional integer
    ["s"]    optional string
    ["TYPE"] optional ref of type TYPE, or heir of type TYPE

For optional parameter, an optional second value may be inserted in the
list to specify a default value.  For instance, the tupple:

    'y' => ['HASH', { a => 1, b => 2 }]

specifies an optional named argument I<y>, which is expected to be a HASH
reference, and whose default value is the hash given.

You may specify an expression as default value instead of giving a manifest
constant, but B<BEWARE>: the cxgetargs() routine will take a snapshot of
your expression when building its analyzing routine.  It's of no consequence
when using a manifest constant, but when using an expression, it will be
evaluated B<once> and the result of that evaluation will be taken as the
manifest constant to use subsequently (and this does B<not> mean the B<same>
reference will be returned, only the same topological structure as the one
we evaluated during caching).

Example:

    sub f {
        my ($x, $z) = cxgetargs(@_,
            -x  => 'i',                 # -x mandatory integer
            -z  => ['n', -20.4],        # -z optional, defaults to -20.4
        );
    }

    f(x => 1, z => {});     # WRONG: z is not a numerical value
    f(z => 1, x => -2);     # OK
    f(-z => 1);             # WRONG: mandatory x is missing
    f(-z => undef);         # WRONG: z cannot be undef

Remember that we are dealing with named parameters for a routine call,
not with option parsing.  Therefore, we are always expecting an I<even>
number of arguments, and those arguments are tuples I<name> => I<value>.

=back

=head2 Options

All the getargs() and xgetargs() routines take an optional hash reference as
second argument.  Keys in this hash define options that apply locally to
the call.  In the case of caching routines, e.g. cxgetargs(), the options
are only considered the first time, when the analyzing routine is built,
and are ignored on subsequent calls.  Therefore, it is wise to use manifest
constants when specifying options, or use the non-caching function family
instead if your options need to be dynamically computed (please, don't do that).

Options given there must be spelled out with the leading C<-> and are
case sensitive.  To enable an option, give a true value.  For instance:

    sub f {
        my ($x, $z) = cxgetargs(@_,
            { -strict => 0, -ignorecase => 1 },
            -x  => 'i',                 # -x mandatory integer
            -z  => ['n', -20.4],        # -z optional, defaults to -20.4
        );
    }

supplies two options, turning C<-ignorecase> on and C<-strict> off.

The available options are, in alphabetical order:

=over 4

=item -extra

Whether to report extra unknown arguments at the end of the argument list.
Example:

    my ($x, $y, @extra) = getargs(@_,
        { -extra => 1, -strict => 0 }, qw(x y));

Your setting is forced to false when C<-strict> is true.  The default
value is the negation of the boolean C<-strict> setting, which means
the above can be rewritten as:

    my ($x, $y, @extra) = getargs(@_, { -strict => 0 }, qw(x y));

which will implicitely set -extra to be true.  This is usually what you
want when not strict, i.e. get at the other parameters.  Assuming we
were writing the above for a function f(), calling:

    f(-x => 1, -y => 2, -other => 5);

would set:

    @extra = (-other => 5);

An alternative when you are not strict is to make use of the C<-inplace>
option to edit @_ inplace.

=item -ignorecase

Turn case-insensitive named parameters.  False by default.  Actually, if
not explicitely specified, the default setting depends on the way
C<Getargs::Long> was imported within the package scope.  If you said:

    use Getargs::Long;

then the default is indeed to be case-sensitive.  However, if you said:

    use Getargs::Long qw(ignorecase);

then the default for the package scope is to be case-insensitive.  You may
still specify the C<-ignorecase> option to force case sensitivity on a
per-routine basis, although I would never do such a thing and stick to a
uniform case sensitivity on a package basis.

=item -inplace

Whether to edit the routine's argument list inplace, removing processed
arguments as they are found and leaving unprocessed ones.  False by default.

Your setting is forced to false when C<-strict> is true, naturally, since
an unknown argument is an error.

=item -strict

Whether unknown named parameters are fatal.  True by default.
When C<-strict> is true, the C<-inplace> and C<-extra> options you may
specify are ignored and forced to false.

=back

=head1 BUGS

Currently, types 'i', 'n' and 's' all mean the same thing, but that will
change.  Don't take the current implementation's deficiency as an excuse
for lamely specifying your scalar types.

You must be careful in this implementation to list options and variables
in the very same order.  Some day, I will probably add another routine to
take arguments the way C<Getopt::Long> does to cope with this ordering
problem (but it forces to spell out variables twice -- once for declaration,
and once for specifying a pointer to it).

=head1 RELATED MODULE

See L<Params::Validate> for another take at parameter validation.  It is
a completely independant module, developped by Dave Rolsky, which may
also interest you.  Its interface and purpose are different though.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See the file LICENSE in the distribution for
details.

=head1 AUTHOR

The original code (written before September 15, 2004) was written by 
Raphael Manfredi E<lt>Raphael_Manfredi@pobox.comE<gt>.

Maintenance of this module is now being done by David Coppit
E<lt>david@coppit.orgE<gt>.

=head1 SEE ALSO

L<Log::Agent>, L<Params::Validate>

=cut

