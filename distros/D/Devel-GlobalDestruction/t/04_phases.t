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

my $had_error = 0;
END { $? = $had_error }
sub ok ($$) {
  $had_error++, print "not " if !$_[0];
  print "ok";
  print " - $_[1]" if defined $_[1];
  print "\n";
  !!$_[0]
}

use Devel::GlobalDestruction;

sub check_not_global {
  my $phase = shift;
  ok !in_global_destruction(), "$phase is not GD";
  Test::Scope::Guard->new( sub {
    ok( !in_global_destruction(), "DESTROY in $phase still not GD" );
  });
}

BEGIN {
  print "1..10\n";
}

BEGIN { check_not_global('BEGIN') }

BEGIN {
  if (eval 'UNITCHECK {}; 1') {
    eval q[ UNITCHECK { check_not_global('UNITCHECK') }; 1 ]
      or die $@;
  }
  else {
    print "ok # UNITCHECK not supported in perl < 5.10\n" x 2;
  }
}

CHECK { check_not_global('CHECK') }
sub CLONE { check_not_global('CLONE') };
INIT { check_not_global('INIT') }
END { check_not_global('END') }
