use Test2::V0;

use Git::Libgit2 qw( init_lib shutdown_lib version );

init_lib();

my ( $maj, $min, $rev ) = version();
ok( defined $maj && $maj >= 1, "libgit2 version $maj.$min.$rev (major >= 1)" );

# Hammer init/shutdown — should not leak or crash.
my $iterations = 5000;
for my $i ( 1 .. $iterations ) {
  my $rc = init_lib();
  # Refcount starts at 1 on first init and increments each subsequent pass.
  ok( $rc >= 1, "init_lib pass $i returned refcount $rc (>= 1)" );
  shutdown_lib();
}

# Final state should be back to zero (or as low as we can given other tests ran first).
my $final_rc = init_lib();
ok( $final_rc >= 1, "init after loop returned refcount $final_rc (>= 1)" );
shutdown_lib();

done_testing;
