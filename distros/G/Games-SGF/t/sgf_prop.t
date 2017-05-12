use Test::More tests => 15;                      # last test to print
use Games::SGF;
#use Games::SGF::Go;
use Data::Dumper;

my $sgf = new Games::SGF(Fatal => 0,Warn => 0,Debug => 0);
my( $pt, $st, $mv );

ok( $pt = $sgf->point("aa"), "Make point");
ok( $sgf->isPoint($pt), "Check point");
ok( $sgf->point($pt) eq "aa", "Invert point");

ok( $mv = $sgf->move("aa"), "Make move");
ok( $sgf->isMove($mv), "Check move");
ok( $sgf->move($mv) eq "aa", "Invert move");

ok( $mv = $sgf->stone("aa"), "Make stone");
ok( $sgf->isStone($mv), "Check stone");
ok( $sgf->stone($mv) eq "aa", "Invert stone");

# add some tags

ok($sgf->addTag('TB', $sgf->T_NONE, $sgf->V_POINT,
            $sgf->VF_EMPTY | $sgf->VF_LIST | $sgf->VF_OPT_COMPOSE), "add tag TB");
ok($sgf->addTag('TW', $sgf->T_NONE, $sgf->V_POINT,
            $sgf->VF_EMPTY | $sgf->VF_LIST | $sgf->VF_OPT_COMPOSE), "add tag TW");
ok($sgf->addTag('HA', $sgf->T_GAME_INFO, $sgf->V_NUMBER), "add tag HA");


# readd some tags
ok(not ($sgf->addTag('TB', $sgf->T_NONE, $sgf->V_POINT,
            $sgf->VF_EMPTY | $sgf->VF_LIST | $sgf->VF_OPT_COMPOSE)), "readding tag TB");
ok(not ($sgf->addTag('TW', $sgf->T_NONE, $sgf->V_POINT,
            $sgf->VF_EMPTY | $sgf->VF_LIST | $sgf->VF_OPT_COMPOSE)), "readding tag TW");
ok(not ($sgf->addTag('HA', $sgf->T_GAME_INFO, $sgf->V_NUMBER)), "readding tag HA");

# redefine some tag

# redefine non existent tag

#$sgf = new Games::SGF::Go(Warn => 0, Debug => 0);
#( $pt, $st, $mv ) = ();
#my @cords;

#ok( $pt = $sgf->point(27,12), "Make Go point");
#ok( $sgf->isPoint($pt), "Check Go point");
#@cords = $sgf->point($pt);
#ok( ($cords[0] == 27 and $cords[1] == 12), "Invert Go point");

#ok( $mv = $sgf->move(27,12), "Make Go move");
#ok( $sgf->isMove($mv), "Check Go move");
#@cords = $sgf->move($mv);
#ok( ($cords[0] == 27 and $cords[1] == 12), "Invert Go move");

