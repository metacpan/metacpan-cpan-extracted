# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Cloudmade.t'

#########################

use Test;

BEGIN { plan tests => 3 };
use Geo::Cloudmade;

if (exists $ENV{CLOUDMADE_API_KEY}) {
  my $geo = Geo::Cloudmade->new($ENV{CLOUDMADE_API_KEY});

  ok (defined $geo);

  my ($res) = $geo->find("Potsdamer Platz,Berlin,Germany", {results=>5, skip=>0});
  print $res->name.": ".$res->centroid->lat."/".$res->centroid->long, "\n";

  my $str = $res->name.": ".$res->centroid->lat."/".$res->centroid->long;
  $str =~ s/(\.\d{3})\d*/$1/g; # don't compare with more than 3 digits after '.'
  ok ($str eq 'Potsdamer Platz: 52.509/13.376');

  my ($reverse)  = $geo->find_closest('address', [52.4870,13.4248]);
  ok (join (' ', $reverse->properties('addr:housenumber', 'addr:street', 'addr:city')) eq '9 Hermannplatz Berlin');
} else {
  ok (1); ok (1); ok (1); # no key - no tests
}
