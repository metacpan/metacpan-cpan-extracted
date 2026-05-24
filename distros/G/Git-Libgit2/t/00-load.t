use Test2::V0;

use Git::Libgit2 qw( init_lib shutdown_lib version );
use Git::Libgit2::FFI ();
use Git::Libgit2::Error ();

ok( Git::Libgit2::FFI::ffi(), 'FFI singleton boots' );

my $rc = init_lib();
ok( $rc >= 1, "init_lib returned refcount $rc" );

my ( $maj, $min, $rev ) = version();
ok( defined $maj && $maj >= 1, "libgit2 version $maj.$min.$rev (major >= 1)" );

is( scalar version(), "$maj.$min.$rev", 'version() scalar context joins dotted' );

shutdown_lib();

done_testing;
