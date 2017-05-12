package Games::EternalLands::Client;

use strict;
use Carp qw(carp cluck);
use IO::Socket;
use POSIX;
use YAML;
use Games::EternalLands::Map;
use Data::Dumper;
use Carp;
use Tie::Cache;

our $VERSION = "0.04";

#   use Socket qw(!/^[AP]F_/ !SOMAXCONN !SOL_SOCKET);

# use Module qw(:DEFAULT :T2 !B3 A3);


use Games::EternalLands::Constants qw(:ServerCommands :ClientCommands :Debug :Stats :TypeContainers);

my $MAXBAGS = 200;
my $ITEMS_PER_BAG = 50;

################################################


################################################

sub Log
{
    my $self   = shift;
    my @now    = localtime(time);
    my $nowStr = sprintf("%4d-%02d-%02d %02d:%02d", $now[5]+1900,$now[4],$now[3], $now[2],$now[1]); 

    defined($_[0]) || cluck("Argument to Log() is not defined !");
    print STDERR "[",$nowStr,"] ",$_[0],"\n";
}

sub setDebug
{
    my $self = shift;
    my ($val) = @_;

    $self->{'debug'} = $val;
}

sub myLocation
{
    my $self = shift;
    my $me   = $self->{'me'};

    my $map = $self->crntMap();
    if (wantarray) {
        return defined($me) ? ($map,$me->{'xpos'},$me->{'ypos'}) : (undef,undef,undef);
    }
    else {
        return defined($me) ? [$map,$me->{'xpos'},$me->{'ypos'}] : undef;
    }
}

sub emptyEquipSlot
{
    my $self = shift;
    my ($start) = @_;

    for(my $i=36; $i<44; $i++) {
        if (!defined($self->{'invByPos'}->{$i})) {
            return $i;
        }
    }
    return -1;
}

sub emptyInvSlot
{
    my $self = shift;
    my ($start) = @_;

    for(my $i=0; $i<36; $i++) {
        if (!defined($self->{'invByPos'}->{$i})) {
            return $i;
        }
    }
    return -1;
}

sub moveInvItem
{
    my $self = shift;
    my ($from,$to) = @_;

    if (!defined($self->{'invByPos'}->{$from})) {
        $self->Log("Can't move empty inventory slot $from\n");
        return undef;
    }
    if (defined($self->{'invByPos'}->{$to})) {
        $self->Log("Can't move item to used inventory slot $to\n");
        return undef;
    }
    my $item = $self->{'invByPos'}->{$from}->{'name'} || "unkown";
    $self->Log("Moving $item from slot $from to slot $to");

    $self->send($MOVE_INVENTORY_ITEM,pack('CC',$from,$to));
}

sub equipItem
{
    my $self = shift;
    my ($name,$multi) = @_;

    if (!defined($multi)) {
        foreach my $p (36 .. 43) {
            if (exists $self->{'invByPos'}->{$p}) {
                my $item = $self->{'invByPos'}->{$p}->{'name'};
                ($item =~ m/^$name$/i) && return 1;
            }
        }
    }

    my @pList = ();
    foreach my $p (1 .. 35) {
        if (exists $self->{'invByPos'}->{$p}) {
            my $item = $self->{'invByPos'}->{$p}->{'name'};
            ($item =~ m/^$name$/i) && push(@pList,$p);
        }
    }

    if ($#pList == -1) {
        $self->Log("Do not have a $name to equip");
        return 0;
    }
    my $to = $self->emptyEquipSlot();
    if ($to == -1) {
        $self->Log("No free inventory position to equip $name to");
        return 0;
    }
    $self->moveInvItem($pList[0],$to);
    return 1;
}

sub getPlayerInfo
{
    my $self = shift;
    my ($id) = @_;

    $self->send($GET_PLAYER_INFO,pack('L',$id));
}

sub haveItem
{
    my $self = shift;
    my ($name) = @_;
    my @pList = keys(%{$self->{'invByName'}->{lc($name)}});

    foreach my $p (@pList) {
        defined($p) && return $self->{'invByPos'}->{$p};
    }
    return undef;
}

sub unEquipAll
{
    my $self = shift;

    my @equippedSlots;
    for(my $pos=36; $pos<44; $pos++) {
        if (defined($self->{'invByPos'}->{$pos})) {
            push(@equippedSlots,$pos);
        }
    }
    ($#equippedSlots >= 0) || return 0;

    my $to = 0;
    foreach my $from (@equippedSlots) {
        while(defined($self->{'invByPos'}->{$to})) {
            $to++;
        }
        ($to < 36) || last;
        $self->moveInvItem($from,$to);
    }
    if ($to >= 36) {
        $self->Log("not enough spare slots to un-equip everything");
        return 0;
    }
    return 1;
}

sub unEquipItem
{
    my $self = shift;
    my ($name) = @_;

    my @pList = keys(%{$self->{'invByName'}->{lc($name)}});

    my $from = -1;
    foreach my $p (@pList) {
        ($p >= 36) || next;
        $from = $p;
        last;
    }
    if ($from == -1) {
        return 1;
    }
    my $to = $self->emptyInvSlot();
    if ($to == -1) {
        $self->Log("No free inventory position to un-equip $name to");
        return undef;
    }
    $self->moveInvItem($from,$to);
    return 1;
}

sub sitDown
{
    my $self = shift;

    $self->send($SIT_DOWN,pack('C',1));
}

sub standUp
{
    my $self = shift;

    $self->send($SIT_DOWN,pack('C',0));
}

sub packetAsHex
{
    my $self = shift;
    my ($pkt) = @_;
    my @bytes;

    my $n = length($pkt);
    for(my $i=0; $i<$n; $i++) {
        my $ch = substr($pkt,$i,1);
        push(@bytes,sprintf("%2X", ord($ch)));
    }
    return join(" ",@bytes);
}

sub send
{
    my $self = shift;
    my ($cmd,$data) = @_;

    if ($cmd eq $MOVE_TO or $cmd eq $ATTACK_SOMEONE) {
        if ($self->{'lastMove'}+1 > time()) {
            return;
        }
        $self->{'lastMove'} = time();
    }
    ($self->{'debug'} & $DEBUG_TYPES) && $self->Log("Sending: ".$ServerCommandsByID{$cmd});

    my $len = pack('v',length($data)+1);
    my $buf = $cmd.$len.$data;

    ($self->{'debug'} & $DEBUG_PACKETS) && $self->Log("Sending: ".$self->packetAsHex($buf));

    $self->{'nSentPackets'} += 1;
    my $ok = send($self->{'socket'},$buf,0);

    return $ok
}

sub lookAtMapObject
{
    my $self = shift;
    my ($id) = @_;

    $self->send($LOOK_AT_MAP_OBJECT,pack('L',$id));
}

sub sendPM
{
    my $self = shift;
    my ($user,$msg) = @_;

   push(@{$self->{'pmQueue'}}, "$user $msg");
}

sub dropItem
{
    my $self = shift;
    my ($qty,$name) = @_;

    my $onHand = $self->qtyOnHand($name);
    if ($onHand <= 0) {
        $self->Log("Don't have any $name to drop");
        return 0;
    }
    if ($qty > $onHand) {
        $qty = $onHand;
        $self->Log("Only have any $qty $name to drop");
    }
    my $dropped = 0;
    my $inv = $self->{'invByName'}->{lc($name)};
    foreach my $item (values %$inv) {
        my $pos  = $item->{'pos'};
        my $n    = $item->{'quantity'};
        my $drop = ($qty > $n) ? $n : $qty;
        $self->send($DROP_ITEM,pack('CV',$pos,$drop));
        $dropped += $drop;
        ($dropped >= $qty) || last;
    }

    return $qty;
}

sub dropAll
{
    my $self = shift;

    my $me = $self->{'me'};
    my $x  = $self->{'me'}->{'xpos'} || "unkown";
    my $y  = $self->{'me'}->{'ypos'} || "unkown";

    my @items = keys(%{$self->{'invByPos'}});
    foreach my $i (@items) {
        my $pos  = $self->{'invByPos'}->{$i}->{'pos'};
        my $qty  = $self->{'invByPos'}->{$i}->{'quantity'};
        my $name = $self->{'invByPos'}->{$i}->{'name'} || "'object with no name'";
        $self->Log("Dropping $qty $name at ($x,$y)");
        $self->send($DROP_ITEM,pack('CV',$pos,$qty));
    }
}

sub putInStorage
{
    my $self = shift;
    my ($qty,$name) = @_;

    my $onHand = $self->qtyOnHand($name);
    if ($onHand <= 0) {
        $self->Log("Don't have any $name to put in storage");
        return 0;
    }
    if ($qty > $onHand) {
        $qty = $onHand;
        $self->Log("Only have any $qty $name to put in storage");
    }
    my $stored = 0;
    my $inv = $self->{'invByName'}->{lc($name)};
    foreach my $item (values %$inv) {
        my $pos = $item->{'pos'};
        my $n   = $item->{'quantity'};
        my $sto = ($qty > $n) ? $n : $qty;
        $self->Log("Putting $sto $name in stoarge");
        $self->send($DEPOSITE_ITEM,pack('CV',$pos,$sto));
        $stored += $sto;
        ($stored >= $qty) || last;
    }
    return $qty;
}

sub tradeObject
{
    my $self = shift;
    my ($qty,$name) = @_;

    my $onHand = $self->qtyOnHand($name);
    if ($onHand <= 0) {
        $self->Log("I don't have any $name to put up for trade");
        return;
    }
    if ($onHand < $qty) {
        $qty = $onHand;
        $self->Log("I only have $qty $name to put up for trade");
    }
    my $traded = 0;
    my $inv = $self->{'invByName'}->{lc($name)};
    foreach my $item (values %$inv) {
        my $pos   = $item->{'pos'};
        my $n     = $item->{'quantity'};
        my $trade = ($qty > $n) ? $n : $qty;
        $self->send($PUT_OBJECT_ON_TRADE,pack('CCV',1,$pos,$trade));
        $traded += $trade;
        ($traded >= $qty) || last;
    }
    return $qty;
}

sub useInventoryItem
{
    my $self = shift;
    my ($name) = @_;

    $name = lc($name);
    if (!exists $self->{'invByName'}->{$name}) {
        $self->Log("I don't have a $name to use");
        return undef;
    }
    my @items = keys(%{$self->{'invByName'}->{$name}});
    if ($#items < 0) {
        $self->Log("No $name at any position . . .");
        return undef;
    }
    my $item = $self->{'invByName'}->{$name}->{$items[0]};
    if ($item->{'cooldown'} > time()) {
        $self->Log("$name has not cooled down yet");
        return undef;
    }
    $self->send($USE_INVENTORY_ITEM,pack('v',$item->{'pos'}));

    foreach my $item (values %{$self->{'invByPos'}}) {
        $item->{'cooldown'} = time()+1;
    }
    return 1;
}

sub attackActor
{
    my $self = shift;
    my ($id) = @_;

    $self->send($ATTACK_SOMEONE,pack('L',$id));
    $self->{'path'} = undef;
}

sub harvest
{
    my $self = shift;
    my ($id) = @_;

    $self->send($HARVEST, pack('v',$id));
}

sub isDead
{
    my $self = shift;
    my ($actor) = @_;

    return $actor->{'dead'};
}

sub locateMe
{
    my $self = shift;

    $self->{'locateMe'} = undef;
    $self->send($LOCATE_ME,"");
}

sub keepAlive
{
    my $self = shift;
    my ($force) = @_;

    my $currentTime = time();
    my $nextHeartbeatTime = $self->{'lastHeartbeatTime'} + $self->{'heartbeatTimer'};
    if (($currentTime >= $nextHeartbeatTime) || ($force)) {
        $self->send($HEART_BEAT,"");
        $self->{'lastHeartbeatTime'} = time();
    }
    if (($self->{'canTrade'}) && ($self->{'msgInterval'} >= 15)) {
        my $nextMsgTime = $self->{'lastMsgAt'} + $self->{'msgInterval'} * 60;
        if ($currentTime > $nextMsgTime) {
            $self->{'lastMsgAt'} = $currentTime;
            $self->Advertise();
        }
    }
}

# unpack the items list from the pack sent by
# the server in to a hash
sub getItemsList
{
    my $self = shift;
    my ($data) = @_;
    my %items;

    my $nItems = unpack('C', substr($data,0,1));
    for(my $i=0; $i<$nItems; $i++) {
        my $item = {
            'image'    => unpack('v', substr($data,$i*8+1,2)),
            'quantity' => unpack('V', substr($data,$i*8+1+2,4)),
            'pos'      => unpack('C', substr($data,$i*8+1+6,1)),
            'flags'    => unpack('C', substr($data,$i*8+1+7,1)),
        };
        $items{$item->{'pos'}} = $item;
    }
    return \%items;
}

sub deleteItem
{
    my $self = shift;
    my ($pos) = @_;

    if (!exists $self->{'invByPos'}->{$pos}) {
        $self->Log("Can't delete something I don't have !");
        return;
    }
    my $name = $self->{'invByPos'}->{$pos}->{'name'};
    delete $self->{'invByPos'}->{$pos};
    if (!defined($name)) {
        $self->Log("Deleteing an item with no name !");
        return;
    }
    if (!exists $self->{'invByName'}->{$name}) {
        $self->Log("Deleting an item with an unkown name !");
        return;
    }
    delete $self->{'invByName'}->{$name}->{$pos};
    if (keys(%{$self->{'invByName'}->{$name}}) == 0) {
        delete $self->{'invByName'}->{$name};
        $self->Log("I no longer have any $name");
    }
}

sub Say
{
    my $self = shift;
    my ($msg) = @_;

    $self->send($RAW_TEXT,$msg);
    if ($msg =~ m/^\#beam me/i) {
print STDERR "Beaming may screw x,y locations up !\n";
#        $self->{'me'}->{'xpos'} = undef;
#        $self->{'me'}->{'ypos'} = undef;
    }
    ($self->{'debug'} & $DEBUG_TEXT) &&
        $self->Log("I said '$msg'");
}

sub LogTrade
{
    my $self = shift;

    my $trader = $self->{'tradeWith'};
    foreach my $pos (keys %{$self->{'thereTrades'}}) {
        my $name = $self->{'thereTrades'}->{$pos}->{'name'};
        my $qty  = $self->{'thereTrades'}->{$pos}->{'quantity'};
        $self->Log("$trader gave me $qty '".$name."'");
    }
    foreach my $pos (keys %{$self->{'myTrades'}}) {
        my $name = $self->{'myTrades'}->{$pos}->{'name'};
        my $qty  = $self->{'myTrades'}->{$pos}->{'quantity'};
        $self->Log("I gave $trader $qty '".$name."'");
    }
    $self->Log("Trade with '$trader' complete");
}

sub getActors($)
{
    my $self = shift;

    my @actors = values %{$self->{'actorsByID'}};

    return wantarray ? @actors : \@actors;
}

sub actorsPosition
{
    my $self = shift;
    my ($id) = @_;

    my $actor = $self->{'actorsByID'}->{$id};
    return ($actor->{'xpos'},$actor->{'ypos'});
}

sub moveTo
{
    my $self = shift;
    my ($x,$y) = @_;

    ($x =~ m/^\d+$/) || confess "x='$x' which is not numeric";
    ($y =~ m/^\d+$/) || confess "y='$y' which is not numeric";

    $self->{'me'}->{'lastMoved'} = time();

    $self->send($MOVE_TO,pack('vv',$x,$y));
}

###########################################################################
# Bag handling functions                                                  #
###########################################################################

sub addBag
{
    my $self = shift;
    my ($id,$x,$y,$z) = @_;

    if ($id >= $MAXBAGS) {
        $self->Log("Bad bag ID $id at ($x,$y)");
        return undef;
    }
    if (defined($self->{'bagsByID'}->{$id})) {
        $self->Log("Bag($id) already exists! this should not happen");
    }
    my $bag = {
        'bagX'      => $x,
        'bagY'      => $y,
        'bagZ'      => $z,
        'bagID'     => $id,
    };
    $self->{'bagsByID'}->{$id} = $bag;
    #$self->Log("Bag($id) at ($x,$y,$z)");

    return $bag;
}

sub getBagByLocation
{
    my $self = shift;
    my ($x,$y) = @_;

    foreach my $id (keys %{$self->{'bagsByID'}}) {
        ($self->{'bagsByID'}->{$id}->{'bagX'} == $x) || next;
        ($self->{'bagsByID'}->{$id}->{'bagY'} == $y) || next;
        return $id;
    }
    return undef;
}

sub getBagByID
{
    my $self = shift;
    my ($id) = @_;
    (exists $self->{'bagsByID'}->{$id}) || return undef;
    return $self->{'bagsByID'}->{$id};
}

sub openBag
{
    my $self = shift;
    my ($id) = @_;

    my $bag = $self->{'bagsByID'}->{$id};
    if (!defined($bag)) {
        $self->Log("Opening non existant bag $id, this should not happen");
        return undef;
    }
    my $me = $self->{'me'};
    if (($bag->{'bagX'} != $me->{'xpos'}) or ($bag->{'bagY'} != $me->{'ypos'})) {
        $self->Log("Can't open bag $id because I am not on it");
        return undef;
    }
    if (defined($bag->{'items'})) {
        delete $bag->{'items'};
    }
    push(@{$self->{'groundItems'}}, $bag);
    $self->send($INSPECT_BAG,pack('C',$id));
    ($self->{'debug'} & $DEBUG_BAGS) &&
        $self->Log("Inspecting bag $id");

    return $bag;
}

sub nearestBag($$)
{
    my $self  = shift;
    my ($all) = @_;

    my $closest = undef;
    my $dist    = 100000;

    foreach my $bagID (keys %{$self->{'bagsByID'}}) {
        my $bag = $self->{'bagsByID'}->{$bagID};
        if (!defined($bag->{'lookedAt'}) || $all) {
            my $d = $self->distanceTo($bag->{'bagX'},$bag->{'bagY'});
            if ($d < $dist) {
                $dist = $d;
                $closest = $bag;
            }
        }
    }
    if ($self->{'debug'} & $DEBUG_BAGS) {
        my $id = $closest->{'bagID'};
        my ($x,$y) = ($closest->{'bagX'},$closest->{'bagY'});
        $self->Log("Nearest bag($id) is at ($x,$y), distance=$dist");
    }
    return ($closest,$dist);
}

sub pickUp($$$)
{
    my $self = shift;
    my ($bag,$pos,$qty) = @_;

    my $item = $bag->{'items'}->{$pos};
    if (!defined($item)) {
        $self->Log("Picking up item from bad position in bag");
        return undef;
    }
    if ($item->{'quantity'} < $qty) {
        $self->Log("Picking up more than in the bag");
        $qty = $item->{'quantity'};
    }
    $self->send($PICK_UP_ITEM, pack('CV',$pos,$qty));
    $item->{'pickUp'} = $qty;
    push(@{$self->{'pickUpQueue'}}, $item);
}

###########################################################################
#                                                                         #
###########################################################################

sub distanceTo
{
    my $self = shift;
    my ($toX,$toY) = @_;
    my $fromX = $self->{'me'}->{'xpos'};
    my $fromY = $self->{'me'}->{'ypos'};

    return $self->{'Map'}->distance($fromX,$fromY,$toX,$toY);
}

sub getStat
{
    my $self = shift;
    my ($stat) = @_;
    my @stat = ();
    if (exists $self->{'stats'}->{$stat}) {
        @stat = @{$self->{'stats'}->{$stat}};
    }
    return wantarray ? @stat : $stat[0];
}

sub useMapObject
{
    my $self = shift;
    my ($objID) = @_;

    $self->send($USE_MAP_OBJECT,pack('Vl',$objID,-1));
}

sub touchPlayer
{
    my $self = shift;
    my ($name) = @_;

    $name = lc($name);
    if (!defined($self->{'actorsByName'}->{$name})) {
        $self->Log("Not touching unkown player $name");
        return;
    }
    my $id = $self->{'actorsByName'}->{$name}->{'id'};

    $self->{'crntNPC'} = $id;
    $self->send($TOUCH_PLAYER,pack('l',$id));
    $self->{'NPCchat'}->{$id}->{'waiting'} = time();
    delete $self->{'NPCchat'}->{$id}->{'options'};
    delete $self->{'NPCchat'}->{$id}->{'text'};
    delete $self->{'NPCchat'}->{$id}->{'name'};
}

sub respondToNPC
{
    my $self = shift;
    my ($opt) = @_;

    my $id = $opt->{'id'};
    $self->{'crntNPC'} = $id;
    $self->send($RESPOND_TO_NPC,pack('vv',$opt->{'actor'},$id));
    $self->{'NPCchat'}->{$id}->{'waiting'} = time();

}

###########################################################
# MISCELLANEOUS CALLBACKS                                 #
###########################################################

sub LOG_IN_OK
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    $self->{'loggedIn'} = 1;
}

sub LOG_IN_NOT_OK
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    $self->{'loggedIn'}      = 0;
    $self->{'failedLogins'} += 1;
}

sub PING_REQUEST
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    $self->send($PING_RESPONSE,$data);
}

sub NEW_MINUTE
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    $self->{'gminute'} = unpack('v',$data);
    if ($self->{'gminute'} % 60 == 0) {
        $self->{'canHarvExp'} = 1;
    }
}

sub STORAGE_LIST
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my @items = unpack('C(CZ*)*',$data); # How can you not love perl !
    my $n = shift @items;
    for(my $i=0; $i<$n; $i++) {
        my $id   = shift(@items);
        my $name = shift(@items);
        $self->{'stoCategories'}->{$name} = $id;
    }
    $self->{'waitingForStorage'} = 0;
}

sub STORAGE_ITEMS
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $n = unpack('C',substr($data,0,1));
    if ($n == 255) {
        return;
    }

    my $catgry = unpack('C',substr($data,1,1));

    my @items = unpack("CC(vVC)$n", $data);
}


sub GET_ITEMS_COOLDOWN
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my @v = unpack('(Cvv)*',$data);
    my $n = ($#v+1)/3;

    foreach my $item (values %{$self->{'invByPos'}}) {
        $item->{'cooldown'} = 0;
    }
    for(my $i=0; $i<$n; $i++) {
        my ($pos,$max,$cool) = @v[$i*3 .. $i*3+2];
        $self->{'invByPos'}->{$pos}->{'cooldown'} = time()+$cool+1;
    }
}

sub RAW_TEXT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $text = substr($data,2);

    ($self->{'debug'} & $DEBUG_TEXT) && $self->Log("RAW TEXT: $text");

    if (($text =~ m/\s*(\w+) wants to trade with you/) && $self->{'canTrade'}) {
        my $name = lc($1);
        $self->Log("Trade request from '".$name."'");
        my $actor = $self->{'actorsByName'}->{$name};
        if (!defined($actor)) {
            $self->sendPM($name, "Sorry, I can't get your actor ID, this should not happen . . .");
            $self->sendPM($name, "Please notify the owner of this bot");
            return;
        }
        $self->send($TRADE_WITH,pack('V',$actor->{'id'}));
    }
    elsif ($text =~ m/^\[PM from (\w+): (.*)\]/) {
        $self->Log("$1 said '".$2."'");
        if($self->can("handlePM")) {
            $self->handlePM($1,$2);
        }
    }
    elsif ($text =~ m/^You are in (.*\S)\s+\[(.+)\]/) {
        $self->{'locateMe'} = "$1 [$2]";
        if (defined($self->{'locReply'})) {
            $self->sendPM($self->{'locReply'},"$1 at $2");
            $self->{'locReply'} = undef;
        }
    }
    elsif ($text =~ m/^Items you have in your storage:/) {
        my @lines = split("\n", $text);
        if (my $user = $self->{'tellSTO'}) {
            foreach my $line (@lines) {
                ($line =~ m/$self->{'stoRE'}/i) && $self->sendPM($user,$line);
            }
        }
    }
    elsif ($text =~ m/^Your harvesting experience limit for this hour expired/) {
        $self->{'canHarvExp'} = 0
    }
    elsif ($text =~ m/^Today is a special day/) {
        my @lines = split("\n",$text);
        $self->{'specialDay'} = $lines[1];
        $self->Log("Special Day: ".$self->{'specialDay'});
    }
    elsif ($text =~ m/^Day ends/) {
        $self->{'specialDay'} = "Just an ordinary day";
    }

    return $text;
}

##########################################################################
# ACTOR RELATED CALLBACKS                                                #
##########################################################################

sub decodeTitle
{
    my ($title) = @_;

    my ($name,$nameC,$guild,$guildC) = ("","","","");
    my ($i,$j,$k);
    my $len = length($title);

    for($i=0; $i <= $len-1; $i++) {
        (ord(substr($title,$i)) >= 127) || last;
    }
    for($j=$i; $j <= $len-1; $j++) {
        (ord(substr($title,$j,1)) < 127) || last;
    }
    if ($j <= $len-1) {
        for($k=$j; $k <= $len-1; $k++) {
            (ord(substr($title,$k,1)) >= 127) || last;
        }
        $guildC = ord(substr($title,$j,$k-$j));
        $guild  = substr($title,$k);
    }
    $nameC  = ord(substr($title,0,$i));
    $name   = substr($title,$i,$j-$i);

    return ([$nameC,$name],[$guildC,$guild]);
}

sub ADD_NEW_ACTOR
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $actor;
    my $id                    = unpack('v', substr($data,0,2));
    $actor->{'id'}            = $id;
    $actor->{'xpos'}          = unpack('v', substr($data,2,2)) & 0x7FF;
    $actor->{'ypos'}          = unpack('v', substr($data,4,2)) & 0x7FF;
    $actor->{'zpos'}          = unpack('v', substr($data,6,2));
    $actor->{'prevX'}         = $actor->{'xpos'};
    $actor->{'prevY'}         = $actor->{'ypos'};
    $actor->{'zrot'}          = unpack('v', substr($data,8,2));
    $actor->{'bufs'}          = 0; # ignore bufs at the moment
    $actor->{'type'}          = ord(substr($data,10,1));
    $actor->{'frame'}         = substr($data,11,1);
    $actor->{'stats'}->{'mp'} = [unpack('v', substr($data,14,2)),unpack('v', substr($data,12,2))];
    $actor->{'kind'}          = ord(substr($data,16,1));
    my ($name,$guild)         = decodeTitle(unpack('Z*',substr($data,17,13)));
    $actor->{'nColour'}       = $name->[0];
    $actor->{'name'}          = lc($name->[1]);
    $actor->{'gColour'}       = $guild->[0];
    $actor->{'guild'}         = $guild->[1];
    $actor->{'lastMoved'}     = time();
    $actor->{'inCombat'}      = 0;
    $actor->{'map'}           = $self->crntMap();

    $self->{'actorsByID'}->{$id}                = $actor;
    $self->{'actorsByName'}->{$actor->{'name'}} = $actor;   # Assumes unique names . . .
    if ($self->{'my_id'} == $id) {
        $self->{'me'} = $self->{'actorsByID'}->{$id};
    }

    return $actor;
}

sub ADD_NEW_ENHANCED_ACTOR
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $actor;
    my $id                    = unpack('v', substr($data,0,2));
    $actor->{'id'}            = $id;
    $actor->{'xpos'}          = unpack('v', substr($data,2,2)) & 0x7FF;
    $actor->{'ypos'}          = unpack('v', substr($data,4,2)) & 0x7FF;
    $actor->{'zpos'}          = unpack('v', substr($data,6,2));
    $actor->{'prevX'}         = $actor->{'xpos'};
    $actor->{'prevY'}         = $actor->{'ypos'};
    $actor->{'zrot'}          = unpack('v', substr($data,8,2));
    $actor->{'bufs'}          = 0; # ignore bufs at the moment
    $actor->{'type'}          = ord(substr($data,10,1));
    $actor->{'frame'}         = substr($data,11,1);
    $actor->{'skin'}          = substr($data,12,1);
    $actor->{'hair'}          = substr($data,13,1);
    $actor->{'shirt'}         = substr($data,14,1);
    $actor->{'pants'}         = substr($data,15,1);
    $actor->{'boots'}         = substr($data,16,1);
    $actor->{'head'}          = substr($data,17,1);
    $actor->{'shield'}        = substr($data,18,1);
    $actor->{'weapon'}        = substr($data,19,1);
    $actor->{'cape'}          = substr($data,20,1);
    $actor->{'helmet'}        = substr($data,21,1);
    $actor->{'stats'}->{'mp'} = [unpack('v', substr($data,25,2)),unpack('v', substr($data,23,2))];
    $actor->{'kind'}          = ord(substr($data,27,1));
    my ($name,$guild)         = decodeTitle(unpack('Z*',substr($data,28,13)));
    $actor->{'nColour'}       = $name->[0];
    $actor->{'name'}          = lc($name->[1]);
    $actor->{'gColour'}       = $guild->[0];
    $actor->{'guild'}         = $guild->[1];
    $actor->{'lastMoved'}     = time();
    $actor->{'inCombat'}      = 0;
    $actor->{'map'}           = $self->crntMap();

    $self->{'actorsByID'}->{$id} = $actor;
    $self->{'actorsByName'}->{$actor->{'name'}} = $actor;   # Assumes unique names . . .
    if ($self->{'my_id'} == $id) {
        $self->{'me'} = $self->{'actorsByID'}->{$id};
    }
    defined($self->{'map'}) && $self->{'map'}->setOccupied($actor);

    return $actor;
}

sub KILL_ALL_ACTORS
{
    my $self = shift;
    my ($type,$len,$data) = @_;
    $self->{'actorsByID'} = {};
    $self->{'actorsByName'} = {};
    $self->{'me'} = undef;
    $self->{'path'} = undef;
    defined($self->{'map'}) && $self->{'map'}->setAllVacant();
}

sub REMOVE_ACTOR
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $id = unpack('v', $data);
    my $actor = $self->{'actorsByID'}->{$id};
    if (defined($actor)) {
        my $name = $actor->{'name'};
        if (defined($self->{'actorsByName'}->{$name})) {
            if ($self->{'actorsByName'}->{$name}->{'id'} == $id) {
                delete $self->{'actorsByName'}->{$name};
            }
        }
        delete $self->{'actorsByID'}->{$id};
        defined($self->{'map'}) && $self->{'map'}->setVacant($actor);
    }
}

sub ADD_ACTOR_COMMAND
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my %moveXY = (
        "n" => [ 0, 1], "ne" => [  1, 1],
        "e" => [ 1, 0], "se" => [  1,-1],
        "s" => [ 0,-1], "sw" => [ -1,-1],
        "w" => [-1, 0], "nw" => [ -1, 1],
    );

    my $actorID = unpack('v', substr($data,0,2));
    my $cmd     = substr($data,2,1);
    my $actor   = $self->{'actorsByID'}->{$actorID};
    my $cmdStr  = $ActorCommandsByID{$cmd};
    my $name    = "Unknown actor";
    if (defined($actor)) {
        $name = $actor->{'name'};
        if ($cmdStr =~ m/^move_(\w+)/) {
            $actor->{'prevX'} = $actor->{'xpos'};
            $actor->{'prevY'} = $actor->{'ypos'};
            defined($self->{'map'}) && $self->{'map'}->setVacant($actor);
            $actor->{'xpos'} += $moveXY{$1}->[0];
            $actor->{'ypos'} += $moveXY{$1}->[1];
            defined($self->{'map'}) && $self->{'map'}->setOccupied($actor);
            $actor->{'lastMoved'} = time();
        }
        elsif ($cmdStr =~ m/^die.*/) {
           $actor->{'dead'} = 1;
           $actor->{'inCombat'} = 0;
        }
        elsif ($cmdStr =~ m/^enter_combat.*/) {
            $actor->{'inCombat'} = 1;
        }
        elsif ($cmdStr =~ m/^leave_combat.*/) {
            $actor->{'inCombat'} = 0;
        }
    }
    ($self->{'debug'} & $DEBUG_TYPES) &&
        $self->Log("Actor=$name Command=$cmdStr");
}

sub GET_ACTOR_DAMAGE
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $id  = unpack('v',substr($data,0,2));
    my $dmg = unpack('v',substr($data,2,2));
    my $actor = $self->{'actorsByID'}->{$id};
    if (!defined($actor)) {
        $self->Log("Damage to unkown actor($id)");
        return undef;
    }
    $actor->{'stats'}->{'mp'} -= $dmg;

    return $actor;
}

sub GET_ACTOR_HEAL
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $id  = unpack('v',substr($data,0,2));
    my $dmg = unpack('v',substr($data,2,2));
    my $actor = $self->{'actorsByID'}->{$id};
    if (!defined($actor)) {
        $self->Log("Healing unkown actor($id)");
        return undef;
    }
    $actor->{'stats'}->{'mp'} += $dmg;

    return $actor;
}

sub SEND_NPC_INFO
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $id   = $self->{'crntNPC'};
    my $name = unpack('Z*',$data);
    $self->{'NPCchat'}->{$id}->{'name'} = $name;
    $self->{'NPCchat'}->{$id}->{'waiting'} = time();
}

sub NPC_TEXT
{
    my $self = shift;
    my ($type,$len,$data) = @_;
    my $txt;

    my $id = $self->{'crntNPC'};
    my ($byte1,$byte2) = unpack('CC',$data);
    if  ($byte1 > 127 and $byte2 > 127) {
        # Questlog addition (don't handle it at the moment)
        $txt = substr($data,2); }
    else {
        $txt = substr($data,1);
    }
    $self->{'NPCchat'}->{$id}->{'text'} = $txt;
    $self->{'NPCchat'}->{$id}->{'waiting'} = time();
    return $txt
}

sub NPC_OPTIONS_LIST
{
    my $self = shift;
    my ($type,$len,$data) = @_;
    my $offset=0;
    my %options;

    my $fromID = $self->{'crntNPC'};
    for(my $i=0;$i<20;$i++) {
        if ($offset + 3 > $len) {
            last;
        }
        my $n = unpack('v',substr($data,$offset,2));
        if ($offset + 3 + $n + 2 + 2 > $len) {
            last;
        }
        my $response = lc(substr($data,$offset+2,$n-1));
        my $id       = unpack('v',substr($data,$offset+2+$n));
        my $toActor  = unpack('v',substr($data,$offset+2+2+$n));
        $options{$response} = {
            'id' => $id,
            'actor' => $toActor,
        };
        $offset += $n+2+2+2;
        ($self->{'debug'} & $DEBUG_TEXT) && $self->Log("NPC Option($toActor): $id: $response");
    }
    $self->{'NPCchat'}->{$fromID}->{'options'} = \%options;
    delete $self->{'NPCchat'}->{$fromID}->{'waiting'};
    return \%options;
}

##########################################################################
# CALLBACKS ABOUT THIS CLIENT                                            #
##########################################################################

sub TELEPORT_OUT
{
    my $self = shift;
    my ($type,$len,$data) = @_;
}

sub TELEPORT_IN
{
    my $self = shift;
    my ($type,$len,$data) = @_;
}

sub GET_TELEPORTERS_LIST
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $n = unpack('c',substr($data,0,2));
    for(my $i=0; $i<$n; $i++) {
        my ($x,$y,$type) = unpack('vvC',substr($data,$i*5+2,5));
        $self->Log("TELEPORTER at ($x,$y)");
    }
}

sub getMap
{
    my $self = shift;
    my ($name) = @_;

    $name = "/maps/".$name.".elm";
    my $map = $self->{'mapCache'}->{$name};
    if (!defined($map)) {
        $map = Games::EternalLands::Map->new($name,$self->{'elDir'});
        $self->{'mapCache'}->{$name} = $map;
    }
    return $map;
}

sub CHANGE_MAP
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    $self->{'path'}     = undef;
    $self->{'bagsByID'} = {};
    if (defined($self->{'elDir'})) {
        my $name = unpack('Z*',$data);

        if (!defined($self->{'mapCache'}->{$name})) {
            my @harvestables;
            my @entrable;
            my $map = Games::EternalLands::Map->new($name,$self->{'elDir'});
            my @objects = $map->objects();
            foreach my $id (@objects) {
                my $fname = $map->{'3dByID'}->{$id}->{'file_name'};
                $fname =~ s%.*/([^/]+\.e3d)$%$1%;
                if (defined($self->{'harvestableTypes'}->{$fname})) {
                    push(@harvestables,$id);
                }
                if (defined($self->{'entrableTypes'}->{$fname})) {
                    push(@entrable,$id);
                }
                delete $self->{'Map'}->{'3dByID'}->{$id}->{'file_name'};
            }
            $map->{'entrable'} = \@entrable;
            $map->{'harvestables'} = \@harvestables;
            $self->{'mapCache'}->{$name} = $map;
        }
        $self->{'Map'} = $self->{'mapCache'}->{$name};
    }
    $self->locateMe();
}

=begin
$VAR1 = [
          10, 10, phy
          14, 14, coo
          4, 4, rea
          4, 4, wil
          4, 4, ins
          4, 4, vit
0-11

          0, 0, nexus
          0, 0,
          0, 0,
          0, 0,
          0, 0, 
          0, 0,
12-23

24         0, 0, man
 6        16, 16, har
 8        0, 0, alc
30        16, 23, oa
 2        19, 19, att
 4        17, 17, def
 6        0, 0, mag
 8        0, 0, pot
24-39

          240, 240, carry
          28, 35, mp
          32, 32, ep
40-45

          65506,
          250,
          0,
          9175040,
          933232640,
          1184235520,
          0,
          9175040,
          562888704,
          1099759617,
          2420834305,
          2601713664,
          1503789056,
          1539506176,
          0,
          9175040,
          0,
          9175040,
          0,
          65535,
          250,
          0,
          0,
          0,
          0,
          140,
          0,
          0
        ];
=cut

sub HERE_YOUR_STATS
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my @v = unpack('v[48]V[17]v[7]',$data);
    $self->{'stats'} = {
        'phy' =>  [$v[0],$v[1]],
        'coo' =>  [$v[2],$v[3]],
        'rea' =>  [$v[4],$v[5]],
        'wil' =>  [$v[6],$v[7]],
        'ins' =>  [$v[8],$v[9]],
        'phy' => [$v[10],$v[11]],
    };
    $self->{'nexus'} = {
        'human'      => [$v[12],$v[13]],
        'animal'     => [$v[14],$v[15]],
        'vegetal'    => [$v[16],$v[17]],
        'inorganic'  => [$v[18],$v[19]],
        'artificial' => [$v[20],$v[21]],
        'magic'      => [$v[22],$v[23]],
    };
    $self->{'skills'} = {
        'man' => [$v[24],$v[25]],
        'har' => [$v[26],$v[27]],
        'alc' => [$v[28],$v[29]],
        'oa'  => [$v[30],$v[31]],
        'att' => [$v[32],$v[33]],
        'def' => [$v[34],$v[35]],
        'mag' => [$v[36],$v[37]],
        'pot' => [$v[38],$v[39]],
        'sum' => [$v[66],$v[67]],
        'cra' => [$v[70],$v[71]],
    };
    $self->{'stats'} = {
        'carry' => [$v[40],$v[41]],
        'mp'    => [$v[42],$v[43]],
        'ep'    => [$v[44],$v[45]],
        'food'  => [$v[46],45],
    };
    $self->{'research'} = {
        'completed' => $v[47],
        'researching' => $v[81],
        'total' => $v[82],
    };

    $self->{'experience'} = {
        'man' => [$v[49],$v[50]],
        'har' => [$v[51],$v[52]],
        'alc' => [$v[53],$v[54]],
        'oa'  => [$v[55],$v[56]],
        'att' => [$v[57],$v[58]],
        'def' => [$v[59],$v[60]],
        'mag' => [$v[61],$v[62]],
        'pot' => [$v[63],$v[64]],
        'sum' => [$v[69],$v[70]],
        'cra' => [$v[73],$v[74]],
    };
=begin
print STDERR Dumper(\@v);
print STDERR "stats=",Dumper($self->{'stats'});
print STDERR "nexus=",Dumper($self->{'nexus'});
print STDERR "skills=",Dumper($self->{'skills'});
print STDERR "research=",Dumper($self->{'research'});
print STDERR "experience=",Dumper($self->{'experience'});
 exit 1;
=cut

}

sub SEND_PARTIAL_STAT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $n = $len/5;
    for(my $i=0; $i<$n; $i++) {
        my $stat  = substr($data,$i*5+0,1);
        my $value = unpack('l', substr($data,$i*5+1,4));

        if ($stat eq $FOOD_LEV) {
            $self->{'stats'}->{'food'}->[0] = $value; }
        elsif ($stat eq $MAT_POINT_CUR) {
            $self->{'stats'}->{'mp'}->[0] = $value; }
        elsif ($stat eq $MAT_POINT_BASE) {
            $self->{'stats'}->{'mp'}->[1] = $value; }
        elsif ($stat eq $ETH_POINT_CUR) {
            $self->{'stats'}->{'ep'}->[0] = $value; }
        elsif ($stat eq $ETH_POINT_BASE) {
            $self->{'stats'}->{'ep'}->[1] = $value; }
        elsif ($stat eq $CARRY_WGHT_CUR) {
            $self->{'stats'}->{'carry'}->[0] = $value; }
        elsif ($stat eq $CARRY_WGHT_BASE) {
            $self->{'stats'}->{'carry'}->[1] = $value; }
        elsif ($stat eq $DEF_EXP) {
            $self->{'experience'}->{'def'}->[0] = $value; }
        elsif ($stat eq $DEF_EXP_NEXT) {
            $self->{'experience'}->{'def'}->[1] = $value; }
        elsif ($stat eq $ATT_EXP) {
            $self->{'experience'}->{'att'}->[0] = $value; }
        elsif ($stat eq $ATT_EXP_NEXT) {
            $self->{'experience'}->{'att'}->[1] = $value; }
        elsif ($stat eq $HARV_EXP) {
            $self->{'experience'}->{'har'}->[0] = $value; }
        elsif ($stat eq $HARV_EXP_NEXT) {
            $self->{'experience'}->{'har'}->[1] = $value; }
        elsif ($stat eq $HARV_S_CUR) {
            $self->{'skills'}->{'har'}->[0] = $value; }
        elsif ($stat eq $HARV_S_BASE) {
            $self->{'skills'}->{'har'}->[1] = $value; }
        elsif ($stat eq $ATT_S_CUR) {
            $self->{'skills'}->{'att'}->[0] = $value; }
        elsif ($stat eq $ATT_S_BASE) {
            $self->{'skills'}->{'att'}->[1] = $value; }
        elsif ($stat eq $DEF_S_CUR) {
            $self->{'skills'}->{'def'}->[0] = $value; }
        elsif ($stat eq $DEF_S_BASE) {
            $self->{'skills'}->{'def'}->[1] = $value; }
    }
}

sub YOU_ARE
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    $self->{'my_id'} = unpack('v', $data);
}

################################################################
# TRADE RELATED CALLBACKS                                      #
################################################################

sub GET_YOUR_TRADEOBJECTS
{
    my $self = shift;
    my ($type,$len,$data) = @_;
}

sub GET_TRADE_PARTNER_NAME
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $partner = substr($data,1);
    $self->{'tradeWith'} = $partner;

    $self->sendPM($self->{'tradeWith'},"please pm with what you wish to buy or sell");
}

# Blindly trust our trade partner, when they accept so
# do we (but see Bot.pm)
sub GET_TRADE_ACCEPT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $who = unpack('C', $data);
    if ($who) {
        $self->{'tradeAccepted'} += 1;
        my @accepted = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        foreach my $item (@{$self->{'??'}}) {
            my $pos = $item->{'pos'};
            $accepted[$pos] = $item->{'type'};
        }
        $data = pack('CCCCCCCCCCCCCCCC',@accepted);
        $self->send($ACCEPT_TRADE, $data);
    }
}

sub GET_TRADE_REJECT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $who = unpack('C', $data);
    if ($who) {
        $self->{'tradeAccepted'} = 0;
    }
}

# Called when an object is removed from the trade window.
# We only deal with objects our trade partner removed
# as we should know the state of our own trade objects
# We send a LOOK_AT_TRADE_ITEM to the server so that
# we can get the description for the object
sub REMOVE_TRADE_OBJECT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $pos  = unpack('C', substr($data,4,1));
    my $who  = unpack('C', substr($data,5,1));
    my $qty  = unpack('V', substr($data,0,4)),

    my $trades;
    if ($who) { # Trade partner removed object
        $trades = $self->{'thereTrades'}; }
    else {
        $trades = $self->{'myTrades'};
    }
    my $item = $trades->{$pos};
    if (!defined($item)) {
        $self->Log("removing unknown item from trade - this should not happen");
        return;
    }
    if ($item->{'quantity'} == $qty) {
        delete $trades->{$pos};
    }
    elsif ($item->{'quantity'} < $qty) {
        $self->Log("removing more from trade than is in the trade - this should not happen");
    }
    else {
        $item->{'quantity'} -= $qty;
    }
}

sub GET_TRADE_OBJECT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $qty    = unpack('V', substr($data,2,4)),
    my $pos    = unpack('C', substr($data,7,1));
    my $who    = unpack('C', substr($data,8,1));
    my $trades = ($who) ? $self->{'thereTrades'} : $self->{'myTrades'};

    if (defined($trades->{$pos})) {
        $trades->{$pos}->{'quantity'} += $qty; }
    else {
        $trades->{$pos} = {
            'pos'      => $pos,
            'image'    => unpack('v', substr($data,1,2)),
            'quantity' => $qty,
            'type'     => unpack('C', substr($data,6,1)),
        };
        $self->send($LOOK_AT_TRADE_ITEM, pack('CC',$pos,$who));
        push(@{$self->{'lookAtQueue'}}, [$GET_TRADE_OBJECT,$trades->{$pos}]);
    }
}

sub GET_TRADE_EXIT
{
    my $self = shift;

    if ($self->{'tradeAccepted'} == 2) {
        $self->sendPM($self->{'tradeWith'}," Thanks");
    }
    $self->LogTrade();


    $self->{'tradeWith'}     = undef;
    $self->{'thereTrades'}   = {};
    $self->{'myTrades'}      = {};
    $self->{'tradeOk'}       = 0;
    $self->{'tradeAccepted'} = 0;
}

################################################################
# INVENTORY RELATED CALLBACKS                                  #
################################################################

# decode the message from the server that tells us what is in
# our inventory.
# create a a hash of these objects by inventory position
# Send LOOK_AT_INVENTORY_ITEM for each item so that we can
# build a 'byName' hash of these items as well
sub HERE_YOUR_INVENTORY
{
    my $self = shift;

    my ($type,$len,$data) = @_;

    $self->{'nCarry'} = 0;
    $self->{'nEquip'} = 0;
    $self->{'invByPos'} = $self->getItemsList($data);

    my @posList = sort (keys %{$self->{'invByPos'}});
    foreach my $pos (@posList) {
        $self->send($LOOK_AT_INVENTORY_ITEM, pack('C',$pos));
        push(@{$self->{'lookAtQueue'}}, [$HERE_YOUR_INVENTORY,$self->{'invByPos'}->{$pos}]);
        if ($pos < 36) {$self->{'nCarry'} += 1;} else {$self->{'nEquip'} += 1;}
    }
}

sub REMOVE_ITEM_FROM_INVENTORY
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $pos  = unpack('C',$data);
    $self->deleteItem($pos);
    if ($pos < 36) {$self->{'nCarry'} -= 1;} else {$self->{'nEquip'} -= 1;}
}

sub GET_NEW_INVENTORY_ITEM
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $pos  = unpack('C', substr($data,6,1));
    my $newitem = {
        'image'    => unpack('v', substr($data,0,2)),
        'quantity' => unpack('V', substr($data,2,4)),
        'pos'      => $pos,
        'flags'    => unpack('C', substr($data,7,1)),
    };
    if ($newitem->{'quantity'} == 0) {
        $self->deleteItem($pos);
        if ($pos < 36) {$self->{'nCarry'} -= 1;} else {$self->{'nEquip'} -= 1;}
    }
    else {
        my $item = $self->{'invByPos'}->{$pos};
        if (defined($item) and defined($item->{'name'})) {
            $item->{'quantity'} = $newitem->{'quantity'};
            $self->Log("I now have $item->{'quantity'} $item->{'name'}");
        }
        else {
            $self->{'invByPos'}->{$pos} = $newitem;
            $data = pack('C',$pos);
            $self->send($LOOK_AT_INVENTORY_ITEM,$data);
            push(@{$self->{'lookAtQueue'}}, [$GET_NEW_INVENTORY_ITEM,$newitem]);
            if ($pos < 36) {$self->{'nCarry'} += 1;} else {$self->{'nEquip'} += 1;}
        }
    }

    return $newitem;
}

sub INVENTORY_ITEM_TEXT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my ($name,$desc,$weight);

    ($desc,$weight) = split("\n",$data);
    ($name,$desc)   = split(" - ",$desc);
    ($weight)       = ($weight =~ m/weight:\s+(\d+)\s*emu/i);
    $name           = lc(substr($name,1));

    my $q = shift(@{$self->{'lookAtQueue'}});
    if (defined($q)) {
        my $type          = $q->[0];
        my $item          = $q->[1];
        $item->{'name'}   = $name;
        $item->{'desc'}   = $desc;
        $item->{'weight'} = $weight;
        if ($type eq $HERE_YOUR_INVENTORY or $type eq $GET_NEW_INVENTORY_ITEM) {
            $self->{'invByName'}->{lc($name)}->{$item->{'pos'}} = $item;
        }
        ($self->{'debug'} & $DEBUG_TEXT) &&
            $self->Log("Item: $item->{'quantity'} $name");
    }
    else {
        $self->Log("Looking at item '$name' for no reason !");
    }
}

sub HERE_YOUR_GROUND_ITEMS
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $bag = $self->{'groundItems'}->[0];

    my $numItems = unpack('C',$data);
    if ($numItems > $ITEMS_PER_BAG) {
        $self->Log("Too many items in bag: $numItems");
        return undef;
    }
    for(my $i=0;$i<$numItems;$i++) {
        my $offset = $i*7+1;
        my $image  = unpack('v', substr($data,$offset,2));
        my $qty    = unpack('L',substr($data,$offset+2,4));
        my $pos    = unpack('C',substr($data,$offset+6,1));
        my $item   = {
            'pos'      => $pos,
            'quantity' => $qty,
            'image'    => $image,
            'bag'      => $bag,
        };
        $bag->{'items'}->{$pos} = $item;
        $self->send($LOOK_AT_GROUND_ITEM,pack('C',$pos));
        push(@{$self->{'lookAtQueue'}}, [$LOOK_AT_GROUND_ITEM,$item]);
    }
    return $bag;
}

###########################################################
# BAGS REALTED CALLBACKS                                  #
###########################################################

sub GET_NEW_BAG
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $x   = unpack('v', substr($data,0,2)),
    my $y   = unpack('v', substr($data,+2,2)),
    my $z   = 0,  #BUG
    my $id  = unpack('C', substr($data,4,1));
    my $bag = $self->addBag($id,$x,$y,$z);

    return $bag;
}

sub GET_BAGS_LIST
{
    my $self = shift;
    my ($type,$len,$data) = @_;
    my @bags = ();

    my $numBags = unpack('C',substr($data,0,1));
    if ($numBags > $MAXBAGS) {
        $self->Log("Bad number of bags in list: $numBags");
        return \@bags;
    }
    for(my $i=0; $i<$numBags; $i++) {
        my $offset = $i*5+1;
        my $x   = unpack('v', substr($data,$offset,2));
        my $y   = unpack('v', substr($data,$offset+2,2));
        my $z   = 0;
        my $id  = unpack('C', substr($data,$offset+4,1));
        my $bag = $self->addBag($id,$x,$y,$z);
        if (defined($bag)) {
            push(@bags, $bag);
        }
    }
    return \@bags;
}

sub DESTROY_BAG
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $bagID = unpack('C', substr($data,0,1));
    if (defined($self->{'bagsByID'}->{$bagID})) {
        delete $self->{'bagsByID'}->{$bagID}; }
    else {
        $self->Log("Destroying uknown bag $bagID");
    }
}

sub CLOSE_BAG
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $bag = shift(@{$self->{'groundItems'}});
    if ($self->{'debug'} & $DEBUG_BAGS) {
        $self->Log("Closed bag ".$bag->{'bagID'});
    }
}

###########################################################

sub processArgs
{
    my $self = shift;
    my @args  = @_;
    my @notUsed;

    while(my $arg = shift @args) {
        if ($arg eq '-server') {
            $self->{'server'} = shift @args; }
        elsif ($arg eq '-port') {
            $self->{'port'} = shift @args; }
        elsif ($arg eq '-elDir') {
            $self->{'elDir'} = shift @args; }
        elsif ($arg eq '-debug') {
            $self->{'debug'} |= shift @args; }
        else {
            push(@notUsed, $arg);
        }
    }
    return @notUsed;
}

sub new
{
    my $class = shift;
    my $self  = {};
    bless($self, $class);

    $self->{'debug'}             = 0;
    $self->{'server'}            = undef;
    $self->{'port'}              = undef;
    $self->{'username'}          = undef;
    $self->{'socket'}            = undef;
    $self->{'lastHeartbeatTime'} = 0;
    $self->{'heartbeatTimer'}    = 25;
    $self->{'connected'}         = 0;
    $self->{'loggedIn'}          = 0;
    $self->{'failedLogins'}      = 0;
    $self->{'buffer'}            = "";
    $self->{'packets'}           = [];
    $self->{'nRcvdPackets'}      = 0;
    $self->{'nSentPackets'}      = 0;
    $self->{'Map'}               = undef;
    $self->{'myd_id'}            = -1;
    $self->{'me'}                = undef;
    $self->{'actorsByID'}        = undef;
    $self->{'actorsByName'}      = undef;
    $self->{'elDir'}             = undef;
    $self->{'bagsByID'}          = {};
    $self->{'groundItems'}       = [];
    $self->{'lastMove'}          = 0;
    $self->{'locName'}           = "Lost";
    $self->{'locPos'}            = "0,0";
    $self->{'lastMoved'}         = time();
    $self->{'specialDay'}        = "Just an ordinary day";

    $self->{'itemsToSell'}       = {};
    $self->{'itemsToBuy'}        = {};
    $self->{'lastMsgAt'}         = time(); # no msg on startup
    $self->{'msgInterval'}       = 20;     # minutes

    $self->{'canTrade'}          = 1;
    $self->{'myTrades'}          = {};
    $self->{'thereTrades'}       = {};
    $self->{'tradeAccepted'}     = 0;

    $self->{'invByPos'}          = {};
    $self->{'invByName'}         = {};
    $self->{'lookAtQueue'}       = ();   # FIFO of objects we have asked to look at
    $self->{'pmQueue'}           = ();   # FIFO of objects we have asked to look at

    tie(%{$self->{'mapCache'}},'Tie::Cache',{MaxCount=>8});

    @_ = $self->processArgs(@_);

    my $elDir = $self->{'elDir'};
    if (!defined($elDir)) {
        $self->Log("elDir not defined - no map oriented functionaility");
        return $self;
    }

    open(FP, $elDir."/harvestable.lst") || die $elDir."/harvestable.lst";
    while(<FP>) {
        $_ =~ s/\r\n$//;
        $self->{'harvestableTypes'}->{$_} = 1;
    }
    close(FP);

    open(FP, $elDir."/entrable.lst") || die $elDir."/el/entrable.lst";
    while(<FP>) {
        $_ =~ s/\r\n$//;
        $_ =~ s%^.*/%%;
        $self->{'entrableTypes'}->{$_} = 1;
    }
    close(FP);

    return $self;
}

sub connect
{
    my $self = shift;

    while(@_) {
        my $arg = shift;
        if ($arg eq '-server') {
            $self->{'server'} = shift;
        }
        elsif ($arg eq '-port') {
            $self->{'port'} = shift;
        }
    }

    defined($self->{'server'}) || die "server must be defined";
    defined($self->{'port'})   || die "port must be defined";

    $self->{'socket'} = IO::Socket::INET->new(Proto => 'tcp',
                                              Blocking => 1,
                                              PeerAddr => $self->{'server'},
                                              PeerPort => $self->{'port'});

    if (!defined($self->{'socket'})) {
        $self->Log("Failed to create socket: $!");
        return 0;
    }

    $self->{'connected'} = 1;
    my ($type,$len,$packet) = $self->NextPacket();
    $self->Dispatch($type,$len,$packet);
    $self->keepAlive(1);

    return 1;
}

sub disconnect
{
    my $self = shift;

    close($self->{'socket'});
    $self->{'connected'} = 0;
    $self->{'socket'} = undef;
}

sub login
{
    my $self = shift;

    my ($user,$pass);
    if (@_) {
        ($user,$pass) = @_;
    }
    if (!defined($user) || !defined($pass)) {
        $self->Log("User and password must be passed");
        return 0;
    }

    $self->{'loginFailed'} = 0;
    $self->send($LOG_IN, sprintf("%s %s%c",$user,$pass,0));

    while (!$self->{'loggedIn'} && !$self->{'failedLogins'}) {
        my ($type,$len,$packet) = $self->NextPacket();
        $self->Dispatch($type,$len,$packet);
    }
    if ($self->{'loggedIn'}) {
        $self->locateMe();
        while(!defined($self->{'me'})) {
            my ($type,$len,$packet) = $self->NextPacket();
            $self->Dispatch($type,$len,$packet);
        }
    }
    return $self->{'loggedIn'};
}

sub splitPackets
{
    my $self = shift;

    my $found;
    do {
        $found = 0;
        if (length($self->{'buffer'}) > 3) {
            my $len = unpack('v',substr($self->{'buffer'},1,2))-1;
            if (length($self->{'buffer'}) >= $len+2) {
                my $type = substr($self->{'buffer'},0,1);
                my $data = substr($self->{'buffer'},3,$len);
                push(@{$self->{'packets'}},[$type,$len,$data]);
                $self->{'buffer'} = substr($self->{'buffer'},$len+3);
                $found = 1;
                ($self->{'debug'} & $DEBUG_PACKETS) &&
                    $self->Log("Read Data: ".$self->packetAsHex($len.$type.$data));
                ($self->{'debug'} & $DEBUG_TYPES) &&
                    $self->Log("Read packet '".$ClientCommandsByID{$type}."'");
            }
        }
    } while($found);
}

sub readBuffer
{
    my $self = shift;

    my $n = ($#{$self->{'pmQueue'}} > 9) ? 9 : $#{$self->{'pmQueue'}};
    while($n >= 0) {
        my $msg = shift(@{$self->{'pmQueue'}});
        $self->send($SEND_PM,$msg);
        $n--;
    }

    my $rin = ""; my $rout;
    vec($rin, fileno($self->{'socket'}), 1) = 1;
    my $nfound = select($rout=$rin, undef, undef, 0.34);
    if ($nfound) {
        my $buf;
        my $ok = recv($self->{'socket'},$buf,1024,0);
        if (!defined($ok)) {
            $self->Log("recv() failed !");
            return undef;
        }
        my $n = length($buf);
        if ($n > 0) {
            $self->{'buffer'} .= $buf;
            my $nBuf = length($self->{'buffer'});
        }
        return 1;
    }
    return 0;
}

sub NextPacket
{
    my $self = shift;

    $self->keepAlive(0);
    if ($#{$self->{'packets'}} == -1) {
        $self->readBuffer();
        $self->splitPackets();
    }
    if ($#{$self->{'packets'}} >= 0) {
        my $next              = shift @{$self->{'packets'}};
        my ($type,$len,$data) = @{$next};
        (return $type,$len,$data);
    }
    return (undef,undef,undef);
}

sub Dispatch
{
    my $self = shift;
    my ($type,$len,$data) = @_;
    my $ret = undef;

    defined($type) || return undef;

    $self->{'nRcvdPackets'} += 1;

    my $typeStr = $ClientCommandsByID{$type};
    defined($typeStr) || confess "bad packet type in Dispatch";
    my $fn = $self->can($typeStr);
    if (defined($fn)) {
        if ($self->{'debug'} & $DEBUG_TYPES) {
            my $n = $self->{'nRcvdPackets'};
            $self->Log("Dispatching packet($n) '".$typeStr."'");
        }
        $ret = &{$fn}($self,$type,$len,$data);
    }
    else {
        ($self->{'debug'} & $DEBUG_TYPES) &&
            $self->Log("Unhandled packet '".$typeStr."'");
    }
    $self->keepAlive(0);

    return $ret;
}

sub crntMap
{
    my $self = shift;

    return $self->{'Map'}->{'name'};
}

return 1;

