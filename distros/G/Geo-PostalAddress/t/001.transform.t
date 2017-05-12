# $Id: 001.transform.t,v 1.1.1.1 2005/04/18 09:12:10 michel Exp $

use strict;
use Test;

# Test Geo::PostalAddress object creation and address transformation

use Geo::PostalAddress;
use Locale::Country;

my @test_data = (
  # Default data
  ['AF', 'Ministry of Communications', ['Mohammed Jan Khan Watt', 'KABUL'] ],
  # District name, no city or postcode
  ['AL', 'Mr. Artur Mema', ['Fshati Zejmen', 'LEZHE'] ],
  # Postcode and prefix left of city, no district
  ['DZ', 'M. Said Mohamed', ['2, rue de l\'Indépendance', '16027 ALGIERS'] ],
  # Variable length postcode and prefix left of city, no district
  ['CL', 'Señor Juan Pérez', ['El Juncal 050', '872-0019 QUILICURA'] ],
  # Postcode right of city, no district
  ['BM', 'Mr. & Mrs Householder', ['Fiddlewood Cottage', '9 Leafy Lane',
   'SMITH\'S FL 07' ] ],
  # Postcode left of city, district name below
  ['CV', 'Luis Felipe Ramos', ['Rua 5 de Julho 138/Platô', 'C.P. 38',
    '7600 PRAIA', 'SANTIAGO'] ],
  # Postcode right of city, district name below
  ['NG', 'Mr. Ben Tal', ['Tal\'s Compound', 'GHOH 931104', 'PLATEAU STATE'] ],
  # City and district name each on a line by itself, no postcode
  ['IE', 'Mr B Smyth', ['20 Rock Road', 'Blackrock', 'CO DUBLIN'] ],
  # City, district code/name, postcode in some order all on same line
  ['AU', 'MR. RON JAMES', ['4360 DUKES RD', 'KALGOORLIE WA 6430'] ],
  # City and district code+postfix on 1 line, then postcode alone below
  ['BR', 'Sr. Luis Carvalho', ['Boulevard das Flores 255', 'SALVADOR-BA',
   '40301-110'] ],
  # Postcode alone, then city and district below
  ['NI', 'Sr. Juan Manuel Nurinda',
   ['Del Hotel Granada 1c. arriba 75 vrs. alsur.', 'Reparto Santa Isabel',
   '050-008-4', 'GRANADA, GRANADA'] ],
  # City and district name on same line, no postcode
  ['CO', 'SOCIEDAD DE ESCRITORES COLOMBIANOS', ['Av. 15 no 80-13 oficina 702',
   'ARACATACA-MAGDALENA'] ],
  # District name and postal code each on a line by itself
  ['EG', 'Mr. Mohamed Ahmed Mahmoud', ['30, Rue Ahmed Orabi',
   'Al-Mohandessine', 'GIZA', '12411'] ],
  # City, name of district, and postcode each on a line by itself
  ['UA', 'Melnik Ivan Petrovitch', ['Vul. Lisova, 2, kv.3',
   's. Ivanovka, Semenivsky r-n,', 'Tchernigivska obl.', '15432'] ],
  # Postcode on a line by itself, then city
  ['EC', 'Señor Gonzalo Oleas Zambrano',
   ['Calle Leonidas plaze 299 y 12 de Octubre', 'P0102B', 'QUITO'] ],
  # Postcode and prefix on a line by itself under city
  ['IQ', 'Mr Anmed Tarek', ['10 Qahwa Share\'a', 'AL ASMAEE, AL BASRAH',
   '61002'] ],
  # City on first line of address, postcode by itself on last line
  ['HU', 'MÁTÉ JÓZSEF', ['BUDAPEST', 'VIRÁG TÉR 3. IV. 61', '1037'] ],
  # No city (or rather, only one)
  ['SG', 'Ms. Tan Bee Soo', ['16 Sandilands Road', 'SINGAPORE 546080'] ],
  # District name, postcode (no city?)
  ['TH', 'Mr. Phanuwat Weerakul', ['104/5 Moo 11',
   'Wutthakad Road, Bangkhunthien', 'Chomthong', 'BANGKOK 10150'] ],
  # City, no postcode or district
  ['BB', 'General Post Office', ['Cheapside', 'BRIDGETOWN'] ],
);

plan tests => 7*@test_data + 1;

ok(!defined(Geo::PostalAddress->new('ZZ'))); # Doesn't exist.

foreach my $test (@test_data) {
  my ($ccode, $name, $addr) = @$test;
  my $pa = Geo::PostalAddress->new($ccode);

  ok(defined($pa), 1, "$ccode instantiation (base class)");
  ok(UNIVERSAL::isa($pa, 'Geo::PostalAddress'), 1,
     "$ccode base class membership");

  my $d = $pa->display($addr);
  ok(defined($d) && UNIVERSAL::isa($d, 'HASH')
      && (grep(!defined($_), values(%$d)) == 0), 1,
    "$ccode display return type/fields");

  my $s = $pa->storage($d);
  if (ref($s)) {
    ok(UNIVERSAL::isa($s, 'ARRAY'), 1, "$ccode storage return type");
  } elsif (defined($s)) {
    ok(1, 0, "$ccode storage return type: failed: $s");
  } else {
    ok(1, 0, "$ccode storage return type: undef???");
  }

  # Should only be skipped if previous test fails.
  skip(!UNIVERSAL::isa($s, 'ARRAY'),
       ($#$s == $#$addr) && (grep($s->[$_] ne $addr->[$_], 0..$#$s) == 0),
       1, "$ccode display and storage discrepancy");

  my $l = $pa->label("AX", $name, $addr);
  ok(UNIVERSAL::isa($l, 'ARRAY'), 1, "$ccode label return type");

  # Check that label only reordered the lines and maybe added the country.
  my %h = ();
  $h{$_} = exists($h{$_}) ? $h{$_} + 1 : 1 foreach (@$l);
  $h{$_} = exists($h{$_}) ? $h{$_} - 1 : -1 foreach ($name, @$addr);
  exists($h{$_}) && --$h{$_} foreach (code2country($ccode));
  ok(scalar(grep($_, values(%h))), 0, "$ccode label/storage consistency");
}
