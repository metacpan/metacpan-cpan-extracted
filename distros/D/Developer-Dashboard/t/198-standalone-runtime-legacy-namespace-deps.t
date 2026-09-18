#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp ();

use Developer::Dashboard::Pax::StandaloneRuntime;

# DD-933: two representative op implementations in StandaloneRuntime.pm call
# a helper class (JSON, SeedSync) that CodeUnitCompiler.pm's dependency
# discovery pass can fail to add to a compiled entrypoint's
# compiled_packages, because that helper class is referenced only inside
# OTHER subs whose bodies the compiler substitutes with a runtime op before
# its literal-source dependency walk ever sees the reference - the exact
# shape DD-931 already fixed for EnvAudit. Before the fix these op impls
# call __PAX_RUNTIME_LEGACY_NAMESPACE__::<Class>::<method>, a package alias
# that is never installed outside a real PAX build; this test proves that
# by invoking the real, unmodified `_install_compiled_sub` dispatcher
# directly (no full compile needed - the crash/success is a property of the
# generated closure, not of the build pipeline around it).

subtest 'DD-933: doctor_hook_results op does not depend on the legacy JSON alias' => sub {
    my $pkg = 'DD933::TestPkg::Doctor';
    Developer::Dashboard::Pax::StandaloneRuntime::_install_compiled_sub(
        $pkg,
        { name => 'hook_results', op => 'doctor_hook_results' },
    );
    local $ENV{RESULT} = '{"ok":1}';
    my $result = eval { no strict 'refs'; &{"${pkg}::hook_results"}() };
    my $err = $@;
    ok( !$err, 'DD-933: doctor_hook_results runs without dying on the legacy JSON alias' )
        or diag("died with: $err");
    is_deeply( $result, { ok => 1 }, 'DD-933: JSON was actually decoded (real behaviour, not a swallowed error)' );
};

subtest 'DD-933: internal_cli_stage_managed_helper op does not depend on the legacy SeedSync alias' => sub {
    my $pkg = 'DD933::TestPkg::Helper';
    no strict 'refs';
    *{"${pkg}::content"} = sub { return "same content\n" };
    *{"${pkg}::check"}   = sub { return 1 };
    use strict 'refs';

    Developer::Dashboard::Pax::StandaloneRuntime::_install_compiled_sub(
        $pkg,
        {
            name                   => 'stage',
            op                     => 'internal_cli_stage_managed_helper',
            managed_content_method => "${pkg}::content",
            managed_check_method   => "${pkg}::check",
        },
    );

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $target = "$dir/managed-file";
    open my $fh, '>:raw', $target or die "setup: $!";
    print {$fh} "same content\n";
    close $fh;

    my $result = eval {
        no strict 'refs';
        &{"${pkg}::stage"}( target => $target, name => 'x' );
    };
    my $err = $@;
    ok( !$err, 'DD-933: internal_cli_stage_managed_helper runs without dying on the legacy SeedSync alias' )
        or diag("died with: $err");
    is( $result, 0, 'DD-933: correctly detected identical content via SeedSync::same_content_md5, real behaviour' );
};

done_testing();

__END__

=head1 NAME

t/198-standalone-runtime-legacy-namespace-deps.t

=head1 PURPOSE

Proves that two StandaloneRuntime.pm op implementations (doctor_hook_results,
using JSON; internal_cli_stage_managed_helper, using SeedSync) work when
invoked directly, without depending on the __PAX_RUNTIME_LEGACY_NAMESPACE__
alias mechanism that DD-933 found to be unreliable for classes referenced
only inside a special-cased, substituted sub body elsewhere in the codebase.

=head1 WHY IT EXISTS

DD-931 fixed this exact shape for EnvAudit. DD-933 generalises the finding:
JSON and SeedSync hit the same gap at ~24 call sites in StandaloneRuntime.pm.
Before the fix, both subtests here die with "Undefined subroutine
&__PAX_RUNTIME_LEGACY_NAMESPACE__::<Class>::<method>" because nothing in a
bare `prove` process ever installs that alias glob (only a real PAX build's
compiled_packages handling does, and even then only when the class has some
OTHER literal-source reference in that entrypoint's closure). After the fix,
both ops `require` their real class directly and call it by its real name,
so they work in any process, matching DD-931's already-shipped convention.

=head1 WHEN TO USE

Run as part of the full suite (`prove -lr t`) or directly:
C<PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/198-standalone-runtime-legacy-namespace-deps.t>.

=head1 HOW TO USE

No setup needed beyond the standard PERL5LIB preamble - the test installs
its own throwaway packages and exercises the real, unmodified
C<_install_compiled_sub> dispatcher from StandaloneRuntime.pm directly.

=head1 WHAT USES IT

Verifies lib/Developer/Dashboard/Pax/StandaloneRuntime.pm's
doctor_hook_results and internal_cli_stage_managed_helper op implementations.

=head1 EXAMPLES

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/198-standalone-runtime-legacy-namespace-deps.t

=cut
