#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

# _repo_path(@parts)
# Builds an absolute path rooted at the repository checkout, independent of
# the caller's own working directory.
# Input: path segment strings.
# Output: absolute path string.
sub _repo_path {
    return File::Spec->rel2abs( File::Spec->catfile( $RealBin, File::Spec->updir, @_ ) );
}

# _override_dies($no_warnings_line, $override_line)
# Runs a throwaway child Perl process that declares a named sub "sleep" with
# prototype "(;$)" - the exact prototype CI's Time::HiRes gives
# Developer::Dashboard::RuntimeManager::sleep, since RuntimeManager.pm imports
# its sleep from Time::HiRes and Time::HiRes's own sleep prototype differs by
# Perl/Time::HiRes version - then applies the given "no warnings" pragma and
# glob-assignment override line under `use warnings FATAL => 'all'`, exactly
# as this project's test suite compiles.
#
# A fresh child process is used, not an in-process eval, so a fatal warning
# cannot take the harness down with it, and the scenario is built from a
# hand-declared prototype rather than depending on whichever Time::HiRes
# happens to be installed on the machine running THIS test - the whole point
# being that the bug is invisible on a machine whose local Time::HiRes
# already agrees with the override's own prototype (as this project's Docker
# image's Perl 5.40.1 does; CI's Perl 5.44 does not).
#
# Input: two strings of Perl source - the "no warnings" pragma line, and the
# glob-assignment override line under test.
# Output: 1 if the child process died on a warning, 0 if it completed; the
# captured stderr is returned as well for a diagnostic message.
sub _override_dies {
    my ( $no_warnings_line, $override_line ) = @_;
    my $script = <<"PERL";
use strict;
use warnings FATAL => 'all';
package Fake::Sleeper;
sub sleep (;\$) { return 99 }
package main;
$no_warnings_line
$override_line
print "OK\\n";
PERL
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, '-e', $script );
    };
    return ( $exit != 0, $stderr );
}

# The bug as it originally shipped: `no warnings 'redefine'` alone, with an
# explicit "(;\@)" prototype on the override. The mismatch against the
# existing "(;\$)" is a SEPARATE warning category ('prototype'), which
# 'redefine' never touches.
{
    my ( $died, $stderr ) = _override_dies(
        q{no warnings 'redefine';},
        '*Fake::Sleeper::sleep = sub (;@) { return 0 };',
    );
    ok( $died, q{'redefine' alone does not stop an explicitly-prototyped override from colliding} );
    like(
        $stderr,
        qr/Prototype mismatch/,
        'the collision is the same "Prototype mismatch" warning GitHub run 35292793810 hit'
    );
}

# The trap in the middle: giving the override NO prototype at all does not
# fix it either, once 'redefine' is silenced - a non-local *glob = sub {...}
# assignment onto a slot that already holds a prototyped sub is checked
# against "none" vs whatever the existing prototype is, and that is a
# mismatch too.
{
    my ( $died, $stderr ) = _override_dies(
        q{no warnings 'redefine';},
        '*Fake::Sleeper::sleep = sub { return 0 };',
    );
    ok( $died, q{'redefine' alone still does not stop a bare, unprototyped override from colliding} );
    like(
        $stderr,
        qr/Prototype mismatch/,
        'a bare override still mismatches "(;$) vs none" once only \'redefine\' is silenced'
    );
}

# The actual fix: silence BOTH categories. This is the one combination that
# is genuinely safe regardless of which prototype the existing sub carries.
{
    my ( $died, $stderr ) = _override_dies(
        q{no warnings qw(redefine prototype);},
        '*Fake::Sleeper::sleep = sub { return 0 };',
    );
    ok( !$died, q{silencing both 'redefine' and 'prototype' together never collides} )
        or diag("child process died: $stderr");
}

# And tie the mechanism to the actual fix: neither coverage file may
# reintroduce a non-local RuntimeManager::sleep override that silences
# 'redefine' without also silencing 'prototype'.
for my $file (qw(t/100-runtimemanager-coverage.t t/106-runtimemanager-coverage-2.t)) {
    my $path = _repo_path($file);
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $source = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";

    like(
        $source,
        qr/no \s+ warnings \s+ qw\( \s* redefine \s+ prototype \s* \)/x,
        "$file silences both 'redefine' and 'prototype' before overriding RuntimeManager::sleep"
    );
}

done_testing();

__END__

=head1 NAME

t/203-runtimemanager-sleep-mock-prototype.t - guard against a reintroduced prototype-mismatch on the RuntimeManager::sleep test mock

=head1 PURPOSE

Reproduce, deterministically and independent of the local Perl/Time::HiRes
version, the mechanism behind DD-993's CI failure - a fatal "Prototype
mismatch" warning on C<Developer::Dashboard::RuntimeManager::sleep> - and
assert that the two coverage files which permanently override that sub
(t/100 and t/106) silence the warning category that actually causes it.

=head1 WHY IT EXISTS

C<lib/Developer/Dashboard/RuntimeManager.pm> does
C<use Time::HiRes qw(sleep time);>, so C<RuntimeManager::sleep> is not this
project's own code - it is an alias to L<Time::HiRes>'s own C<sleep>, and it
carries whatever prototype that C<sleep> has on the Perl bundling it. That
prototype is not fixed: it read C<(;$)> on the Perl 5.44 GitHub Actions used
in run 35292793810 (master@e959eac, predating v4.39) and C<(;@)> on the Perl
5.40.1 bundled in this project's own C<developer-dashboard:latest> Docker
image - which is exactly why the bug was genuinely red on CI and would not
reproduce locally: nobody's local Time::HiRes disagreed with the override.

t/100 and t/106 each install their override permanently, at file scope,
inside a C<BEGIN> block, as
C<< *Developer::Dashboard::RuntimeManager::sleep = sub (;@) { return 0 }; >>,
guarded only by C<no warnings 'redefine'>. Perl checks a NON-LOCAL typeglob
assignment for two independent things when the slot it targets already holds
a named sub: whether a sub is being "redefined" at all (the C<redefine>
category), and, separately, whether the new sub's prototype - even the
absence of one - matches the old one (the C<prototype> category).
C<no warnings 'redefine'> only ever suppressed the first. Removing the
override's own explicit C<(;@)> prototype does not fix it either: a bare,
unprototyped C<sub { ... }> assigned the same way still mismatches
C<(;$) vs none> once C<redefine> is silenced, because Perl treats "no
prototype" as its own distinct shape to compare. The genuine fix is
C<no warnings qw(redefine prototype);> - both categories, together - which is
correct on every Perl/Time::HiRes combination regardless of what prototype
the existing sub happens to carry.

This project's CI runs under C<use warnings FATAL => 'all'>, so any one of
these mismatches is a build failure, not a note.

The other RuntimeManager::sleep mocks in this suite (t/09, t/46) were never
affected: they each install their override with C<local *glob = sub {...}>,
scoped to one test block. A C<local> typeglob assignment does not trigger
either warning category at all, on any Perl - but it is also dynamically
scoped, so it is the wrong tool for a file-wide override that must survive
for the whole test file, which is what t/100 and t/106 need.

=head1 WHEN TO USE

It runs in the ordinary suite. Consult it before touching either coverage
file's C<BEGIN> block, or before giving any non-local override of an
imported (not locally-declared) sub an explicit or implicit prototype.

=head1 HOW TO USE

    prove -l t/203-runtimemanager-sleep-mock-prototype.t

The first two assertions demonstrate the trap (both should die); the third
demonstrates the fix (should not die) - failure there means the reproduction
itself broke, which should not happen since it is Perl-version-independent
by construction. A failure on the last two means one of the coverage files
reintroduced the unsafe form.

=head1 WHAT USES IT

Nothing programmatic; it is a standing regression guard run by C<prove -lr t>
and by the coverage gate, for DD-993.

=head1 EXAMPLES

Dies under this project's C<FATAL => 'all'> warnings policy no matter which
of these two forms is used, once only C<redefine> is silenced - because the
new sub's prototype (present or absent) can collide with whatever the sub it
replaces already carries:

    no warnings 'redefine';
    *Some::Package::sleep = sub (;@) { return 0 };   # dies: (;$) vs (;@)

    no warnings 'redefine';
    *Some::Package::sleep = sub { return 0 };        # dies: (;$) vs none

Never dies, on any Perl, because both categories that can fire on a
non-local override are silenced together:

    no warnings qw(redefine prototype);
    *Some::Package::sleep = sub { return 0 };

=cut
