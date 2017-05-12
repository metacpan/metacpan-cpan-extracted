#!/usr/bin/perl -w

#use strict;
use lib '.';
use MyBot;
use Data::Dumper;
use Carp;
use Games::EternalLands::Constants qw(:Debug :ActorTypes);

our ($PORT, $SERVER, $ADMINS, $OWNER, $USER, $PASS, $ELDIR, $SLEEP);

my $ok = do 'config.pl';
($ok) || die "Could not 'do' config.pl";

defined($USER) || die "USER must be set";
defined($PASS) || die "PASS must be set";

my $bot = MyBot->new(
    -server=>$SERVER, -port=>$PORT,
    -elDir=>'/usr/local/games/el/',
    -owner=> $OWNER,
    -admins=>$ADMINS, -msgInterval=>15,
    -sellingFile=>'selling.yaml',
    -buyingFile=>'buying.yaml',
    -knowledgeFile=>'knowledge.yaml',
    -helpFile=>'help.txt',-adminhelpFile=>'adminhelp.txt',
    -debug=>$DEBUG_TEXT,
#    -debug=>$DEBUG_TYPES,
#    -debug=>$DEBUG_PATH,
#    -debug=>$DEBUG_PACKETS,
);

$bot->{'canTrade'} = 0;

my %isFood =(
    'cooked meat' => 25,
    'fruits' => 20,
    'vegetables' => 15,
    'bread' => 10,
);

sub decide
{
    my $bot = shift;
    my @goals;

    my ($map,$x,$y) = $bot->myLocation();

    my @carry  = $bot->getStat('carry');
    my @mp     = $bot->getStat('mp');
    my $veg    = $bot->qtyOnHand('vegetables');
    my $lilacs = $bot->qtyOnHand('lilacs');
    my $gc     = $bot->qtyOnHand('gold coins');
    my $n      = $carry[1]-$carry[0];

    if ($gc > 2000) {
        push(@goals,{goal=>\&MyBot::STO,item=>'gold coins',qty=>$gc,name=>'Molgor'});
    }
    elsif ($n <= 12  || $bot->{'nCarry'} >=25) {
        if ($lilacs > 0) {
            push(@goals,{goal=>\&MyBot::SELL,name=>'Lavinia',item=>'lilacs',qty=>$lilacs});
        }
    }
    elsif (($mp[0] > 25) && ($veg < 5)) {
        my @veg = $bot->findHarvest('map5nf','vegetables');
        push(@goals, {goal=>\&MyBot::HARVEST,map=>'map5nf',id=>$veg[0]->{'id'},name=>'vegetables',qty=>15});
    }
    elsif ($mp[0] > 25) {
        $lilacs = int(($n+$lilacs-10)/2)*2;
        push(@goals, {goal=>\&MyBot::HARVEST,map=>'map5nf',id=>518,name=>'lilacs',qty=>$lilacs});
    }
    else {
        @goals = ({goal=>\&MyBot::SLEEP,seconds=>10});
    }
    return @goals;
}

my @Goals = ();

sub main
{
    while(1) {
        $bot->connect();
        if ($bot->{'connected'}) {
            $bot->login($USER,$PASS) || die "failed to log in !";
            my ($type,$len,$packet);

            $bot->eatThese('bread','vegetables','fruits');
            while($bot->{'loggedIn'}) {
                ($type,$len,$packet) = $bot->NextPacket();
                my $ret              = $bot->Dispatch($type,$len,$packet);
                my ($map,$x,$y)      = $bot->myLocation();

                (defined($x) and defined($y)) || next;
                $bot->invIsComplete()         || next;

                if ($bot->{'specialDay'} =~ m/Acid Rain Day/i) {
                    $bot->unEquipAll();
                }

                if ($#Goals == -1) {
                    @Goals = decide($bot);
                }

                if (my $g = $Goals[0]) {
                    my $done = MyBot::doGoal($bot,$g,0);
                    print STDERR MyBot::goalDesc($g,0);
                    if (defined($done)) {
                        shift(@Goals);
                    }
                }
            }
            $bot->disconnect();
        }
        sleep $SLEEP;
        $SLEEP = ($SLEEP < 30*60) ? $SLEEP * 2 : $SLEEP;
    }
}

main();
