=head1 NAME

Lexical::SealRequireHints - prevent leakage of lexical hints

=head1 SYNOPSIS

	use Lexical::SealRequireHints;

=head1 DESCRIPTION

This module works around two historical bugs in Perl's handling of the
C<%^H> (lexical hints) variable.  One bug causes lexical state in one
file to leak into another that is C<require>d/C<use>d from it.  This bug,
[perl #68590], was present from Perl 5.6 up to Perl 5.10, fixed in Perl
5.11.0.  The second bug causes lexical state (normally a blank C<%^H>
once the first bug is fixed) to leak outwards from C<utf8.pm>, if it is
automatically loaded during Unicode regular expression matching, into
whatever source is compiling at the time of the regexp match.  This bug,
[perl #73174], was present from Perl 5.8.7 up to Perl 5.11.5, fixed in
Perl 5.12.0.

Both of these bugs seriously damage the usability of any module relying
on C<%^H> for lexical scoping, on the affected Perl versions.  It is in
practice essential to work around these bugs when using such modules.
On versions of Perl that require such a workaround, this module globally
changes the behaviour of C<require>, including C<use> and the implicit
C<require> performed in Unicode regular expression matching, so that it
no longer exhibits these bugs.

The workaround supplied by this module takes effect the first time its
C<import> method is called.  Typically this will be done by means of a
C<use> statement.  This should be done as early as possible, because it
only affects C<require>/C<use> statements that are compiled after the
workaround goes into effect.  For C<use> statements, and C<require>
statements that are executed immediately and only once, it suffices
to invoke the workaround when loading the first module that will set
up vulnerable lexical state.  Delayed-action C<require> statements,
however, are more troublesome, and can require the workaround to be loaded
much earlier.  Ultimately, an affected Perl program may need to load
the workaround as very nearly its first action.  Invoking this module
multiple times, from multiple modules, is not a problem: the workaround
is only applied once, and applies to everything subsequently compiled.

This module is implemented in XS, with a pure Perl backup version for
systems that can't handle XS modules.  The XS version has a better chance
of playing nicely with other modules that modify C<require> handling.
The pure Perl version can't work at all on some Perl versions; users
of those versions must use the XS.  On all Perl versions suffering the
underlying hint leakage bug, pure Perl hooking of C<require> breaks the
use of C<require> without an explicit parameter (implicitly using C<$_>).

=head1 PERL VERSION DIFFERENCES

The history of the C<%^H> bugs is complex.  Here is a chronological
statement of the relevant changes.

=over

=item Perl 5.6.0

C<%^H> introduced.  It exists only as a hash at compile time.  It is not
localised by C<require>, so lexical hints leak into every module loaded,
which is bug [perl #68590].

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
hash that is modified during compilation, the value that it had at
each point in compilation is recorded in the compiled op tree, for later
examination at runtime.  It is in a special representation-sharing format,
and writes to C<%^H> are meant to be performed on both forms.  C<require>
does not localise the runtime form of C<%^H> (and still doesn't localise
the compile-time form).

A couple of special C<%^H> entries are erroneously written only to the
runtime form.

Pure Perl code, although it can localise the compile-time C<%^H> by
normal means, can't adequately localise the runtime C<%^H>, except by
using a string eval stack frame.  This makes a satisfactory global fix
for the leakage bug impossible in pure Perl.

=item Perl 5.10.1

C<require> now properly localises the runtime form of C<%^H>, but still
not the compile-time form.

A global fix is once again possible in pure Perl, because the fix only
needs to localise the compile-time form.

=item Perl 5.11.0

C<require> now properly localises both forms of C<%^H>, fixing [perl
#68590].  This makes [perl #73174] apparent without any workaround for
[perl #68590].

The special C<%^H> entries are now correctly written to both forms of
the hash.

=item Perl 5.12.0

The automatic loading of C<utf8.pm> during Unicode regular expression
matching now properly restores C<%^H>, fixing [perl #73174].

=back

=cut

package Lexical::SealRequireHints;

{ use 5.006; }
# Don't "use warnings" here because warnings.pm can include require
# statements that execute at runtime, and if they're compiled before
# this module takes effect then they won't get the magic needed to avoid
# leaking hints generated later.  We do need to set warning bits here,
# because it is necessary to turn *off* redefinition warnings for the
# pure Perl implementation (which can redefine CORE::GLOBAL::require).
# Not wanting to encode knowledge of specific warning bits, the only
# safe thing to do is to turn them all off.
BEGIN { ${^WARNING_BITS} = ""; }
# Also don't "use strict", because of consequences of compiling
# strict.pm's code.

our $VERSION = "0.011";

if("$]" >= 5.012) {
	# bug not present
	*import = sub {
		die "$_[0] does not take any importation arguments\n"
			unless @_ == 1;
	};
	*unimport = sub { die "$_[0] does not support unimportation\n" };
} elsif(eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
	1;
}) {
	# Successfully loaded XS.  Now preemptively load modules that
	# may be subject to delayed require statements in XSLoader or
	# things that it loaded.
	foreach(qw(Carp.pm Carp/Heavy.pm)) {
		eval { local $SIG{__DIE__}; require($_); 1; };
	}
} elsif("$]" < 5.007002) {
	die "pure Perl version of @{[__PACKAGE__]} can't work on pre-5.8 perl";
} elsif("$]" >= 5.009004 && "$]" < 5.010001) {
	die "pure Perl version of @{[__PACKAGE__]} can't work on perl 5.10.0";
} else {
	my $done;
	*import = sub {
		die "$_[0] does not take any importation arguments\n"
			unless @_ == 1;
		return if $done;
		$done = 1;
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
	};
	*unimport = sub { die "$_[0] does not support unimportation\n" };
}

=head1 BUGS

The operation of this module depends on influencing the compilation of
C<require>.  As a result, it cannot prevent lexical state leakage through
a C<require> statement that was compiled before this module was invoked.
Where problems occur, this module must be invoked earlier.

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

=head1 SEE ALSO

L<perlpragma>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2012, 2015, 2016, 2017
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
