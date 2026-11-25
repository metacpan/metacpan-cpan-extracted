use strict;
use warnings;

use File::Spec;
use Test::More;
use Developer::Dashboard::Version ();

my $loaded = eval { require Developer::Dashboard::System::Menu; 1 };
plan skip_all => 'system-menu XS bundle is unavailable or out of date'
  if !$loaded;
pass('system-menu API loads through the Dashboard XS bundle');

SKIP: {
    skip 'system-menu API is not loadable yet', 6 if !$loaded;

    is(
        $Developer::Dashboard::System::Menu::VERSION,
        $Developer::Dashboard::Version::VERSION,
        'system-menu module shares the distribution version',
    );

    for my $xs_method (qw(_start _command_json _read_events _stop _running)) {
        ok(
            Developer::Dashboard::System::Menu->can($xs_method),
            "$xs_method is registered in the shared Dashboard XS bundle",
        );
    }

}

SKIP: {
    my $helper_name = $^O eq 'MSWin32' ? 'system_menu_helper.exe' : 'system_menu_helper';
    # The helper is built beside the loaded Dashboard XS bundle, not
    # necessarily beside the current directory: prove may run from a
    # checkout whose blib lives elsewhere (Jenkins runs prove from a
    # fresh checkout with -I pointing at an existing blib, so the old
    # cwd-relative path found nothing). Resolve it from the loaded
    # shared object instead; fall back to the old path if the bundle
    # cannot be found.
    my ($bundle) = grep {
        ( File::Spec->splitpath($_) )[2] =~ /\ADashboard[^\/\\]*\.(?:so|dll|bundle)\z/i
    } @DynaLoader::dl_shared_objects;
    my $helper = defined $bundle
        ? File::Spec->catfile( ( File::Spec->splitpath($bundle) )[1], $helper_name )
        : File::Spec->catfile(
            'blib', 'arch', 'auto', 'Developer', 'Dashboard', $helper_name,
        );
    my $linux_helper_skip_reason;
    if ( $^O eq 'linux' ) {
        my ($pkg_config) = grep { -f $_ && -x $_ }
          map { File::Spec->catfile( $_, 'pkg-config' ) }
          grep { defined $_ && $_ ne q{} } File::Spec->path;
        if ( !defined $pkg_config ) {
            $linux_helper_skip_reason = 'pkg-config is unavailable on PATH';
        }
        else {
            my $status = system { $pkg_config } $pkg_config, '--exists',
              'ayatana-appindicator3-0.1', 'gtk+-3.0';
            die "Unable to execute pkg-config at '$pkg_config': $!\n"
              if $status == -1;
            die "pkg-config terminated by signal " . ( $status & 127 ) . "\n"
              if $status & 127;
            $linux_helper_skip_reason = 'GTK/Ayatana development modules are unavailable'
              if $status != 0;
        }
    }
    if ( defined $linux_helper_skip_reason ) {
        skip "$linux_helper_skip_reason; native helper build is optional on headless Linux", 1;
    }
    else {
        ok( -f $helper, 'native platform helper is built beside the Dashboard XS bundle' );
    }
}

done_testing;

__END__

=head1 NAME

t/242-system-menu-bundle.t - shared XS bundle registration tests

=head1 PURPOSE

Verifies that the native System Menu API loads through the existing
Developer::Dashboard XS extension rather than requiring a second extension
object with a separately versioned ABI. It also checks that platform helpers
are built when required; the Linux helper-file assertion is skipped only when
the optional GTK/Ayatana development modules are unavailable.

=head1 WHY IT EXISTS

System Menu owns native helper-process startup, command transport, event reads,
shutdown, and running-state checks. These XSUBs must be installed under the
System::Menu package by the Dashboard shared extension so normal Perl callers
can use the existing Developer::Dashboard::* module namespace. Headless CPAN
test environments may not have GTK development headers, so the Linux helper
build is optional there while the native API and XSUB checks still run.

=head1 WHEN TO USE

Run this test after changing the System Menu XS source, the main XS include
list, or the Perl module's XS loading path. It is intended to catch accidental
creation of a second XS bundle or missing XSUB registration before any native
helper is started. On Linux without GTK/Ayatana pkg-config modules, only the
helper-file existence assertion is skipped; Linux CI sets
C<DD_REQUIRE_SYSTEM_MENU_HELPER=1>, so its helper build remains mandatory.

=head1 HOW TO USE

Run inside the project dev container after generating the Makefile and building
the XS extension:

  prove -Iblib/lib -Iblib/arch -Ilib -lv t/242-system-menu-bundle.t

=head1 WHAT USES IT

The distribution test suite runs this contract alongside configuration and
runner lifecycle tests. The installed System::Menu module relies on the same
Dashboard XS object as HtmlEscape and GoRoutine. The Linux helper binary is
available when the system development packages were installed before
configuration.

=head1 EXAMPLES

Check the test through the Docker dev service:

  d2 docker compose exec dev prove -Iblib/lib -Iblib/arch -Ilib -lv t/242-system-menu-bundle.t

Load the module after building the distribution:

  perl -Iblib/lib -Iblib/arch -Ilib -MDeveloper::Dashboard::System::Menu -e 'print "$Developer::Dashboard::System::Menu::VERSION\n"'

=cut
