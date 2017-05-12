use strict;
use warnings;

BEGIN {
  if ($ENV{DEVEL_GLOBALDESTRUCTION_PP_TEST}) {
    unshift @INC, sub {
      die 'no XS' if $_[1] eq 'Devel/GlobalDestruction/XS.pm';
    };
  }
}

{
  package Test::Scope::Guard;
  sub new { my ($class, $code) = @_; bless [$code], $class; }
  sub DESTROY { my $self = shift; $self->[0]->() }
}

sub ok ($$) {
  print "not " if !$_[0];
  print "ok";
  print " - $_[1]" if defined $_[1];
  print "\n";
  !!$_[0]
}

BEGIN {
  require B;
  B::minus_c();

  print "1..3\n";
  ok( $^C, "Test properly running under minus-c" );
}

use Devel::GlobalDestruction;

BEGIN {
    ok !in_global_destruction(), "BEGIN is not GD with -c";
}

our $foo;
BEGIN {
  $foo = Test::Scope::Guard->new( sub {
    ok( in_global_destruction(), "Final cleanup object destruction properly in GD" ) or do {
      require POSIX;
      POSIX::_exit(1);
    };
  });
}
