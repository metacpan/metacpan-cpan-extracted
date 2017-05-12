#!perl -T

use Test::More tests => 1;

use Mail::SNCF::Text;

my @lines = <DATA>;
my $output = join("", @lines);

my $file = "t/sncf";
my $sncf = Mail::SNCF::Text->parse($file);

is($sncf->as_string, $output, "Text output works");

__DATA__
* 5 jan 2009 : MASSY TGV -> RENNES
  Départ :  7h47
  Arrivée :  9h49

* 9 jan 2009 : RENNES -> MASSY TGV
  Départ : 14h35
  Arrivée : 16h47

* 12 jan 2009 : PARIS MONTPARNASSE 1 ET 2 -> RENNES
  Départ : 10h05
  Arrivée : 12h08

* 12 jan 2009 : RENNES -> MASSY TGV
  Départ : 18h39
  Arrivée : 20h48

* 14 jan 2009 : PARIS MONTPARNASSE 1 ET 2 -> RENNES
  Départ : 10h05
  Arrivée : 12h08

* 15 jan 2009 : RENNES -> MASSY TGV
  Départ : 18h39
  Arrivée : 20h48

* 23 jan 2009 : MASSY TGV -> RENNES
  Départ :  7h47
  Arrivée :  9h49

* 23 jan 2009 : RENNES -> MASSY TGV
  Départ : 19h09
  Arrivée : 21h18

* 2 f�v 2009 : MASSY TGV -> RENNES
  Départ :  7h47
  Arrivée :  9h49

* 11 f�v 2009 : PARIS GARE DE LYON -> MARSEILLE ST CHARLES
  Départ : 16h16
  Arrivée : 19h22

* 13 f�v 2009 : ST RAPHAEL VALESCURE -> LYON PART DIEU
  Départ : 14h22
  Arrivée : 17h50

* 6 f�v 2009 : RENNES -> MASSY TGV
  Départ : 17h10
  Arrivée : 19h22

* 9 f�v 2009 : PARIS MONTPARNASSE 1 ET 2 -> RENNES
  Départ : 10h05
  Arrivée : 12h08

* 13 f�v 2009 : RENNES -> LYON PART DIEU
  Départ : 14h14
  Arrivée : 18h31

* 16 f�v 2009 : LYON PART DIEU -> MASSY PALAISEAU
  Départ : 17h26
  Arrivée : 19h35

* 17 f�v 2009 : MASSY TGV -> RENNES
  Départ :  7h47
  Arrivée :  9h49

* 20 f�v 2009 : RENNES -> MASSY TGV
  Départ : 17h10
  Arrivée : 19h22

* 23 f�v 2009 : PARIS MONTPARNASSE 1 ET 2 -> RENNES
  Départ : 10h05
  Arrivée : 12h08

* 27 f�v 2009 : RENNES -> MASSY TGV
  Départ : 17h10
  Arrivée : 19h22

* 2 mar 2009 : PARIS MONTPARNASSE 1 ET 2 -> RENNES
  Départ : 10h05
  Arrivée : 12h08

