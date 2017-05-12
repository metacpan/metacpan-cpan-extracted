
  use Devel::Hook ();

  INIT {
    print "INIT #2\n";
  }

  BEGIN {
    Devel::Hook->push_INIT_hook( sub { print "INIT #3 (hook)\n" } );
    Devel::Hook->unshift_INIT_hook( sub { print "INIT #1 (hook)\n" } );
  }

  print "RUNTIME\n";

__END__

Output will be:

  INIT #1 (hook)
  INIT #2
  INIT #3 (hook)
  RUNTIME

