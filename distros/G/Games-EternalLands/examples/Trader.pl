#!/usr/bin/perl -w

use strict;
use lib '.';

use MyBot;
use Games::EternalLands::Constants qw(%ClientCommandsByID $DEBUG_PACKETS $DEBUG_TYPES);

# A simple Trade Bot, it buys and sells items as
# defined by the -buyingFile and -sellingFIe
# options - both these files are in yaml format

our ($PORT, $SERVER, $ADMINS, $OWNER, $USER, $PASS, $ELDIR, $SLEEP);
require 'config.pl';

my $bot = Games::EternalLands::Bot->new(
              -server=>$SERVER, -port=>$PORT,
              -elDir=>'/usr/local/games/el/',
              -owner=> $OWNER,
              -admins=>$ADMINS, -msgInterval=>15,
              -sellingFile=>'selling.yaml',
              -buyingFile=>'buying.yaml',
              -helpFile=>'help.txt',-adminHelpFile=>'adminhelp.txt',
          );

defined($USER) || die "USER must be set";
defined($PASS) || die "PASS must be set";

while(1) {
    $bot->connect();
    if ($bot->{'connected'}) {
        $bot->login($USER,$PASS) || die "failed to log in !";
        $bot->Say("#jc 3");
        while($bot->{'loggedIn'}) {
            my ($type,$len,$packet) = $bot->NextPacket();
            if (defined($type)) {
                $bot->Dispatch($type,$len,$packet);
            }
        }
        $bot->disconnect();
    }
    sleep $SLEEP;
    if ($SLEEP < 30*60) {
        $SLEEP *= 2;
    }
}

