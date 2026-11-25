use strict;
use warnings;

use File::Spec;
use Test::More;

my $source = File::Spec->catfile( 'native', 'system_menu_helper_linux.c' );
open my $handle, '<', $source
  or die "Unable to read Linux system-menu helper '$source': $!";
my $contents = do { local $/; <$handle> };
close $handle
  or die "Unable to close Linux system-menu helper '$source': $!";

ok(
    $contents =~ m{#include\s*<libayatana-appindicator/app-indicator\.h>},
    'Linux helper uses the Ayatana AppIndicator API',
);
ok( $contents =~ /root->indicator\s*=\s*APP_INDICATOR\s*\(/,
    'Linux helper creates a native status-menu indicator' );
ok( $contents =~ /\bapp_indicator_set_status\s*\(/,
    'Linux helper explicitly activates and deactivates its indicator' );
ok( $contents =~ /\bapp_indicator_set_menu\s*\(/,
    'Linux helper attaches its menu to the native indicator' );
ok( $contents =~ /g_object_new\s*\(\s*APP_INDICATOR_TYPE/,
    'Linux helper constructs Ayatana without its deprecated convenience constructor' );
ok( $contents !~ /\bapp_indicator_new(?:_with_path)?\s*\(/,
    'Linux helper does not call deprecated Ayatana constructors' );
ok( $contents !~ /\bGtkStatusIcon\b|\bgtk_status_icon_\w+\s*\(/,
    'Linux helper does not use deprecated GtkStatusIcon APIs' );
ok( $contents !~ /\bgtk_menu_popup\s*\(/,
    'Linux helper does not use deprecated gtk_menu_popup' );

my $makefile_source = File::Spec->catfile( 'Makefile.PL' );
open my $makefile_handle, '<', $makefile_source
  or die "Unable to read build configuration '$makefile_source': $!";
my $makefile_contents = do { local $/; <$makefile_handle> };
close $makefile_handle
  or die "Unable to close build configuration '$makefile_source': $!";
ok(
    $makefile_contents =~ /ayatana-appindicator3-0\.1/,
    'Linux helper build obtains Ayatana compiler and linker flags through pkg-config',
);
ok(
    $makefile_contents =~ /-Werror=deprecated-declarations/,
    'Linux helper build treats deprecated API compiler diagnostics as errors',
);

done_testing;

__END__

=head1 NAME

t/243-system-menu-linux-indicator-api.t - Linux native indicator API contract

=head1 PURPOSE

Checks that the Linux system-menu helper uses Ayatana AppIndicator for its
status-menu lifecycle and no longer calls the deprecated GtkStatusIcon or
C<gtk_menu_popup> APIs.

=head1 WHY IT EXISTS

GTK3 marks GtkStatusIcon and gtk_menu_popup deprecated, producing compiler
warnings during helper builds. A supported indicator API avoids relying on
those deprecated calls while retaining a native desktop status menu.

=head1 WHEN TO USE

Run this test when changing the Linux native helper or its build dependencies.
It is a source contract and complements compilation and runtime checks; it does
not claim that a desktop shell visibly displayed the indicator.

=head1 HOW TO USE

Run inside the dev Docker service from the CODE directory:

  d2 docker compose exec dev prove -lv t/243-system-menu-linux-indicator-api.t

=head1 WHAT USES IT

The distribution test suite runs this contract alongside System::Menu
configuration, worker lifecycle, and XS bundle tests. The Linux helper is
compiled and launched by the Dashboard System::Menu adapter.

=head1 EXAMPLES

Run the focused source contract:

  prove -lv t/243-system-menu-linux-indicator-api.t

Run the source contract together with native bundle checks:

  prove -Iblib/lib -Iblib/arch -Ilib -lv t/242-system-menu-bundle.t t/243-system-menu-linux-indicator-api.t

=cut
