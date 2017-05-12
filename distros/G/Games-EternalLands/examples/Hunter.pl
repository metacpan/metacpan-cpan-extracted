#!/usr/bin/perl -w

use strict;
use lib '.';
use MyBot;
use Games::EternalLands::Constants qw(:Debug :ActorTypes);

our ($PORT, $SERVER, $ADMINS, $OWNER, $USER, $PASS, $ELDIR, $SLEEP);
require 'config.pl';

defined($USER) || die "USER must be set";
defined($PASS) || die "PASS must be set";

# If you want to run this bot, define SERVER and PORT variable to be
# value for the Test Server and comment out the line below
#die "You MUST NOT run this bot on the real server, you will be banned";

my $bot = Games::EternalLands::Bot->new(
              -server=>$SERVER, -port=>$PORT,
              -elDir=>$ELDIR,
              -owner=> $OWNER, -admins=>$ADMINS,
              -knowledgeFile=>'knowledge.yaml',
              -helpFile=>'help.txt',-adminhelpFile=>'adminhelp.txt',
#              -debug=>$DEBUG_TEXT,
#              -debug=>$DEBUG_TYPES,
#              -debug=>$DEBUG_PATH,
#              -debug=>$DEBUG_PACKETS,
          );

$bot->{'canTrade'} = 0;

my %isFood =(
    'cooked meat' => 25,
    'fruits' => 20,
    'vegetables' => 15,
    'bread' => 10,
);

my %huntable = (
    $brown_rabbit => 10,
    $beaver => 15,
    $brownie => 20,
    $wood_sprite => 25,
    $deer => 30,
);

sub decide
{
    my $bot = shift;

    my ($map,$x,$y) = $bot->myLocation();

    my @carry  = $bot->getStat('carry');
    my @mp     = $bot->getStat('mp');
    my $meat   = $bot->qtyOnHand('raw meat');
    my $fur    = $bot->qtyOnHand('brown rabbit fur');
    my $gc     = $bot->qtyOnHand('gold coins');
    my $bread  = $bot->qtyOnHand('bread');
    my $n      = $carry[1]-$carry[0];
    my @goals;

    if ($bread < 3) {
        push(@goals, {goal=>\&MyBot::GETBREAD,qty=>10});
    }
    elsif ($gc > 500) {
        push(@goals,{goal=>\&MyBot::STO,item=>'gold coins',qty=>$gc,name=>'Molgor'});
    }
    elsif ($n <= 15  || $bot->{'nCarry'} >=25) {
        foreach my $item (values %{$bot->{'invByPos'}}) {
            my $name = $item->{'name'};
            $isFood{$name} && next;
            ($name =~ m/raw meat/i) && next;
            ($name =~ m/brown rabbit fur/i) && next;
            my $qty = $item->{'quantity'};
            push(@goals,{goal=>\&MyBot::STO,item=>$name,qty=>$qty,name=>'Molgor'});
        }
        if (($meat > 0) || ($fur > 0)) {
            push(@goals,{goal=>\&MyBot::SELL,name=>'Reca',item=>'raw meat',qty=>$meat});
            push(@goals,{goal=>\&MyBot::SELL,name=>'Reca',item=>'brown rabbit fur',qty=>$fur});
        }
    }
    else {
        @goals = ({goal=>\&MyBot::HUNT,map=>'startmap',x=>24,y=>24,huntable=>\%huntable});
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
