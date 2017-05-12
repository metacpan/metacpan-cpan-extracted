use strict;
use warnings;
use Test::More;

BEGIN { 
        if ($ENV{skiptests}) { 
          plan skip_all => "$ENV{skiptests}"
	} else {
	  plan tests => 20
	}
	use_ok('Geo::PostalCode');
      };

use constant DIR => 'polevault';

sub closestpc
{
  my($gp,$pc,$rad)=@_;

  my $zpi = $gp->lookup_postal_code(postal_code => $pc)
      or return undef;
  my $r = $gp->nearby_postal_codes(lat => $zpi->{lat}, lon => $zpi->{lon}, distance => $rad)
      or return undef;

  # Sort to guarantee order
  return join(",",sort @$r);
}

my $gp = Geo::PostalCode->new(db_dir => 'blib/tests/'.DIR,
                              cachesize => 'max', # not necessary, just to test
	)
    or die "Couldn't create Geo::PostalCode object: $!\n";

is(closestpc($gp,'00000',0),'00000');
is(closestpc($gp,'00000',70),'00000,11111,22222');
is(closestpc($gp,'00000',3107),'00000,11111,22222');
is(closestpc($gp,'00000',3108),'00000,11111,22222,55555,66666');
is(closestpc($gp,'00000',6150),'00000,11111,22222,33333,55555,66666');
is(closestpc($gp,'11111',70),'00000,11111,22222');
is(closestpc($gp,'22222',70),'00000,11111,22222');
is(closestpc($gp,'33333',139),'33333,44444');
is(closestpc($gp,'44444',139),'33333,44444');
is(closestpc($gp,'55555',98),'55555,66666');
is(closestpc($gp,'66666',98),'55555,66666');
is(closestpc($gp,'77777',98),'77777,88888');
is(closestpc($gp,'88888',98),'77777,88888');
is(closestpc($gp,'99999',0),'99999');
is(closestpc($gp,'99999',3107),'99999');
is(closestpc($gp,'99999',3109),'77777,88888,99999');
is(closestpc($gp,'99999',6150),'44444,77777,88888,99999');
is(closestpc($gp,'99999',10000),'33333,44444,55555,66666,77777,88888,99999');
is(closestpc($gp,'99999',1000000),'00000,11111,22222,33333,44444,55555,66666,77777,88888,99999');

