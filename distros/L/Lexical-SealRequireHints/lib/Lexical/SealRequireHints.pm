=head1 NAME

Lexical::SealRequireHints - prevent leakage of lexical hints

=head1 SYNOPSIS

    use Lexical::SealRequireHints;

=head1 DESCRIPTION

This module works around two historical bugs in Perl's handling of the
C<%^H> (lexical hints) variable.  One bug causes lexical state in one
file to leak into another that is C<require>d/C<use>d/C<do>ed from it.
This bug, [perl #68590], was present from Perl 5.6 up to Perl 5.10, fixed
in Perl 5.11.0.  The second bug causes lexical state (normally a blank
C<%^H> once the first bug is fixed) to leak outwards from C<utf8.pm>, if
it is automatically loaded during Unicode regular expression matching,
into whatever source is compiling at the time of the regexp match.
This bug, [perl #73174], was present from Perl 5.8.7 up to Perl 5.11.5,
fixed in Perl 5.12.0.

Both of these bugs seriously damage the usability of any module relying
on C<%^H> for lexical scoping, on the affected Perl versions.  It is in
practice essential to work around these bugs when using such modules.
On versions of Perl that require such a workaround, this module globally
changes the behaviour of C<require>, including C<use> and the implicit
C<require> performed in Unicode regular expression matching, and of C<do>,
so that they no longer exhibit these bugs.

The workaround supplied by this module takes effect the first time its
C<import> method is called.  Typically this will be done by means of a
C<use> statement.  This should be done as early as possible, because it
only affects C<require>/C<use>/C<do> statements that are compiled after
the workaround goes into effect.  For C<use> statements, and C<require>
and C<do> statements that are executed immediately and only once,
it suffices to invoke the workaround when loading the first module
that will set up vulnerable lexical state.  Delayed-action C<require>
and C<do> statements, however, are more troublesome, and can require
the workaround to be loaded much earlier.  Ultimately, an affected Perl
program may need to load the workaround as very nearly its first action.
Invoking this module multiple times, from multiple modules, is not a
problem: the workaround is only applied once, and applies to everything
subsequently compiled.

This module is implemented in XS, with a pure Perl backup version for
systems that can't handle XS modules.  The XS version has a better
chance of playing nicely with other modules that modify C<require>
or C<do> handling.  The pure Perl version can't work at all on some
Perl versions; users of those versions must use the XS.  On all Perl
versions suffering the underlying hint leakage bug, pure Perl hooking
of C<require> breaks the use of C<require> without an explicit parameter
(implicitly using C<$_>).

=head1 PERL VERSION DIFFERENCES

The history of the C<%^H> bugs is complex.  Here is a chronological
statement of the relevant changes.

=over

=item Perl 5.6.0

C<%^H> introduced.  It exists only as a hash at compile time.  It is not
localised by C<require>/C<do>, so lexical hints leak into every module
loaded, which is bug [perl #68590].

The C<CORE::GLOBAL> mechanism doesn't work cleanly for C<require>, because
overriding C<require> loses the necessary special parsing of bareword
arguments to it.  As a result, pure Perl code can't properly globally
affect the behaviour of C<require>.  Pure Perl code can localise C<%^H>
itself for any particular C<require> invocation, but a global fix is
only possible through XS.

=item Perl 5.7.2

The C<CORE::GLOBAL> mechanism now works cleanly for C<require>, so pure
Perl code can globally affect the behaviour of C<require> to achieve a
global fix for the bug.

=item Perl 5.8.7

When C<utf8.pm> is automatically loaded during Unicode regular expression
matching, C<%^H> now leaks outward from it into whatever source is
compiling at the time of the regexp match, which is bug [perl #73174].
It often goes unnoticed, because [perl #68590] makes C<%^H> leak into
C<utf8.pm> which then doesn't modify it, so what leaks out tends to
be identical to what leaked in.  If [perl #68590] is worked around,
however, C<%^H> tends to be (correctly) blank inside C<utf8.pm>, and
this bug therefore blanks it for the outer module.

=item Perl 5.9.4

C<%^H> now exists in two forms.  In addition to the relatively ordinary
hash that is modified during compilation, the value that it had at each
point in compilation is recorded in the compiled op tree, for later
examination at runtime.  It is in a special representation-sharing
format, and writes to C<%^H> are meant to be performed on both forms.
C<require>/C<do> does not localise the runtime form of C<%^H> (and still
doesn't localise the compile-time form).

A couple of special C<%^H> entries are erroneously written only to the
runtime form.

Pure Perl code, although it can localise the compile-time C<%^H> by
normal means, can't adequately localise the runtime C<%^H>, except by
using a string eval stack frame.  This makes a satisfactory global fix
for the leakage bug impossible in pure Perl.

=item Perl 5.10.1

C<require>/C<do> now properly localise the runtime form of C<%^H>,
but still not the compile-time form.

A global fix is once again possible in pure Perl, because the fix only
needs to localise the compile-time form.

=item Perl 5.11.0

C<require>/C<do> now properly localise both forms of C<%^H>, fixing
[perl #68590].  This makes [perl #73174] apparent without any workaround
for [perl #68590].

The special C<%^H> entries are now correctly written to both forms of
the hash.

=item Perl 5.12.0

The automatic loading of C<utf8.pm> during Unicode regular expression
matching now properly restores C<%^H>, fixing [perl #73174].

=back

=cut

package Lexical::SealRequireHints;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.012";

my($install_compilation_workaround, $install_full_workaround_idempotently);
$install_full_workaround_idempotently = sub {
	$install_full_workaround_idempotently =
		sub { die "unsuccessful workaround installation" };
	my $icw = $install_compilation_workaround;
	$install_compilation_workaround = undef;
	$icw->();
	if(exists $INC{"AutoLoader.pm"}) {
		# The "require" statements in AutoLoader were compiled
		# before we put the workaround in place, and so are
		# vulnerable.  They're capable of loading an open-ended
		# set of files, so the vulnerability can't be allowed
		# to stand.  So we delete AutoLoader's compiled code
		# and load in anew, to get it compiled in a form that's
		# subject to the workaround.
		no strict "refs";
		my $dynaloader_shares = defined(&{"DynaLoader::AUTOLOAD"}) &&
			\&{"DynaLoader::AUTOLOAD"} ==
				\&{"AutoLoader::AUTOLOAD"};
		foreach my $k (sort keys %{"AutoLoader::"}) {
			undef *{"AutoLoader::$k"} unless $k =~ /::\z/;
		}
		delete $INC{"AutoLoader.pm"};
		scalar(require AutoLoader);
		if($dynaloader_shares) {
			no warnings "redefine";
			*{"DynaLoader::AUTOLOAD"} = \&{"AutoLoader::AUTOLOAD"};
		}
	}
	if(exists $INC{"utf8_heavy.pl"}) {
		# The "require" and "do" statements in utf8_heavy.pl
		# were compiled before we put the workaround in place,
		# and so are vulnerable.  They're capable of loading an
		# open-ended set of files, so the vulnerability can't
		# be allowed to stand.	So we delete utf8_heavy.pl's
		# compiled code and load in anew, to get it compiled in
		# a form that's subject to the workaround.
		no strict "refs";
		foreach(qw(DEBUG SWASHGET SWASHNEW croak DESTROY)) {
			undef *{"utf8::$_"} if exists ${"utf8::"}{$_};
		}
		delete $INC{"utf8_heavy.pl"};
		scalar(require "utf8_heavy.pl");
	}
	my %direct_delayed_loads = (
		# This hash lists all the files that may be loaded in
		# a delayed fashion by files that may be loaded as a
		# result of loading this module or which may be loaded
		# too early to get this module in first.  Delayed loading
		# refers to loading by means of a "require" that is not
		# executed during loading of the file containing the
		# "require".  The significance of that is that such a
		# "require" may have been compiled before we installed
		# the workaround, thus being vulnerable to hint leakage,
		# and is liable to be executed later when some hints
		# have actually been set.
		"AutoLoader.pm" => [
			# AutoLoader has a specific delayed load of
			# Carp.pm, and no other specific delayed loads,
			# but it also performs delayed loads of an
			# open-ended set of files.  Doing so is its
			# core purpose.  This situation can't be dealt
			# with by the preemptive loading that this hash
			# supports, and needs its own handling (above).
		],
		"B.pm" => [],
		"Carp.pm" => [qw(Carp/Heavy.pm)],
		"Carp/Heavy.pm" => [],
		"Config.pm" => ["$]" >= 5.008007 ? qw(Config_heavy.pl) : ()],
		"Config_git.pl" => [],
		"Config_heavy.pl" => [
			("$]" >= 5.010001 ? qw(Config_git.pl) : ()),
		],
		"DynaLoader.pm" => [qw(Carp.pm)],
		"Exporter.pm" => [qw(Carp.pm Exporter/Heavy.pm)],
		"Exporter/Heavy.pm" => [qw(Carp.pm)],
		"List/Util.pm" => [],
		"List/Util/PP.pm" => [qw(Carp.pm Scalar/Util.pm)],
		"Mac/FileSpec/Unixish.pm" => [],
		"Scalar/Util.pm" => [qw(Carp.pm)],
		"Scalar/Util/PP.pm" => [qw(overload.pm)],
		"XSLoader.pm" => [qw(Carp.pm DynaLoader.pm)],
		"feature.pm" => [qw(Carp.pm)],
		"mro.pm" => [],
		"overload.pm" => [
			("$]" >= 5.008001 ? qw(Scalar/Util.pm) : ()),
			("$]" >= 5.011000 ? qw(mro.pm) : ()),
		],
		"overload/numbers.pm" => [],
		"overloading.pm" => [qw(overload/numbers.pm)],
		"strict.pm" => [qw(Carp.pm)],
		"utf8.pm" => [qw(Carp.pm utf8_heavy.pl)],
		"utf8_heavy.pl" => [
			# utf8_heavy.pl has a specific delayed load of
			# Carp.pm, but it also performs delayed loads
			# of an open-ended set of files.  This situation
			# can't be dealt with by the preemptive loading
			# that this hash supports, and needs its own
			# handling (above).
		],
		"vars.pm" => [qw(Carp.pm)],
		"warnings.pm" => [qw(Carp.pm Carp/Heavy.pm)],
		"warnings/register.pm" => [],
	);
	foreach my $already (sort keys %INC) {
		foreach my $need (@{$direct_delayed_loads{$already} || []}) {
			# Loading the target file now means that if the
			# vulnerable "require" executes later then it
			# won't actually be causing file loading, so no
			# hint leakage will happen.  This "require" is
			# itself vulnerable, but so are all the "require"s
			# that happened immediately during loading of
			# this module; we expect that this module is
			# loaded early enough that there are no hints set
			# that would be a problem.  Because we're doing
			# this loading after installing the workaround,
			# the target file's "require"s won't themselves
			# be vulnerable, so we don't need to recurse.
			scalar(require($need));
		}
	}
	$install_full_workaround_idempotently = sub {};
};

if("$]" >= 5.012) {
	# bug not present
	$install_full_workaround_idempotently = sub {};
} elsif(eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
	1;
}) {
	# successfully loaded XS
	$install_compilation_workaround = \&_install_compilation_workaround;
} elsif("$]" < 5.007002) {
	die "pure Perl version of @{[__PACKAGE__]} can't work on pre-5.8 perl";
} elsif("$]" >= 5.009004 && "$]" < 5.010001) {
	die "pure Perl version of @{[__PACKAGE__]} can't work on perl 5.10.0";
} else {
	$install_compilation_workaround = sub {
		my $next_require = defined(&CORE::GLOBAL::require) ?
			\&CORE::GLOBAL::require : sub {
				my($arg) = @_;
				# The shenanigans with $CORE::GLOBAL::{require}
				# are required because if there's a
				# &CORE::GLOBAL::require when the eval is
				# executed (compiling the CORE::require it
				# contains) then the CORE::require in there is
				# interpreted as plain require on some Perl
				# versions, leading to recursion.
				my $grequire = $CORE::GLOBAL::{require};
				delete $CORE::GLOBAL::{require};
				my $requirer = eval qq{
					package @{[scalar(caller(0))]};
					sub { scalar(CORE::require(\$_[0])) };
				};
				$CORE::GLOBAL::{require} = $grequire;
				return scalar($requirer->($arg));
			};
		no warnings qw(redefine prototype);
		*CORE::GLOBAL::require = sub ($) {
			die "wrong number of arguments to require\n"
				unless @_ == 1;
			my($arg) = @_;
			# Some reference to $next_require is required
			# at this level of subroutine so that it will
			# be closed over and hence made available to
			# the string eval.
			my $nr = $next_require;
			my $requirer = eval qq{
				package @{[scalar(caller(0))]};
				sub { scalar(\$next_require->(\$_[0])) };
			};
			# We must localise %^H when performing a require
			# with a filename, but not a require with a
			# version number.  This is because on Perl 5.9.5
			# and above require with a version number does an
			# internal importation from the "feature" module,
			# which is intentional behaviour that must be
			# allowed to affect %^H.  (That's logically the
			# wrong place for the feature importation, but
			# it's too late to change how old Perls do it.)
			# A version number is an argument that is either
			# numeric or, from Perl 5.9.2 onwards, a v-string.
			my $must_localise = ($arg^$arg) ne "0" &&
				!("$]" >= 5.009002 && ref(\$arg) eq "VSTRING");
			# On Perl 5.11 we need to set the HINT_LOCALIZE_HH
			# bit to get proper restoration of %^H by the
			# swash loading code.
			$^H |= 0x20000 if "$]" >= 5.011 && $must_localise;
			# Compile-time %^H gets localised by the
			# "local %^H".	Runtime %^H doesn't exist prior
			# to Perl 5.9.4, and on Perl 5.10.1 and above is
			# correctly localised by require.  Between those
			# two regimes there's an area where we can't
			# correctly localise runtime %^H in pure Perl,
			# short of putting an eval frame around the
			# require, so we don't use this implementation in
			# that region.
			local %^H if $must_localise;
			return scalar($requirer->($arg));
		};
		my $next_do = defined(&CORE::GLOBAL::do) ?
			\&CORE::GLOBAL::do : sub {
				my($arg) = @_;
				my $gdo = $CORE::GLOBAL::{do};
				delete $CORE::GLOBAL::{do};
				my $doer = eval qq{
					package @{[scalar(caller(0))]};
					sub { CORE::do(\$_[0]) };
				};
				$CORE::GLOBAL::{do} = $gdo;
				return $doer->($arg);
			};
		no warnings qw(redefine prototype);
		*CORE::GLOBAL::do = sub ($) {
			die "wrong number of arguments to do\n"
				unless @_ == 1;
			my($arg) = @_;
			my $nd = $next_do;
			my $doer = eval qq{
				package @{[scalar(caller(0))]};
				sub { \$next_do->(\$_[0]) };
			};
			$^H |= 0x20000 if "$]" >= 5.011;
			local %^H;
			return $doer->($arg);
		};
	};
}

sub import {
	die "$_[0] does not take any importation arguments\n"
		unless @_ == 1;
	$install_full_workaround_idempotently->();
	return;
}

sub unimport {
	die "$_[0] does not support unimportation\n";
}

=head1 BUGS

The operation of this module depends on influencing the compilation
of C<require> and C<do>.  As a result, it cannot prevent lexical state
leakage through a C<require>/C<do> statement that was compiled before
this module was invoked.  Where problems occur, this module must be
invoked earlier.

On all Perl versions that need a fix for the lexical hint leakage bug,
the pure Perl implementation of this module unavoidably breaks the use
of C<require> without an explicit parameter (implicitly using C<$_>).
This is due to another bug in the Perl core, fixed in Perl 5.15.5, and is
inherent to the mechanism by which pure Perl code can hook C<require>.
The use of implicit C<$_> with C<require> is rare, so although this
state of affairs is faulty it will actually work for most programs.
Perl versions 5.12.0 and greater, despite having the C<require> hooking
bug, don't actually exhibit a problem with the pure Perl version of this
module, because with the lexical hint leakage bug fixed there is no need
for this module to hook C<require>.

There is a bug on Perl versions 5.15.5 to 5.15.7 affecting C<do> which,
among other effects, causes C<%^H> to leak into C<do>ed files.  It is
not the same bug that affected Perl 5.6 to 5.11.  This module currently
does not work around this bug at all, but its test suite does detect it.
As a result, this module fails its test suite on those Perl versions.
This could change in future versions of this module.

=head1 SEE ALSO

L<perlpragma>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2012, 2015, 2016, 2017, 2023
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
