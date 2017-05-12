package Games::EternalLands::Bot;

use strict;
use Carp qw(confess cluck carp);
use IO::Socket;
use POSIX;
use YAML;
use Games::EternalLands::Client;
use Games::EternalLands::MapHelper ':all';
use Data::Dumper;
use vars qw(@ISA);

@ISA = qw(Games::EternalLands::Client);

use Games::EternalLands::Constants qw(:Debug :TypeContainers);

our $VERSION = '0.04';

my $ACTOR_TYPE_NPC = 2;

################################################


################################################

sub getHeight
{
    my $self = shift;
    my ($x,$y) = @_;

    my $hMap = $self->{'Map'}->{'hMap'};
    my $wdth = $self->{'Map'}->{'width'};
    my $hght = $self->{'Map'}->{'height'};

    return Games::EternalLands::MapHelper::getZ($hMap,$wdth,$hght,$x,$y);
}

sub randomLocation
{
    my $self = shift;

    my ($x,$y,$h);
    my $width  = $self->{'Map'}->{'width'};
    my $height = $self->{'Map'}->{'height'};
    do {
        $x = int(rand($width));
        $y = int(rand($height));
        $h = $self->getHeight($x,$y);
    } while ($h == 0);

    return [$x,$y];
}

sub send
{
    my $self = shift;
    my ($cmd,$data) = @_;

    if (defined($ActiveCommands{$cmd})) {
        $self->{'lastUsedMapObject'} = undef;
    }
    $self->SUPER::send($cmd,$data);
}

sub saveKnowledge
{
    my $self = shift;

    if (defined($self->{'knowledgeFile'})) {
        my $tmp = $self->{'knowledgeFile'}.".tmp";
        YAML::DumpFile($tmp, $self->{'knowledge'});
        rename($tmp,$self->{'knowledgeFile'});
    }
}

sub rememberActor($$)
{
    my $self = shift;
    my ($new) = @_;

    my $name = lc($new->{'name'});
    if (!defined($name)) {
        confess "Actors name is not defined";
        return undef;
    }

    $self->{'knowledge'}->{'actors'}->{$name} = {
        'name' => $name,
        'map'  => $new->{'map'},
        'x'    => $new->{'xpos'},
        'y'    => $new->{'ypos'},
    };
    $self->saveKnowledge();

    if ($self->{'debug'} & $DEBUG_TEXT) {
        my $name = $new->{'name'} || 'undef';
        my $map  = $new->{'map'}  || 'undef';
        my $x    = $new->{'xpos'} || 'undef'; 
        my $y    = $new->{'ypos'} || 'undef';
        $self->Log("Remembering Actor '$name' at $map($x,$y)");
    }
}


sub getNPCLocation
{
    my $self = shift;
    my ($name) = @_;

    my $npc = $self->{'knowledge'}->{'actors'}->{lc($name)};

    if (wantarray) {
        return defined($npc) ? ($npc->{'map'},$npc->{'x'},$npc->{'y'}) : (undef,undef,undef);
    }
    else {
        return defined($npc) ? [$npc->{'map'},$npc->{'x'},$npc->{'y'}] : undef;
    }
}

sub rememberExit($$)
{
    my $self = shift;
    my ($new) = @_;

    my $id = $new->{'id'};
    if (!defined($id)) {
        confess("exit id is not defined !");
        return undef;
    }
    my $from = $new->{'from'};
    if (!defined($from)) {
        confess("exit from is not defined !");
        return undef;
    }

    my $exit = $self->{'knowledge'}->{'exitsByMap'}->{$from}->{$id} || {};
    map {$exit->{$_} = $new->{$_}} (keys %$new);
    $self->{'knowledge'}->{'exitsByMap'}->{$from}->{$id} = $exit;

    if ($self->{'debug'} & $DEBUG_TEXT) {
        my $to   = $exit->{'to'}   || 'undef';
        my $x    = $exit->{'x'}    || 'undef';
        my $y    = $exit->{'y'}    || 'undef';
        $self->Log("Remembering exit($id) from $from to $to($x,$y)");
    }
}

sub rememberHarvest($$)
{
    my $self = shift;
    my ($new) = @_;

    my $id = $new->{'id'};
    if (!defined($id)) {
        confess "id of harvest is not defined";
        return undef;
    }
    my $map = $new->{'map'};
    if (!defined($map)) {
        confess "map of harvest is not defined";
        return undef;
    }

    my $harv = $self->{'knowledge'}->{'harvByMap'}->{$map}->{'byID'}->{$id} || {};
    map {$harv->{$_} = $new->{$_}} (keys %$new);
    $self->{'knowledge'}->{'harvByMap'}->{$map}->{'byID'}->{$id} = $harv;

    if (my $name = $new->{'name'}) {
        $name =~ s/\.\s*$//;
        $new->{'name'} = lc($name);

        my $found  = 0;
        my $hList = $self->{'knowledge'}->{'harvByMap'}->{$map}->{'byName'}->{$name} || [];
        foreach my $h (@{$hList}) {
            if ($h eq $harv) {
                $found = $1;
                last;
            }
        };
        if (! $found) {
            push(@{$hList},$harv);
            $self->{'knowledge'}->{'harvByMap'}->{$map}->{'byName'}->{$name} = $hList;
        }
    }

    if ($self->{'debug'} & $DEBUG_TEXT) {
        my $name = $harv->{'name'} || "'unkown'";
        $self->Log("Remembering harvest($id) on $map is a $name");
    }
}

sub getExitDetails($$$)
{
    my $self = shift;
    my ($map,$id) = @_;

    if (!defined($map)) {
        $map = $self->crntMap();
    }

    (exists $self->{'knowledge'}->{'exitsByMap'}->{$map}) || return undef;
    return $self->{'knowledge'}->{'exitsByMap'}->{$map}->{$id};
}

sub connectedMaps
{
    my $self = shift;
    my ($map) = @_;

    if (!defined($map)) {
        $map = $self->crntMap();
    }
    my %maps;
    my $exits = $self->{'knowledge'}->{'exitsByMap'}->{$map};
    if (defined($exits)) {
        foreach my $e (values %$exits) {
            if (defined($e->{'to'})) {
                $maps{$e->{'to'}} = 1;
            }
        }
    }
    my @maps = keys(%maps);
    if (wantarray) {
        return @maps;
    }
    return ($#maps >= 0) ? \@maps : undef;
}

sub knownMaps
{
    my $self = shift;

    my %Maps;

    foreach my $m (keys %{$self->{'knowledge'}->{'exitsByMap'}}) {
        $Maps{$m} = 1
    }
    foreach my $m (keys %{$self->{'knowledge'}->{'harvByMap'}}) {
        $Maps{$m} = 1
    }
    return (keys %Maps);
}

sub allHarvestables
{
    my $self = shift;
    my ($map) = @_;

    if (!defined($map)) {
        $map = $self->crntMap();
    }
    if (my $byID = $self->{'knowledge'}->{'harvByMap'}->{$map}->{'byID'}) {
        return keys(%$byID);
    }
    return wantarray ? () : undef;
}

sub findHarvest
{
    my $self = shift;
    my ($map,$name) = @_;

    if (!defined($map)) {
        $map = $self->crntMap();
    }

    my $hList = undef;
    my $byMap = $self->{'knowledge'}->{'harvByMap'};
    if (exists $byMap->{$map}->{'byName'}->{$name}) {
        $hList = $byMap->{$map}->{'byName'}->{$name};
    }
    if (wantarray) {
        return defined($hList) ? @$hList : ();
    }
    return $hList;
}

sub eatThese
{
    my $self = shift;
    my @eatList = @_;

    $self->{'eatList'} = \@eatList;
}

sub eatSomething
{
    my $self   = shift;
    my ($what) = @_;

    my $eatList = defined($what) ? $what : $self->{'eatList'};
    if ($self->{'lastEat'} < time()-90) {
        $self->{'lastEat'} = time();
        foreach my $what (@$eatList) {
           if ($self->qtyOnHand(lc($what)) > 0) {
               $self->Log("Eating $what");
               $self->useInventoryItem(lc($what));
               return 1;
           }
        }
    }
    return 0;
}

sub findExit
{
    my $self = shift;
    my ($map,$fn) = @_;

    my @mList = defined($map) ? ($map) : $self->knownMaps();

    my @result;
    foreach my $m (@mList) {
        my $byMap = $self->{'knowledge'}->{'exitsByMap'};
        if (exists $byMap->{$map}) {
            foreach my $e (keys %{$byMap->{$map}}) {
                if (defined($fn)) {
                    &{$fn}($byMap->{$map}->{$e}) && push(@result,$byMap->{$map}->{$e});
                }
                else {
                    push(@result,$byMap->{$map}->{$e});
                }
            }
        }
    }
    return wantarray ? @result : \@result;
}

sub harvest
{
    my $self = shift;
    my ($id) = @_;

    $self->SUPER::harvest($id);
    $self->{'harvesting'} = {
        'map' => $self->crntMap(),
        'id' => $id,
    };
}

sub getHarvestables
{
    my $self = shift;

    my @tmp = ();
    my $h = $self->{'Map'}->{'harvestables'};

    return wantarray ? @$h : $h;
}

sub ADD_NEW_ACTOR
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $actor = $self->SUPER::ADD_NEW_ACTOR($type,$len,$data);
    if ($actor->{'kind'} eq $ACTOR_TYPE_NPC) {
        $self->rememberActor($actor);
    }
    elsif ($actor->{'id'} == $self->{'my_id'}) {
        if (my $exit = $self->{'lastUsedMapObject'}) {
            $exit->{'toX'} = $actor->{'xpos'};
            $exit->{'toY'} = $actor->{'ypos'};
            $self->rememberExit($exit);
            $self->{'lastUsedMapObject'} = undef;
            $self->saveKnowledge();
        }
    }
}

sub ADD_NEW_ENHANCED_ACTOR
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $actor = $self->SUPER::ADD_NEW_ENHANCED_ACTOR($type,$len,$data);
    if ($actor->{'kind'} eq $ACTOR_TYPE_NPC) {
        $self->rememberActor($actor);
    }
    elsif ($actor->{'id'} == $self->{'my_id'}) {
        if (my $exit = $self->{'lastUsedMapObject'}) {
            $exit->{'toX'} = $actor->{'xpos'};
            $exit->{'toY'} = $actor->{'ypos'};
            $self->rememberExit($exit);
            $self->{'lastUsedMapObject'} = undef;
            $self->saveKnowledge();
        }
    }
}

# Try to kil the actor specified
# Returns 1 - actor has been killed
#         0 - actor escaped us
#     undef - we are trying to kill it
sub killActor
{
    my $self = shift;
    my ($id) = @_;

    my $actor = $self->{'actorsByID'}->{$id};
    defined($actor) || return 0;

    my $me = $self->{'me'};

    my $dist = $self->distanceTo($actor->{'xpos'},$actor->{'ypos'});
    if ($dist >= 4) {
        ($actor->{'inCombat'}) && return 0;  # too far away for us to be attacking it
        $self->moveCloseTo([$actor->{'xpos'},$actor->{'ypos'}],2);
        return undef;
    }
    if ($me->{'inCombat'} || $actor->{'inCombat'}) {
        return undef;
    }
    if ($actor->{'dead'} || ($actor->{'stats'}->{'mp'}->[0] <= 0)) {
        return 1;
    }
    $self->attackActor($actor->{'id'});
    return undef;
}

sub RAW_TEXT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $text = $self->SUPER::RAW_TEXT($type,$len,$data);
    if ($text =~ m/^You need to wear a\s+(\S.*\S)\s+in order to harvest this item/) {
        $self->{'harvesting'}->{'wear'} = $1;
        $self->rememberHarvest($self->{'harvesting'});
        $self->saveKnowledge();
    }
    elsif ($text =~ m/^You started to harvest\s+(\S.*\S)$/) {
        my $name = lc($1); $name =~ s/\.$//;
        $self->{'harvesting'}->{'name'} = $name;
        $self->rememberHarvest($self->{'harvesting'});
        $self->saveKnowledge();
    }
    elsif ($text =~ m/^You stopped harvesting/) {
        $self->{'harvesting'} = undef;
    }
    elsif ($text =~ m/^Go to the doorstep.*click.*to get/i) {
        if (my $exit = $self->{'lastUsedMapObject'}) {
            $exit->{'msg'} = $text;
            $self->rememberExit($exit);
            $self->{'lastUsedMapObject'} = undef;
            $self->saveKnowledge();
        }
    }
    elsif ($text =~ m/The door is locked/i) {
        if (my $exit = $self->{'lastUsedMapObject'}) {
            $exit->{'msg'} = $text;
            $self->rememberExit($exit);
            $self->{'lastUsedMapObject'} = undef;
            $self->saveKnowledge();
        }
    }
}

###########################################################
#
###########################################################

sub Advertise
{
    my $self = shift;

    my $toSell  = $self->{'itemsToSell'};
    my @forSale = (keys %{$toSell});
    @forSale    = sort {$toSell->{$a}->[2] <=> $toSell->{$b}->[2]} @forSale;
    my $item    = $forSale[0];
    my $qty     = $self->qtyInStock($item);
    my $price   = $toSell->{$item}->[1];

    if ($qty > 0) {
        $self->Say('@@3 I am selling '."$qty $item for $price"."gc each");
    }

    $toSell->{$item}->[2] = time();
    if (defined($self->{'sellingFile'})) {
        YAML::DumpFile($self->{'sellingFile'}, $self->{'itemsToSell'});
    }
}

sub handleHelp
{
    my $self = shift;
    my ($user) = @_;

    my $help = $self->isAdmin($user) ? $self->{'adminhelp'} : $self->{'help'};
    if (defined($help)) {
        foreach my $line (@{$help}) {
            $self->sendPM($user,"$line");
        }
    }
}

sub handleDump
{
    my $self = shift;
    my ($user) = @_;

    print STDERR Dumper($self);
}

sub handleInv
{
    my $self = shift;
    my ($user,$item_re) = @_;

    my @items = keys %{$self->{'itemsToSell'}};
    if (defined($item_re)) {
        @items = grep(/$item_re/, @items);
    }
    my $n = 0;
    foreach my $name (@items) {
        my $onHand = $self->qtyOnHand($name);
        if ($onHand > 0) {
            my $qty = $self->qtyInStock($name);
            if ($qty > 0) {
                my $price     = $self->{'itemsToSell'}->{$name}->[1];
                $self->sendPM($user,"$qty $name at ".$price."gc each");
                $n++;
            }
        }
    }
    if ($n == 0) {
        $self->sendPM($user,"I am not selling anything at the moment");
    }
}

sub handleListWant
{
    my $self = shift;
    my ($user) = @_;

    foreach my $name (keys %{$self->{'IWant'}}) {
        my $qty = $self->{'IWant'}->{$name};
        $self->sendPM($user,"I want $qty $name");
    }
}

sub handleListBuySell
{
    my $self = shift;
    my ($user,$action) = @_;

    my $list = ($action eq "sell") ? $self->{'itemsToSell'} : $self->{'itemsToBuy'};

    my @items = keys %{$list};
    foreach my $name (@items) {
        my $qty    = $list->{$name}->[0];
        my $price  = $list->{$name}->[1];
        $self->sendPM($user,"$qty $name at ".$price."gc each");
    }
}

sub handleDoNotSell
{
    my $self = shift;
    my ($user,$item) = @_;

    if (defined($self->{'itemsToSell'}->{$item})) {
        undef $self->{'itemsToSell'}->{$item};
        if (defined($self->{'sellingFile'})) {
            YAML::DumpFile($self->{'sellingFile'}, $self->{'itemsToSell'});
        }
    }
}

sub handleUpdateSell
{
    my $self = shift;
    my ($user,$qty,$item,$price) = @_;
    $self->{'itemsToSell'}->{$item} = [$qty,$price,0];
    if (defined($self->{'sellingFile'})) {
        YAML::DumpFile($self->{'sellingFile'}, $self->{'itemsToSell'});
    }
}

sub handleUpdateBuy
{
    my $self = shift;
    my ($user,$qty,$item,$price) = @_;
    $self->{'itemsToBuy'}->{$item} = [$qty,$price,0];
    if (defined($self->{'buyingFile'})) {
        YAML::DumpFile($self->{'buyingFile'}, $self->{'itemsToBuy'});
    }
}

sub handleBuy
{
    my $self = shift;
    my ($user,$qty,$name) = @_;

    $self->tradeUserOk($user) || return;

    $name =~ s/\s{2,}/ /g;
    my $sell = $self->{'itemsToSell'}->{$name};
    if (!defined($sell)) {
        $self->sendPM($user,"Sorry, I don't have any $name");
        return;
    }
    my $nSell = $self->qtyInStock($name);
    if ($nSell < $qty) {
        $self->sendPM($user,"Sorry, I only have ".$nSell." $name");
        return;
    }
    my $price = ceil($qty * $sell->[1]);
    $self->sendPM($user,"$qty $name will cost you ".$price."gc");
    $self->{'IWant'}->{'gold coins'} += $price;
    $self->{'mySells'}->{$name} += $qty;

    $self->tradeObject($qty,$name);
}

sub handleSell
{
    my $self = shift;
    my ($user,$qty,$name) = @_;

    $self->tradeUserOk($user) || return;

    $name =~ s/\s{2,}/ /g;
    my $buy = $self->{'itemsToBuy'}->{$name};
    if (!defined($buy)) {
        $self->sendPM($user,"Sorry, I am not buying $name");
        return;
    }
    my $nBuy = $self->qtyToBuy($name);
    if ($nBuy < $qty) {
        $self->sendPM($user,"Sorry, I am only buying ".$nBuy." $name");
        return;
    }
    my $price = floor($qty * $buy->[1]);
    $self->sendPM($user,"I will pay $price"."gc for $qty $name");
    $self->{'IWant'}->{$name} += $qty;
    $self->{'myBuys'}->{$name} += $qty;

    $self->tradeObject($price,'gold coins');
}

sub adminCmds
{
    my $self = shift;
    my ($user,$msg) = @_;

    if ($msg =~ m/^\s*list\s+stock\s*$/i) { #
        $self->handleListStock($user);
    }
    elsif ($msg =~ m/^\s*list\s+sells{0,1}\s*$/i) { #
        $self->handleListBuySell($user,"sell");
    }
    elsif ($msg =~ m/^\s*list\s+buys{0,1}\s*$/i) { #
        $self->handleListBuySell($user,"buy");
    }
    elsif ($msg =~ m/^\s*tradeing\s+(on|off)/i) { #
        $self->{'canTrade'} = ($1 eq 'on');
        $self->sendPM($user,"Trading is now $1");
    }
    elsif ($msg =~ m/^\s*list\s+wants{0,1}\s*$/i) { #
        $self->handleListWant($user);
    }
    elsif ($msg =~ m/give\s+me\s+(\d+)\s+(\w.*\S)\s*$/i) {
        $self->handleGiveMe($user,$1,lc($2));
    }
    elsif ($msg =~ m/^\s*do\s+not\s+sell\s+(\w.*\w)\s*$/i) {
        $self->handleDoNotSell($user,$1);
    }
    elsif ($msg =~ m/^\s*do\s+not\s+buy\s+(\w.*\w)\s*$/i) {
        $self->handleDoNotBuy($user,$1);
    }
    elsif ($msg =~ m/\s*sell\s+(\d+)\s+(\w.*\S)\s+(for|at)\s+(\d+)gc*/i) {
        $self->handleUpdateSell($user,$1,$2,$4);
    }
    elsif ($msg =~ m/\s*buy\s+(\d+)\s+(\w.*\S)\s+(for|at)\s+(\d+)gc*/i) {
        $self->handleUpdateBuy($user,$1,$2,$4);
    }
    elsif ($msg =~ m/^\s*move\s+to\s+(\d+)\,(\d+)\s*/) {
        $self->moveTo([$1,$2]);
    }
    elsif ($msg =~ m/\s*say\s(\S.*\S)\s*/) {
        $self->Say($1);
    }
    elsif ($msg =~ m/\s*stats\s*$/) {
        $self->handleStats($user);
    }
    elsif ($msg =~ m/\s*touch\s+player\s+(\d+)\s*$/) {
        $self->handleTouchPlayer($1);
    }
    elsif ($msg =~ m/\s*respond\s+to\s+(\d+)\s+with\s+(\d+)\s*$/) {
        $self->respondToNPC($1,$2);
    }
    elsif ($msg =~ m/\s*dump\s+(.*\S)\s*$/) {
        $self->handleDump($user,$1);
    }
    elsif ($msg =~ m/^\s*sto\s*$/) {
        $self->handleSto($user,'.*');
    }
    elsif ($msg =~ m/^\s*sto\s+(.+)$/) {
        $self->handleSto($user,$1);
    }
    else {
        return 0;
    }
    return 1;
}

sub handlePM
{
    my $self = shift;
    my ($user,$msg) = @_;

    my $canTrade = $self->{'canTrade'};

    if ($self->isAdmin($user)) {
        $self->adminCmds($user,$msg) && return;
    }
    if ($msg =~ m/^\s*loc\s*$/i) {
        $self->{'locReply'} = $user;
        $self->locateMe();
    }
    elsif ($msg =~ m/^\s*owner\s*$/i) {
        $self->sendPM($user,$self->{'owner'});
    }
    elsif (($canTrade) && ($msg =~ m/^\s*buy\s+(\d+)\s+(\w.*\w)\s*$/i)) {
        $self->handleBuy($user,$1,lc($2));
    }
    elsif (($canTrade) && ($msg =~ m/^\s*sell\s+(\d+)\s+(\w.*\w)\s*$/i)) {
        $self->handleSell($user,$1,lc($2));
    }
    elsif (($canTrade) && ($msg =~ m/^\s*donate\s+(\d+)\s+(\w.*\w)\s*$/i)) {
        if ($self->tradeUserOk($user)) {
            $self->{'IWant'}->{$2} += $1;
        }
    }
    elsif (($canTrade) && ($msg =~ m/^\s*wanted\s*$/i)) {
        $self->handleWanted($user,undef);
    }
    elsif (($canTrade) && ($msg =~ m/^\s*inv\s+(\w|\w.*\w)\s*$/i)) {
        $self->handleInv($user,$1);
    }
    elsif (($canTrade) && ($msg =~ m/^\s*inv\s*$/i)) {
        $self->handleInv($user,undef);
    }
    elsif ($msg =~ m/^\s*help\s*$/i) {
        $self->handleHelp($user);
    }
    else {
        $self->sendPM($user,"Sorry, I don't understand.");
        $self->sendPM($user,"PM me with HELP for a list of commands");
    }
}

##########################################################################################
# Path finding/following functions
##########################################################################################

sub distance($$$$)
{
    my $self = shift;
    my ($x1,$y1,$x2,$y2) = @_;

    my $x = ($x1 > $x2) ? $x1-$x2 : $x2-$x1;
    my $y = ($y1 > $y2) ? $y1-$y2 : $y2-$y1;

    return ($x > $y) ? $x : $y;
}

sub distanceToObject
{
    my $self = shift;
    my ($id) = @_;

    my ($x,$y) = $self->getObjectLocation($id);

    return $self->distanceTo($x,$y);
}

sub pathDesc
{
    my ($path) = @_;

    my @tmp = ();
    foreach my $p (@$path) {
        my $str = (ref($p) eq "ARRAY") ? "($p->[0],$p->[1])": "($p)";
        push(@tmp, $str);
    }
    my $pathStr = join(' ==> ',@tmp);
    return $pathStr;
}

sub getAllExits
{
    my $self = shift;
    my ($map) = @_;

    my @exits = ();
    my $exits = $self->{'knowledge'}->{'exitsByMap'}->{$map};
    if (defined($exits)) {
        @exits = keys(%$exits);
    }
    return wantarray ? @exits : \@exits;
}

# $from = {
#    'map' => ?
#    'loc' => [x,y]
#
# }
#
#

sub exitOk
{
    my ($exit) = @_;

    defined($exit->{'to'}) || return 0;
    ($exit->{'to'} ne 'undef')  || return 0;
    defined($exit->{'toX'}) || return 0;
    defined($exit->{'toY'}) || return 0;
    return 1;
}

sub findPathToMap
{
    my $self = shift;
    my ($from,$to,$delta) = @_;

    my %Visited;
    my @queue;

    my $id = "MAP,$from->[0],$from->[1],$from->[2]";
    my ($crntID,$crntCost,$parent) = (undef,undef,undef);
    push(@queue, [$id,0,"NONE"]); # [id,cost,parent]
L:  while(my $next = shift(@queue)) {
        my ($crntMap,$crntX,$crntY);
        ($crntID,$crntCost,$parent) = @$next;
        #print STDERR "Now at $crntID, cost=$crntCost parent=$parent\n";
        my $exitID = undef;
        if ($crntID =~ m/^MAP\,(.+)\,(\d+)\,(\d+)/) {
            ($crntMap,$crntX,$crntY) = ($1,$2,$3);
        }
        elsif ($crntID =~ m/^EXIT\,(.+)\,(\d+)/) {
            my $e = $self->getExitDetails($1,$2);
            ($crntMap,$crntX,$crntY) = ($1,$e->{'fromX'},$e->{'fromY'});
            $exitID = $2;
        }
        else {
            carp("Can't decode my location");
            return undef;
        }
        my $map = $self->getMap($crntMap);
        $Visited{$crntID} = $parent;
        if (defined($exitID)) { # we are at an exit
           my $exit = $self->getExitDetails($crntMap,$exitID);
           if (defined($exit->{'to'}) and defined($exit->{'toX'}) and defined($exit->{'toY'})) {
               my $nextID = "MAP,$exit->{'to'},$exit->{'toX'},$exit->{'toY'}";
               if (!defined($Visited{$nextID})) {
                   push(@queue, [$nextID,$crntCost+10,$crntID]);
                   #print STDERR "We are at an exit - adding $nextID, cost=$crntCost+10, parent=$crntID to queue\n";
               }
            }
        }
        elsif ($crntMap eq $to->[0]) {
            #print STDERR "We are on the desination map\n";
            my $path = $self->doPathFind($map,$crntX,$crntY,$to->[1],$to->[2],$delta);
            if (defined($path)) {
                #print STDERR "Destination is reachable\n";
                my $n = $#{$path};
                if ($n < $delta) {
                    #print STDERR "We have arrived\n";
                    last L;
                }
                my $nextID = "MAP,$to->[0],$path->[$n]->[0],$path->[$n]->[1]";
                if (!defined($Visited{$nextID})) {
                    my $cost = $crntCost+$n+1;
                    push(@queue, [$nextID,$cost,$crntID]);
                    #print STDERR "adding $nextID, cost=$cost, parent=$crntID to queue\n";
                }
            }
            else {
                #print STDERR "Dstination not reachble - exit map\n";
                my @exits = $self->getAllExits($crntMap);
                @exits = map {$self->getExitDetails($crntMap,$_)} @exits;
                @exits = grep { exitOk($_) } @exits;
                foreach my $e (@exits) {
                    my $nextID = "EXIT,$e->{'from'},$e->{'id'}";
                    if (!defined($Visited{$nextID})) {
                        my $path = $self->doPathFind($map,$crntX,$crntY,$e->{'fromX'},$e->{'fromY'},10);
                        if (defined($path)) {
                            my $cost   = $crntCost + $#{$path}+1;
                            push(@queue, [$nextID,$cost,$crntID]);
                            #print STDERR "Adding exit $nextID, cost=$cost, parent=$crntID to queue\n";
                        }
                    }
                }
            }
        }
        else {
            #print STDERR "Just arrived on a map\n";
            my @exits = $self->getAllExits($crntMap);
            @exits = map {$self->getExitDetails($crntMap,$_)} @exits;
            @exits = grep { exitOk($_) } @exits;
            foreach my $e (@exits) {
                my $nextID = "EXIT,$e->{'from'},$e->{'id'}";
                if (!defined($Visited{$nextID})) {
                    my $path = $self->doPathFind($map,$crntX,$crntY,$e->{'fromX'},$e->{'fromY'},10);
                    if (defined($path)) {
                        my $cost   = $crntCost + $#{$path}+1;
                        push(@queue, [$nextID,$cost,$crntID]);
                        #print STDERR "Adding exit $nextID, cost=$cost, parent=$crntID to queue\n";
                    }
                }
            }
        }
        @queue = sort { $a->[1] <=> $b->[1] } @queue;
    }
    my @path;
    while($crntID ne "NONE") {
        unshift(@path,$crntID);
        $crntID = $Visited{$crntID};
    }
    return \@path;
}

# Take path returned by the findPath* calls and
# 1. convert from "x,y" to [x,y]
# 2. chop it up in to  a series of steps, where
# each step is <= 6
sub shortenPath
{
    my $self = shift;
    my ($path) = @_;

    my @path;
    my ($newX,$newY)   = (-1,-1);
    my ($pathX,$pathY) = (-1,-1);

    my $p1 = shift @$path;
    if (defined($p1)) {
        ($newX,$newY) = ($pathX,$pathY) = @$p1;
        foreach my $p (@{$path}) {
            ($newX,$newY) = @$p;
            if ($self->distance($pathX,$pathY,$newX,$newY) > 6) {
                push(@path,[$newX,$newY]);
                ($pathX,$pathY) = ($newX,$newY);
            }
        }
        if ($newX != $pathX or $newY != $pathY) {
            push(@path,[$newX,$newY]);
        }
    }
    ($self->{'debug'} & $DEBUG_PATH) &&
        $self->Log("Shortened path: ".pathDesc(\@path));

    return \@path;
}

sub doPathFind
{
    my $self = shift;
    my ($map,$fromX,$fromY,$toX,$toY,$delta) = @_;

    defined($fromX)    || cluck("fromX is not defined");
    defined($fromY)    || cluck("fromY is not defined");
    defined($toX)      || cluck("toX is not defined");
    defined($toY)      || cluck("toY is not defined");
    ($toX =~ m/^\d+$/) || cluck("toX='$toX' which is not numeric");
    ($toY =~ m/^\d+$/) || cluck("toY='$toY' which is not numeric");
    ($toX =~ m/^\d+$/) || cluck("toX='$toX' which is not numeric");
    ($toY =~ m/^\d+$/) || cluck("toY='$toY' which is not numeric");

    ($self->{'debug'} & $DEBUG_PATH) &&
        $self->Log("findPath from ($fromX,$fromY) to ($toX,$toY) (delta=$delta)");
    my $hMap = $map->{'hMap'};
    my $wdth = $map->{'width'};
    my $hght = $map->{'height'};
    my $path = findPathFromTo($hMap,$wdth,$hght,$fromX,$fromY,$toX,$toY,$delta);

    return $path
}

sub findPathClose($$$$)
{
    my $self = shift;
    my ($from,$to,$delta) = @_;

    my $path = $self->doPathFind($self->{'Map'},$from->[0],$from->[1],$to->[0],$to->[1],$delta);
    if (defined($path)) {
        ($self->{'debug'} & $DEBUG_PATH) &&
            $self->Log("Detailed path: ".pathDesc($path));
        $path = $self->shortenPath($path);
    }
    return $path;
}

sub findPath($$$)
{
    my $self = shift;
    my ($from,$to) = @_;

    return $self->findPathClose($from,$to,0);
}

sub stop
{
    my $self = shift;

    $self->{'path'} = undef;
    $self->{'destination'} = [-1-1,0];

    return 1;
}

sub moveCloseTo($$$)
{
    my $self = shift;
    my ($to,$delta) = @_;

    my $me = $self->{'me'};
    if (!defined($me)) {
        $self->Log("Can't move - 'me' is not defined");
        return undef;
    }
    my ($fromX,$fromY) = ($me->{'xpos'},$me->{'ypos'});
    if (!defined($fromX) or !defined($fromY)) {
        $self->Log("Can't move - my location is not defined");
        return undef;
    }
    my $path = $self->findPathClose([$fromX,$fromY],$to,$delta);
    $self->followPath($path);

    return $path;
}

sub moveTo($$)
{
    my $self = shift;
    my ($to) = @_;

    return $self->moveCloseTo($to,0);
}

sub followPath($$)
{
    my $self = shift;
    my ($path) = @_;

    if (!defined($path)) {
        $self->Log("Not following undefined path !");
        return undef;
    }
    my $n = $#{$path};
    if ($n < 0) {
        $self->Log("Not following empty path !");
        return undef;
    }
    $self->{'path'} = $path;
    my ($x,$y)      = ($path->[$n]->[0],$path->[$n]->[1]);
    $self->{'destination'} = [$x,$y,0];
    $self->SUPER::moveTo($path->[0]->[0],$path->[0]->[1]);
}

##########################################################################################
#
##########################################################################################

sub useMapObject
{
    my $self = shift;
    my ($id) = @_;

    if (my $prev = $self->{'lastUsedMapObject'}) {
        my ($x,$y) = ($prev->{'x'},$prev->{'y'});
        my $to     = $prev->{'to'};
        if (!defined($x) || !defined($y) || !defined($to)) {
            $prev->{'timedOut'} = 1;
        }
        $self->rememberExit($prev);
        $self->saveKnowledge();
    }
    $self->{'timeLastObjectUsed'} = time();
    $self->{'lastUsedMapObject'} = {
        'from' => $self->crntMap(),
        'id' => $id,
    };
    $self->SUPER::useMapObject($id);
}

sub getObjectLocation
{
    my $self = shift;
    my ($id) = @_;

    my $obj = $self->{'Map'}->{'3dByID'}->{$id};
    my ($x,$y) = (int($obj->{'x_pos'}*2),int($obj->{'y_pos'}*2));

    return wantarray ? ($x,$y) : [$x,$y];
}

sub CHANGE_MAP($$$$)
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    $self->SUPER::CHANGE_MAP($type,$len,$data);

    my $map = $self->crntMap();
    if (my $exit = $self->{'lastUsedMapObject'}) {
        $exit->{'to'} = $map;
        $self->rememberExit($exit);
    }
    my $exits = $self->{'Map'}->{'entrable'};
    foreach my $id (@$exits) {
        if (!defined($self->getExitDetails($map,$id))) {
            my ($x,$y) = $self->getObjectLocation($id);
            $self->rememberExit({'id'=>$id,'from'=>$map,'fromX'=>$x,'fromY'=>$y});
        }
    }
    my $harv = $self->{'Map'}->{'harvestables'};
    foreach my $h (@$harv) {
        if (!defined($self->{'knowledge'}->{'harvByMap'}->{$map}->{'byID'}->{$h})) {
            my ($x,$y) = $self->getObjectLocation($h);
            $self->rememberHarvest({map=>$map, x=>$x, y=>$y, id=>$h});
        }
    }
    $self->saveKnowledge();
}

sub sellToNPC($$$)
{
    my $self = shift;
    my ($qty,$item) = @_;

    my $crntNPC = $self->{'crntNPC'};
    (defined $crntNPC) || return 0;
    (exists $self->{'NPCchat'}->{$crntNPC}) || return undef;
    (exists $self->{'NPCchat'}->{$crntNPC}->{'waiting'}) && return undef;

    my $opts = $self->{'NPCchat'}->{$crntNPC}->{'options'};
    defined($opts) || return undef;

    if (defined($opts->{'sell'})) {
        $self->respondToNPC($opts->{'sell'});
        return undef;
    }
    elsif (defined($opts->{$item})) {
        $self->respondToNPC($opts->{$item});
        return undef;
    }
    else {
        my $sellQty = 0;
        foreach my $o (keys %{$opts}) {
            if (($o =~ m/^\d+$/) and ($o > $sellQty and $o <= $qty)) {
                $sellQty = $o;
            }
        }
        ($sellQty > 0) || return 0;
        $self->respondToNPC($opts->{$sellQty});
        return $sellQty;
    }
}

sub openStorage($)
{
    my $self = shift;

    my $crntNPC = $self->{'crntNPC'};
    (defined $crntNPC) || return 0;
    (exists $self->{'NPCchat'}->{$crntNPC}) || return 0;
    my $opts = $self->{'NPCchat'}->{$crntNPC}->{'options'};
    (defined $opts) || return undef;

    if (exists $opts->{'open storage'}) {
        $self->respondToNPC($opts->{'open storage'});
        $self->{'waitingForStorage'} = 1;
        return undef;
    }
    return (! $self->{'waitingForStorage'});
}

sub nextMove($)
{
    my $self = shift;

    my $path = $self->{'path'};
    if (!defined($path)) {
        return undef;
    }
    if ($#{$path} == -1) {
        $self->{'path'} = undef;
        $self->{'destination'} = [-1,-1,0];
        return undef;
    }
    my $me = $self->{'me'};
    if (!defined($me)) {
        return undef;
    }
    my $next = $path->[0];
    my $d = $self->distanceTo($next->[0],$next->[1]);
    ($self->{'debug'} & $DEBUG_PATH) &&
        $self->Log("Next location ($next->[0],$next->[1]), distance=$d");
    if ($d <= 1) {
        shift (@{$self->{'path'}});
        if ($next = $path->[0]) {
            ($self->{'debug'} & $DEBUG_PATH) &&
                $self->Log("Asking server to move me to ($next->[0],$next->[1])");
            $self->SUPER::moveTo($next->[0],$next->[1]);
        }
    }
    elsif ($me->{'lastMoved'}+2 < time()) {
        my ($x,$y,$delta) = @{$self->{'destination'}};
        ($self->{'debug'} & $DEBUG_PATH) &&
            $self->Log("Timeout on moving - calling moveCloseTo([$x,$y],$delta)");
        $self->moveCloseTo([$x,$y],$delta);
    }
}

sub Dispatch($$$$)
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $ret;
    if (defined($type)) {
        $ret = $self->SUPER::Dispatch($type,$len,$data); 
    }
    if (defined($self->{'path'})) {
        $self->nextMove($self->{'path'});
    }

    return $ret;
}
    
################################################################
# TRADE RELATED CALLBACKS                                      #
################################################################

sub GET_TRADE_ACCEPT
{
    my $self = shift;
    my ($type,$len,$data) = @_;

    my $who = unpack('C', $data);
    if ($who) {
        $self->{'tradeOk'} = $self->chkTrade($self->{'thereTrades'},$self->{'IWant'});
        if ($self->{'tradeOk'}) {
            $self->SUPER::GET_TRADE_ACCEPT($type,$len,$data); 
        }
    }
}

################################################################
# INVENTORY RELATED CALLBACKS                                  #
################################################################

sub readHelp
{
    my $self = shift;
    my ($fname) = @_;
    my @lines = ();

    if (defined($fname)) {
        if (open(FP,$fname)) {
            while(<FP>) {
                chomp $_;
                push(@lines, $_);
            }
        }
        else {
            $self->Log("Coud not open $fname for reading\n");
        }
    }
    return \@lines;
}

sub new
{
    my $class  = shift;
    my ($self) = Games::EternalLands::Client->new(@_);
    bless($self, $class);

    $self->{'admin'}             = [];

    $self->{'helpFile'}          = undef;
    $self->{'adminHelpFile'}     = undef;
    $self->{'help'}              = undef;
    $self->{'adminhelp'}         = undef;
    $self->{'owner'}             = "No owner defined";
    $self->{'location'}          = "No location defined";

    $self->{'buyingFile'}        = undef;
    $self->{'sellingFile'}       = undef;
    $self->{'itemsToSell'}       = {};
    $self->{'itemsToBuy'}        = {};
    $self->{'lastMsgAt'}         = time(); # no msg on startup
    $self->{'msgInterval'}       = 20;     # minutes
    $self->{'pmHandlers'}        = {};
    $self->{'destination'}       = [-1,-1,0];

    $self->{'IWant'}             = {};
    $self->{'tradingWith'}       = undef;
    $self->{'myTrades'}          = {};
    $self->{'mySells'}           = {};
    $self->{'thereTrades'}       = {};
    $self->{'tradeOk'}           = 0;
    $self->{'tradeAccepted'}     = 0;
    $self->{'stoByID'}           = {};
    $self->{'stoByName'}         = {};
    $self->{'waitingForStorage'} = 0;
    $self->{'eatList'}           = [];
    $self->{'lastEat'}           = 0;

    $self->{'pktMemory'}     = [];
    $self->{'memoryRegex'}   = '^NO$';
    $self->{'maxPktMemory'}  = 0;

    @_ = $self->processArgs(@_);

    $self->{'help'} = $self->readHelp($self->{'helpFile'});
    $self->{'adminhelp'} = $self->readHelp($self->{'adminHelpFile'});

    if (defined($self->{'sellingFile'}) and (-e $self->{'sellingFile'})) {
        $self->{'itemsToSell'} = YAML::LoadFile($self->{'sellingFile'});
    }
    if (defined($self->{'buyingFile'}) and (-e $self->{'buyingFile'})) {
        $self->{'itemsToBuy'}  = YAML::LoadFile($self->{'buyingFile'});
    }
    if (defined($self->{'knowledgeFile'}) and (-e $self->{'knowledgeFile'})) {
        $self->{'knowledge'}  = YAML::LoadFile($self->{'knowledgeFile'});
    }

    return $self;
}

sub setMemory
{
    my $self = shift;
    my ($max,$regex) = @_;

    $self->{'memoryRegex'}   = $regex;
    $self->{'maxPktMemory'}  = $max;
}

sub forget
{
    my $self = shift;

    $self->{'pktMemory'} = [];
}

sub inspectBag
{
    my $self = shift;
    my ($bagID) = @_;

    my $bag = $self->{'bagsByID'}->{$bagID};
    if (!defined($bag)) {
        $self->Log("Inspecting non existant bag $bagID");
        return {};
    }
    my $items = $bag->{'items'};
    if (!defined($items)) {
        return undef;
    }
    foreach my $pos (keys %$items) {
        if (!defined($items->{$pos}->{'name'})) {
            return undef;
        }
    }
    return $items;
}

sub pickUp
{
    my $self = shift;
    my ($bagID,$pickup) = @_;

    my $bag = $self->{'bagsByID'}->{$bagID};
    if (!defined($bag)) {
        $self->Log("Picking up from non existsant bag($bagID)");
        return 0;
    }
    if (!defined($bag->{'items'})) {
        $self->Log("Picking up from empty bag($bagID)");
        return 0;
    }
    foreach my $pos (keys %{$bag->{'items'}}) {
        my $name = $bag->{'items'}->{$pos}->{'name'};
        if (!defined($name)) {
            $self->Log("item in bag with no name !");
            next;
        }
        my $qty  = defined($pickup) ? $pickup->{$name} : 100000;
        if (defined($qty)) {
            my $inBag = $bag->{'items'}->{$pos}->{'quantity'};
            if ($inBag < $qty) {
                $qty = $inBag;
            }
            $self->SUPER::pickUp($bag,$pos,$qty);
        }
    }
    return 1;
}

sub contains
{
    my $self = shift;
    my ($hash,$item) = @_;

    foreach my $pos (keys %{$hash}) {
         if ($hash->{$pos}->{'name'} eq $item) {
             return $hash->{$pos};
         }
    }
    return undef;
}

sub isAdmin
{
    my $self = shift;
    my ($user) = @_;

    foreach my $admin (@{$self->{'admins'}}) {
        if ($user eq $admin) {
            return 1;
        }
    }
    return 0;
}

sub tradeUserOk
{
    my $self = shift;
    my ($user) = @_;

    my $tradeWith = $self->{'tradeWith'};
    if (!defined($tradeWith)) {
        $self->sendPM($user,"Start trading with me before asking for items.");
        return 0 ;
    }
    if  ($tradeWith ne $user) {
        $self->sendPM($user,"Sorry, I am already trading with someone else.");
        $self->sendPM($user,"Please try again in while.");
        return 0;
    }
    return 1;
}


###########################################################
#
###########################################################

sub invIsComplete
{
    my $self = shift;
    foreach my $pos (keys %{$self->{'invByPos'}}) {
        if (!defined($self->{'invByPos'}->{$pos}->{'name'})) {
            return 0; }
    }
    return 1;
}

sub qtyToBuy
{
    my $self = shift;
    my ($name) = @_;

    my $qty    = $self->{'itemsToBuy'}->{$name}->[0];
    my $price  = $self->{'itemsToBuy'}->{$name}->[1];
    my $gc     = $self->qtyOnHand('gold coins');

    return (floor($price * $qty) > $gc) ? floor($gc/$price) : $qty;
}

sub qtyInStock
{
    my $self = shift;
    my ($name) = @_;

    my $onHand = $self->qtyOnHand($name);
    if ($onHand <= 0) {
        return 0;
    }
    if (!defined($self->{'itemsToSell'}->{$name})) {
        return 0;
    }
    my $toSell = $self->{'itemsToSell'}->{$name}->[0] || 0;
    if (defined($self->{'myTrades'}->{$name})) {
         $toSell -= $self->{'myTrades'}->{$name}->{'quantity'};
         $onHand -= $self->{'myTrades'}->{$name}->{'quantity'};
    }
    return ($toSell > $onHand) ? $onHand : $toSell;
}

sub qtyOnHand
{
    my $self = shift;
    my ($name) = @_;

    if (my $byName = $self->{'invByName'}->{lc($name)}) {
        my $qty = 0;
        foreach my $pos (values %$byName) {
            $qty += $pos->{'quantity'};
        }
        return $qty;
    }
    return 0;
}

sub chkTrade
{
    my $self = shift;
    my ($trades,$wants) = @_;


    my $user        = $self->{'tradeWith'};
    my %thereTrades = %{$self->{'thereTrades'}}; # Copy so we can modify it
    my $IWant       = $self->{'IWant'};

    # check if what we want matches what we were given
    my $tradeOk = 1;
    foreach my $want (keys %{$IWant}) {
        my $qty = $IWant->{$want};
        my $item = $self->contains(\%thereTrades,$want);
        if (defined($item)) {
            $qty -= $item->{'quantity'};
            delete $thereTrades{$item->{'pos'}};
        }
        if ($qty > 0) {
            $self->sendPM($user,"I still need $qty more $want");
            $tradeOk = 0;
        }
        elsif ($qty < 0) {
            $qty *= -1;
            $self->sendPM($user,"you have given me $qty too many $want");
            $tradeOk = 0;
        }
    }
    foreach my $pos (keys %thereTrades) {
        my $name = $thereTrades{$pos}->{'name'};
        $self->sendPM($user,"$name is not something you are giving/selling to me");
        $tradeOk = 0;
    }

    return $tradeOk;
}

sub Say
{
    my $self = shift;
    my ($msg) = @_;

    $self->SUPER::Say($msg);
    if ($msg =~ m/^\#beam me/i) {
        $self->{'lastUsedMapObject'} = undef;
        $self->{'path'} = undef;
    }
}

sub handleWanted
{
    my $self = shift;
    my ($user,$item_re) = @_;

    my @items = keys %{$self->{'itemsToBuy'}};
    if (defined($item_re)) {
        @items = grep(/$item_re/, @items);
    }
    my $n = 0;
    foreach my $name (@items) {
        my $qty = $self->qtyToBuy($name);
        if ($qty > 0) {
            my $price = $self->{'itemsToBuy'}->{$name}->[1];
            $self->sendPM($user,"$qty $name at ".$price."gc each");
            $n++;
        }
    }
    if ($n == 0) {
        $self->sendPM($user,"I am not buying anything at the moment");
    }
}

sub handleListStock
{
    my $self = shift;
    my ($user) = @_;

    foreach my $name (keys %{$self->{'invByName'}}) {
        my $qty = $self->qtyOnHand($name);
        $self->sendPM($user,"I have $qty $name");
    }
}

sub handleDoNotBuy
{
    my $self = shift;
    my ($user,$item) = @_;

    if (defined($self->{'itemsToBuy'}->{$item})) {
        undef $self->{'itemsToBuy'}->{$item};
        if (defined($self->{'buyingFile'})) {
            YAML::DumpFile($self->{'buyingFile'}, $self->{'itemsToBuy'});
        }
    }
}

sub handleGiveMe
{
    my $self = shift;
    my ($user,$qty,$name) = @_;

    $self->tradeUserOk($user) || return;
     
    my $give = $self->qtyOnHand($name);
    if ($give <= 0) {
        $self->sendPM($user,"Sorry, I don't have any $name");
    }
    else {
        if ($qty > $give) {
            $self->sendPM($user,"Sorry, I only have ".$give->{'quantity'}." $name");
        }
        else {
            $self->tradeObject($qty,$name);
        }
    }
}

sub handleStats
{
    my $self = shift;

    my ($user) = @_;

    foreach my $stat ('har','att','def','alc','mag','pot','sum','oa') {
        my $xp_cur  = $self->{'experience'}->{$stat}->[0];
        my $xp_base = $self->{'experience'}->{$stat}->[1];
        my $cur  = $self->{'skills'}->{$stat}->[0];
        my $base = $self->{'skills'}->{$stat}->[1];
        my $msg = sprintf("| %3s: %2d/%2d    %d/%d",$stat,$cur,$base,$xp_cur,$xp_base);
        $self->sendPM($user,$msg);
    }
    foreach my $stat ('mp','ep','food','carry') {
        my $cur  = $self->{'stats'}->{$stat}->[0];
        my $base = $self->{'stats'}->{$stat}->[1];
        my $msg = sprintf("| %5s: %2d/%2d", $stat, $cur, $base);
        $self->sendPM($user,$msg);
    }
    $self->sendPM($user,"Filled Inventory Slots: ".$self->{"nCarry"});
    $self->sendPM($user,"Filled Equipment Slots: ".$self->{"nEquip"});
}

sub handleSto
{
    my $self = shift;
    my ($user,$re) = @_;

    $self->Say('#sto ');
    $self->{'tellSTO'} = $user;
    $self->{'stoRE'} = $re;
}

sub distanceTo
{
    my $self = shift;
    my ($toX,$toY) = @_;

    defined($toX) || confess "x not defined in distanceTo(x,y)";
    defined($toX) || confess "y not defined in distanceTo(x,y)";

    my $me             = $self->{'me'};
    my ($fromX,$fromY) = ($me->{'xpos'},$me->{'ypos'});

    (defined($fromX) && defined($fromY)) || confess "my location not defined in distanceTo()";

    my ($x,$y)         = (abs($fromX-$toX),abs($fromY-$toY));
    my $d              = ($x > $y) ? $x : $y;

    return $d;
}

sub arrived
{
    my $self = shift;

    return (!defined($self->{'path'}) and !defined($self->{'pathState'}));
}

sub NextPacket
{
    my ($self) = shift;

    my ($type,$len,$data) = $self->SUPER::NextPacket();

    if ($self->{'debug'} & $DEBUG_PATH) {
        my ($map,$x,$y) = $self->myLocation();
        my $loc = (defined($x) and defined($y)) ? "($x,$y)" : "(undef,undef)";
        $self->Log("I am on '$map' at $loc");
    }
    my $food = $self->{'stats'}->{'food'}->[0];
    if (defined($food) and $food < 5) {
        $self->eatSomething(undef);
    }
    if (my $prev = $self->{'lastUsedMapObject'}) {
        if ($self->{'timeLastObjectUsed'} < time()-40) {
            my ($x,$y) = ($prev->{'x'},$prev->{'y'});
            my $to     = $prev->{'to'};
            if (!defined($x) || !defined($y) || !defined($to)) {
                $prev->{'timedOut'} = 1;
            }
            $self->rememberExit($prev);
            $self->{'lastUsedMapObject'}  = undef;
            $self->saveKnowledge();
        }
    }
    return ($type,$len,$data);

}

################################################################
# TRADE RELATED CALLBACKS                                      #
################################################################

sub GET_TRADE_EXIT
{
    my $self = shift;

    if ($self->{'tradeAccepted'} == 2) {
        foreach my $name (keys %{$self->{'mySells'}}) {
            $self->{'itemsToSell'}->{$name}->[0] -= $self->{'mySells'}->{$name};
        }
        foreach my $name (keys %{$self->{'myBuys'}}) {
            $self->{'itemsToBuy'}->{$name}->[0] -= $self->{'myBuys'}->{$name};
        }
    }
    $self->{'IWant'}         = {};
    $self->{'mySells'}       = {};
    $self->{'myBuys'}        = {};

    if (defined($self->{'sellingFile'})) {
        YAML::DumpFile($self->{'sellingFile'}, $self->{'itemsToSell'});
    }
    $self->SUPER::GET_TRADE_EXIT(@_); 
}

################################################################
# INVENTORY RELATED CALLBACKS                                  #
################################################################

sub processArgs
{
    my $self = shift;
    my @args  = @_;
    my @notUsed = ();

    while(my $arg = shift @args) {
        if ($arg eq '-server') {
            $self->{'server'} = shift @args; }
        elsif ($arg eq '-port') {
            $self->{'port'} = shift @args; }
        elsif ($arg eq '-admins') {
            my $admins = shift @args;
            my @admins = split(',',$admins);
            $self->{'admins'} = \@admins;
        }
        elsif ($arg eq '-knowledgeFile') {
            $self->{'knowledgeFile'} = shift @args; }
        elsif ($arg eq '-buyingFile') {
            $self->{'buyingFile'} = shift @args; }
        elsif ($arg eq '-sellingFile') {
            $self->{'sellingFile'} = shift @args; }
        elsif ($arg eq '-helpFile') {
            $self->{'helpFile'} = shift @args; }
        elsif ($arg eq '-adminHelpFile') {
            $self->{'adminHelpFile'} = shift @args; }
        elsif ($arg eq '-msgInterval') {
            $self->{'msgInterval'} = shift @args; }
        elsif ($arg eq '-owner') {
            $self->{'owner'} = shift @args; }
        elsif ($arg eq '-location') {
            $self->{'location'} = shift @args; }
        else {
            push(@notUsed,$arg);
        }
    }
    return @notUsed;
}

return 1;
