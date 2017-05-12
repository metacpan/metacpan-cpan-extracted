use Test::More (tests => 6);

use_ok "Devel::InheritNamespace";

my $din = Devel::InheritNamespace->new(
    except => qr/(?:Functions|VMS|Win32)$/,
);

my $modules = $din->all_modules( 'MyApp' => 'File::Spec' );
ok( $modules->{'MyApp::Cygwin'}->{is_virtual} );
ok( $modules->{'MyApp::Epoc'}->{is_virtual} );
ok( $modules->{'MyApp::Mac'}->{is_virtual} );
ok( $modules->{'MyApp::OS2'}->{is_virtual} );
ok( $modules->{'MyApp::Unix'}->{is_virtual} );