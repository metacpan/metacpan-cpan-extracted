use strict;
use warnings;
no warnings 'once';

BEGIN {
  package Test::Scope::Guard;
  sub new { my ($class, $code) = @_; bless [$code], $class; }
  sub DESTROY { my $self = shift; $self->[0]->() }
}

print "1..8\n";

our $had_error;

sub ok ($$) {
  $had_error++, print "not " if !$_[0];
  print "ok";
  print " - $_[1]" if defined $_[1];
  print "\n";
}

END {
  ok( ! Devel::GlobalDestruction::XS::in_global_destruction(), 'Not yet in GD while in END block 2' )
}

ok( eval "use Devel::GlobalDestruction::XS; 1", "use Devel::GlobalDestruction::XS" );

ok( defined prototype \&Devel::GlobalDestruction::XS::in_global_destruction, "defined prototype" );

ok( prototype \&Devel::GlobalDestruction::XS::in_global_destruction eq "", "empty prototype" );

ok( ! Devel::GlobalDestruction::XS::in_global_destruction(), "Runtime is not GD" );

our $sg1 = Test::Scope::Guard->new(sub { ok( Devel::GlobalDestruction::XS::in_global_destruction(), "Final cleanup object destruction properly in GD" ) });

END {
  ok( ! Devel::GlobalDestruction::XS::in_global_destruction(), 'Not yet in GD while in END block 1' )
}

our $sg2 = Test::Scope::Guard->new(sub { ok( ! Devel::GlobalDestruction::XS::in_global_destruction(), "Object destruction in END not considered GD" ) });
END { undef $sg2 }
