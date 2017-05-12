
package Games::EternalLands::Map;

use strict;
use Carp;
use Data::Dumper;
use Games::EternalLands::MapHelper ':all';
use vars qw(@ISA);

our $VERSION = '0.04';

sub setOccupied
{
    my $self = shift;
    my ($actor) = @_;

return 0;

    if (!defined($actor)) {
        carp("Actor is undefined");
        return 0;
    }
    if (!defined($actor->{'xpos'}) || !defined($actor->{'ypos'})) {
        carp("Actor has undefined location");
        return 0;
    }
    my $loc = $actor->{'xpos'}.",".$actor->{'ypos'};
    if ($self->{'actorsByLoc'}->{$loc} ne $actor) {
        carp("Map says another actor is at ($loc) !\n");
        return 0;
    }
    $self->{'actorsByLoc'}->{$loc} = $actor;
    return 1;
}

sub setVacant
{
    my $self = shift;
    my ($actor) = @_;

    my $loc = $self->{'xpos'}.",".$self->{'ypos'};
    if ($self->{'actorsByLoc'}->{$loc} != $actor) {
        carp("Map says actor is not at ($loc) !\n");
        return 0;
    }
    delete $self->{'actorsByLoc'}->{$loc};
    return 1;
}

sub distance($$$$$)
{
    my $self = shift;

    my ($x1,$y1,$x2,$y2) = @_;

    my $x = ($x1-$x2);
    my $y = ($y1-$y2);

    return sqrt($x*$x+$y*$y);
}

sub getObjectLocation
{
    my $self = shift;
    my ($id) = @_;

    my $obj = $self->{'3dByID'}->{$id};

    my ($x,$y) = (undef,undef);
    if (defined($obj)) {
        $x = int($obj->{'x_pos'}*2);
        $y = int($obj->{'y_pos'}*2);
    }
    return ($x,$y);
}

sub objects
{
    my $self = shift;

    my @objs = keys(%{$self->{'3dByID'}});

    return wantarray ? @objs : \@objs;
}

sub parseMapHeader($)
{
    my ($buf) = @_;

    my %mapHdr;

    $mapHdr{'file_sig'}             = substr($buf,0,4);
    $mapHdr{'tile_map_x_len'}       = unpack('V',substr($buf,4,4));
    $mapHdr{'tile_map_y_len'}       = unpack('V',substr($buf,8,4));
    $mapHdr{'tile_map_offset'}      = unpack('V',substr($buf,12,4));
    $mapHdr{'height_map_offset'}    = unpack('V',substr($buf,16,4));
    $mapHdr{'obj_3d_struct_len'}    = unpack('V',substr($buf,20,4));
    $mapHdr{'obj_3d_no'}            = unpack('V',substr($buf,24,4));
    $mapHdr{'obj_3d_offset'}        = unpack('V',substr($buf,28,4));
    $mapHdr{'obj_2d_struct_len'}    = unpack('V',substr($buf,32,4));
    $mapHdr{'obj_2d_no'}            = unpack('V',substr($buf,36,4));
    $mapHdr{'obj_2d_offset'}        = unpack('V',substr($buf,40,4));
    $mapHdr{'lights_struct_len'}    = unpack('V',substr($buf,44,4));
    $mapHdr{'lights_no'}            = unpack('V',substr($buf,48,4));
    $mapHdr{'lights_offset'}        = unpack('V',substr($buf,52,4));
    $mapHdr{'dungeon'}              = ord(substr($buf,56,1));
    $mapHdr{'res_2'}                = ord(substr($buf,57,1));
    $mapHdr{'res_3'}                = ord(substr($buf,58,1));
    $mapHdr{'res_4'}                = ord(substr($buf,59,1));
    $mapHdr{'ambient_r'}            = unpack('f',substr($buf,60,4));
    $mapHdr{'ambient_g'}            = unpack('f',substr($buf,64,4));
    $mapHdr{'ambient_b'}            = unpack('f',substr($buf,68,4));
    $mapHdr{'particles_struct_len'} = unpack('V',substr($buf,72,4));
    $mapHdr{'particles_no'}         = unpack('V',substr($buf,76,4));
    $mapHdr{'particles_offset'}     = unpack('V',substr($buf,80,4));
    $mapHdr{'reserved_8'}           = unpack('V',substr($buf,84,4));
    $mapHdr{'reserved_9'}           = unpack('V',substr($buf,88,4));
    $mapHdr{'reserved_10'}          = unpack('V',substr($buf,92,4));
    $mapHdr{'reserved_11'}          = unpack('V',substr($buf,96,4));
    $mapHdr{'reserved_12'}          = unpack('V',substr($buf,100,4));
    $mapHdr{'reserved_13'}          = unpack('V',substr($buf,104,4));
    $mapHdr{'reserved_14'}          = unpack('V',substr($buf,108,4));
    $mapHdr{'reserved_15'}          = unpack('V',substr($buf,112,4));
    $mapHdr{'reserved_16'}          = unpack('V',substr($buf,116,4));
    $mapHdr{'reserved_17'}          = unpack('V',substr($buf,120,4));

    return \%mapHdr;
}

sub parse3Dobj
{
    my ($buf) = @_;

    my %obj;

    $obj{'file_name'} = unpack('Z*',substr($buf,0,80));
    $obj{'x_pos'}     = unpack('f',substr($buf,80,4));
    $obj{'y_pos'}     = unpack('f',substr($buf,84,4));
    $obj{'z_pos'}     = unpack('f',substr($buf,88,4));
    $obj{'x_rot'}     = unpack('f',substr($buf,92,4));
    $obj{'y_rot'}     = unpack('f',substr($buf,96,4));
    $obj{'z_rot'}     = unpack('f',substr($buf,100,4));
    $obj{'self_list'} = ord(substr($buf,104,1));
    $obj{'blended'}   = ord(substr($buf,105,1));
    $obj{'r'}         = unpack('f',substr($buf,106,4));
    $obj{'g'}         = unpack('f',substr($buf,110,4));
    $obj{'b'}         = unpack('f',substr($buf,114,4));
    $obj{'reserved'}  = unpack('C*',substr($buf,118,24));

    return \%obj;
}

sub new
{
    my $class = shift;
    my $self  = {};
    bless($self, $class);

    my ($fname,$elDir) = @_;
    my ($mapHdrBuf,$tileMapBuf,$hghtMapBuf);

    if (!defined($elDir)) {
        print STDERR "elDir not defined, so no maps\n";
        return undef;
    }

    open(FP,"$elDir/$fname") || confess "Could not open map file $elDir/$fname";

    (read(FP,$mapHdrBuf,124) == 124) || confess "Could not read map header: $!\n";

    my $mapHdr = parseMapHeader($mapHdrBuf);
    my $wdth   = $mapHdr->{'tile_map_x_len'};
    my $hght   = $mapHdr->{'tile_map_y_len'};

    (read(FP,$tileMapBuf,$wdth*$hght) == $wdth*$hght)  || die "Could not read tileMap for '$fname'";
    undef $tileMapBuf;

    $wdth *= 6;
    $hght *= 6;
    $self->{'width'}  = $wdth;
    $self->{'height'} = $hght;
    my $hMapSize = $wdth*$hght;
    my $hMapBuf;
    (read(FP,$hMapBuf,$hMapSize) == $hMapSize) ||
        confess "Could not read Height Map for '$fname'";
    $self->{'hMap'} = $hMapBuf;

    my $rMapSize = $hMapSize;
    $self->{'rMap'} = sprintf("%".$rMapSize."s","");
    findRegions($self->{'hMap'},$self->{'rMap'},$wdth,$hght);

    my $obj3dBuf;
    for(my $i=0; $i<$mapHdr->{'obj_3d_no'}; $i++) {
        my $obj3dSize = $mapHdr->{'obj_3d_struct_len'};
        (read(FP,$obj3dBuf,$obj3dSize) == $obj3dSize) || confess "Could not read 3D object";
        $self->{'3dByID'}->{$i} = parse3Dobj($obj3dBuf);
    }

    $self->{'wdth'} = $wdth;
    $self->{'hght'} = $hght;
    $self->{'actorsByLoc'} = {};
    $fname =~ s%^.*/([^/]+)\.elm%$1%;
    $self->{'name'} = $fname;

    return $self;
}

return 1;
