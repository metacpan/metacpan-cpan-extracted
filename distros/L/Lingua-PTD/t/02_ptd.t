# -*- cperl -*-
use Test::More tests => 22 + 5*32;

use utf8;
use Lingua::PTD;

my $ptd = Lingua::PTD->new("t/02_ptd.dmp");

isa_ok $ptd => "Lingua::PTD";
isa_ok $ptd => "Lingua::PTD::Dumper";

# save it before messing with its contents
$ptd->saveAs(dmp    => "t/_out.dmp");
$ptd->saveAs(bz2    => "t/_out.dmp.bz2");
$ptd->saveAs(xz     => "t/_out.dmp.xz");
$ptd->saveAs(sqlite => "t/_out.sqlite");


# test original PTD
test_contents($ptd, "dmp");

# test dumped PTD
ok -f "t/_out.dmp";

my $optd = Lingua::PTD->new("t/_out.dmp");

isa_ok $optd => "Lingua::PTD";
isa_ok $optd => "Lingua::PTD::Dumper";

test_contents($optd, "dumpped dmp");
unlink "t/_out.dmp";

# test sqlite PTD
ok -f "t/_out.sqlite";

my $sptd = Lingua::PTD->new("t/_out.sqlite");

isa_ok $sptd => "Lingua::PTD";
isa_ok $sptd => "Lingua::PTD::SQLite";

test_contents($sptd, "sqlite");
unlink "t/_out.sqlite";

# test dumped and bzipped PTD
ok -f "t/_out.dmp.bz2";

my $bzptd = Lingua::PTD->new("t/_out.dmp.bz2");

isa_ok $bzptd => "Lingua::PTD";
isa_ok $bzptd => "Lingua::PTD::BzDmp";

test_contents($bzptd, "bzipped ptd");
unlink "t/_out.dmp.bz2";

# test dumped and xz PTD
ok -f "t/_out.dmp.xz";

my $xzptd = Lingua::PTD->new("t/_out.dmp.xz");

isa_ok $xzptd => "Lingua::PTD";
isa_ok $xzptd => "Lingua::PTD::XzDmp";

test_contents($xzptd, "xzipped ptd");
unlink "t/_out.dmp.xz";


## Reset things...
my $ptd1 = Lingua::PTD->new("t/02_ptd.dmp");
$ptd1->saveAs( sqlite => "t/02.sqlite");

my $ptd2 = Lingua::PTD->new("t/02.sqlite");

# Intersect with itself
$ptd2->intersect($ptd1);
is $ptd2->count("casa") => 100, "Intersect with itself maintains count of word";
is $ptd2->size          => 250, "Intersect with itself maintains number of counts";

$ptd2->add($ptd1);
# adding duplicates occurrences
is $ptd2->count("casa") => 200;
is $ptd2->size          => 500;

# adding with itself, maintains probabilities
is $ptd2->prob("casa","home")  => .25;
is $ptd2->prob("casa","house") => .25;

$ptd1->subtractDomain("gato");
is_deeply [$ptd1->words] => [qw.casa.];

$ptd1->add($ptd2);
is $ptd1->size => 600;
is $ptd1->prob("casa" => "house") => .25;
is $ptd2->prob("casa" => "house") => .25;

unlink "t/02.sqlite";


### ----------- lowercasing
$ptd1 = Lingua::PTD->new("t/02_casedptd.dmp");
isa_ok $ptd1 => "Lingua::PTD"; # loaded OK

$ptd1->lowercase;
isa_ok $ptd1,"Lingua::PTD"; # still a PTD

is $ptd1->prob("casa" => "house") => 0.5, "house + HOUSE";
is $ptd1->prob("casa" => "home")  => 0.5, "home + hoMe";

is $ptd1->count("coração") => 150, "coração + CORAÇÃO";

ok ($ptd1->prob("coração" => "heart") > 0.8332);
ok ($ptd1->prob("coração" => "heart") < 0.8334);
is $ptd1->count("camelo") => 2, "lc(CAMELO)";

sub test_contents {
    my ($ptd, $type) = @_;

    ok( grep {$_ eq "casa"} $ptd->words, "casa is in the dictionary" );
    ok(!(grep {$_ eq "albergue"} $ptd->words), "albergue not in the dictionary");

    is($ptd->count("casa"),     100, "Count casa = 100");
    is($ptd->count("albergue"), 0,   "Count albergue = 0");

    is($ptd->prob("casa","home"),  .25, "P(T(casa)=home)=.25");
    is($ptd->prob("casa","house"), .25, "P(T(casa)=house)=.25");
    is($ptd->prob("casa","homens"),  0, "P(T(casa)=homens)=.0");

    is_deeply([sort $ptd->trans("casa")], [qw.home house.], "T(casa)=[home,house]");
    is_deeply([sort $ptd->words],         [qw.casa gato.],  "Words=[casa,gato]");


    my $stats = $ptd->stats;
    is($stats->{size},  $ptd->size, "Size ok");
    is($stats->{occTotal}, $stats->{size}, "Occ total ok");
    is($stats->{count}, $ptd->count, "count ok");
    is($stats->{avgOcc}, 125, "avgOcc ok");
    is($stats->{occMin}, 100, "occMin ok");
    is($stats->{occMax}, 150, "occMax ok");
    is($stats->{occMinWord}, 'casa', "minword ok");
    is($stats->{occMaxWord}, 'gato', "maxword ok");
    is($stats->{probMax}, 1, "probmax ok");
    is($stats->{probMin}, 0.25, "probmin ok");
    is($stats->{avgBestTrans}, 1.25/2); # cross fingers

    ## Recalculate probabilities
    $ptd->reprob;
    is($ptd->count("casa"),100, "Count(casa) = 100 (R)"); # count maintains
    is($ptd->prob("casa","home"), .5);
    is($ptd->prob("casa","house"), .5);
    is($ptd->prob("casa","homens"), 0);

    is($ptd->size, 250, "DicSize = 250 ($type)");

    $ptd->subtractDomain( ['gato'] );
    is_deeply([$ptd->words],['casa']);
    is($ptd->size, 100);
    is($ptd->count, 1);

    ##
    $ptd->downtr( sub {
                      my ($w,$c,%t) = @_;
                      $c = 0;
                      toentry($w,$c,%t);
                  }, filter => 1);

    is($ptd->count("casa"),0);

    $ptd->downtr( sub { return undef}, filter => 1);
    is_deeply([$ptd->words],[]);


}
