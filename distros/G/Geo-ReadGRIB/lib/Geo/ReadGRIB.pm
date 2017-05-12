#--------------------------------------------------------------------------
# Geo::ReadGRIB
#
# - A Perl extension that gives read access to GRIB "GRIdded Binary"
#   format Weather data files.
#
# - Copyright (C) 2006 by Frank Cox
#--------------------------------------------------------------------------

package Geo::ReadGRIB;

use 5.006_001;
use strict;
use warnings;
use IO::File;
use Carp;

our $VERSION = 1.4;

use Geo::ReadGRIB::PlaceIterator;

my $LIB_DIR = "./";

# try to find wgrib.exe
foreach my $inc (@INC) {
    if ( -e "$inc/Geo/wgrib.exe" ) {
        $LIB_DIR = "$inc/Geo";
        last;
    }
}

unless ( -e "$LIB_DIR/wgrib.exe" ) {
    die "CAN'T CONTINUE: Path to  wgrib.exe not found";
}

## Set some signal handlers to clean up temp files in case of interruptions
#  it does this by calling exit(0) which will run the END block

$SIG{INT} = $SIG{QUIT} = $SIG{TERM} = sub {
    print "ReadGRIB attempting cleanup...\n";
    exit(0);
};

END {
    unlink glob("wgrib.tmp.*");
}

#--------------------------------------------------------------------------
# new()
#--------------------------------------------------------------------------
sub new {

    my $class = shift;
    my $gFile = shift;
    unless ( defined $gFile ) {
        croak "new(): Usage: Geo::ReadGRIB->new(GRIB_FILE)";
    }
    my $self = {};
    bless $self, $class;

    $self->{fileName} = $gFile;
    $self->{DEBUG}    = 0;
    $self->backflip( 0 );

    $self->openGrib();

    return $self;
}

#--------------------------------------------------------------------------
# openGrib()
#
# Open grib file using wgrib.exe and extract header data
# 
# Version 1.0 added a call to _getCatalog() here to get all critical
# header data
#--------------------------------------------------------------------------
sub openGrib {

    use Time::Local;

    my $self = shift;

    my $tmp = $self->tempfile();
    my $cmd = "\"$LIB_DIR\"/wgrib.exe \"$self->{fileName}\" -d 1 -4yr -PDS10 -GDS10 -text -nh -o $tmp";

    my $header = qx($cmd);
    unlink $tmp;

    if ($?) {
        croak "Error in $cmd: $?";
    }

    my @inv = split /:/, $header;

    my ( $arg, $val, %head );

    $head{recNum} = $inv[0];
    $head{offset} = $inv[1];
    $head{name}   = $inv[3];
    $head{level}  = $inv[11];
    $head{fcst}   = $inv[12];

    foreach my $invel (@inv) {
        chomp $invel;

        # print "$invel \n";
        if ( $invel =~ /=/ ) {
            ( $arg, $val ) = split /=/, $invel;
            $val =~ s/^\s+//;
            $head{$arg} = $val;

            # print "    ($arg,$val) \n";
        }
    }

    foreach ( sort keys %head ) {
        #     print " $_: $head{$_}\n";
        $self->{$_} = $head{$_};
    }


    # reduce date string to 'time' format
    my ( $yr, $mo, $day, $hr ) = unpack 'A4A2A2A2', $self->{d};
    $self->{TIME} = timegm( 0, 0, $hr, $day, $mo - 1, $yr - 1900 );

    $self->{LAST_TIME} = $self->{THIS_TIME} = $self->{TIME};

    $self->parseGDS( $head{GDS10} );

    # if this isn't a lat/long grid we can't go on
    if ( $self->{GRID_TYPE} != 0 ) {
        croak "GDS byte 6 not 0: Only latitude/longitude grids are currently supported";
    }

    $self->_getCatalog;

    return;
}

#--------------------------------------------------------------------------
# getCatalogVerbose() DEPRECATED. Use getFullCatalog() instead
#
# This method is now redundent and just calls getFullCatalog() and sets
# an error.
#--------------------------------------------------------------------------
sub getCatalogVerbose {
    my $self = shift;
    $self->error( "Method getCatalogVerbose() DEPRECATED and is now redundant  "
        . "in Geo::ReadGRIB V0.98 and above. Use getFullCatalog() instead" );
    $self->getFullCatalog();
    return 1;
}


#--------------------------------------------------------------------------
#  getCatalog( ) DEPRECATED. It now does nothing but set an error.
#   Do not use in new code and please remove it from old code.
#
#  The catalog is now fetched in openGRIB() and this method dose not need
#  to be called.
#--------------------------------------------------------------------------
sub getCatalog {
    my $self = shift;
    $self->error( "Method getCatalog DEPRECATED and is no longer needed  "
        . "in Geo::ReadGRIB V1.0 and above" );
    return 1;
}

#--------------------------------------------------------------------------
# _getCatalog()
#--------------------------------------------------------------------------
sub _getCatalog {

    my $self = shift;

    my $tmp = $self->tempfile();
    my $cmd = "\"$LIB_DIR\"/wgrib.exe \"$self->{fileName}\" -o $tmp";

    my @cat = qx($cmd);
    unlink $tmp;

    if ($?) {
        croak "Error in \$cmd: $?";
    }

    my $timeRange = $self->TR;

    my ( @line, $offset );
    foreach (@cat) {
        @line = split /:/;
        $line[8] =~ s/P1=//;
        $line[9] =~ s/P2=//;
        if ( $timeRange == 0 ) {
            $offset = $line[8];
        }
        elsif ( $timeRange == 10 ) {
            $offset = ($line[8] * 256) + $line[9];
        }
        else {
            croak "Time Range flag $timeRange not yet supported. Please ask the Geo::ReadGRIB maintainer to add support for GRIB files like this";
        }

        $offset = $offset * 3600 + $self->{TIME};
        $self->{LAST_TIME} = $offset if $offset > $self->{LAST_TIME};
        $self->{catalog}->{ $offset }->{ $line[3] } = $line[0];
    }

    return;
}

#--------------------------------------------------------------------------
# getFullCatalog()
#
# recovers the verbose catalog which has text discriptions
# of data items.
#--------------------------------------------------------------------------
sub getFullCatalog{

    my $self = shift;

    my $tmp = $self->tempfile();
    my $cmd = "\"$LIB_DIR\"/wgrib.exe -v \"$self->{fileName}\" -o $tmp";

    my @cat = qx($cmd);
    unlink $tmp;

    if ($?) {
        croak "Error in \$cmd: $?";
    }

    my @line;
    foreach (@cat) {
        chomp;
        @line = split /:/;
        $line[7] =~ s/"//g;
        $self->{v_catalog}->{ $line[3] } = $line[7];
    }
    return;
}

#--------------------------------------------------------------------------
# parseGDS()
#
# Assumes gds is dumped in "decimal" (-GDS10)
#--------------------------------------------------------------------------
sub parseGDS {

    my $self = shift;
    my $gds  = shift;

    $gds =~ s/^\s+//;

    my @GDS = split /\s+/, $gds;

    $self->{GRID_TYPE} = $GDS[5];

    my @slice = @GDS[ 6, 7 ];
    $self->Ni( $self->toDecimal( \@slice ) );

    @slice = @GDS[ 8, 9 ];
    $self->Nj( $self->toDecimal( \@slice ) );

    @slice = @GDS[ 10, 11, 12 ];
    $self->La1( $self->toDecimal( \@slice ) / 1000 );

    @slice = @GDS[ 13, 14, 15 ];
    $self->Lo1( $self->toDecimal( \@slice ) / 1000 );

    my @rc_flags = split '', sprintf "%08b", $GDS[16];
    
    # if INCREMENTS_FLAG is true get increments from GDS else calculate
    $self->{INCREMENTS_FLAG} = $rc_flags[0]; 

    @slice = @GDS[ 17, 18, 19 ];
    $self->La2( $self->toDecimal( \@slice ) / 1000 );

    @slice = @GDS[ 20, 21, 22 ];
    $self->Lo2( $self->toDecimal( \@slice ) / 1000 );

    @slice = @GDS[ 23, 24 ];
    if ( ($slice[0] == $slice[1] and $slice[0] == 255) and not $self->{INCREMENTS_FLAG} ) {
        $self->LoInc( $self->calInc( $self->Lo1, $self->Lo2, $self->Ni ) );
    }
    else {
        $self->LoInc( $self->toDecimal( \@slice ) / 1000 );
    }

    @slice = @GDS[ 25, 26 ];
    if ( ($slice[0] == $slice[1] and $slice[0] == 255) and not $self->{INCREMENTS_FLAG} ) {
        $self->LaInc = $self->calInc( $self->La1, $self->La2, $self->Nj );
    }
    else {
        $self->LaInc( $self->toDecimal( \@slice ) / 1000 );
    }

    my @scan_mode_flags = split '', sprintf "%08b", $GDS[27];

    # if SN_SCAN_FLAG true data runs in numeric order south-north
    # elce data runs north-south
    $self->sn_scan_flag( $scan_mode_flags[1] );

    if ( $scan_mode_flags[0] ) {
        croak "Scan mode -i not yet supported. Please contact the Geo::ReadGRIB maintainer to add support for GRIB files that scan east to west";
    }

    if ( $scan_mode_flags[2] ) {
        croak "Scan mode (J,I) not yet supported. Please contact the Geo::ReadGRIB maintainer to add support for GRIB files where adjacent points are consecutive in the j direction (north/south)";
    }

    # Calculate effective Lo where thay are shifted west to 0 degrees.
    # This will be used for finding data offset and for checking for 
    # out of range args where ranges may cross long 0
    $self->{eLo2} =  $self->Lo2;
    $self->{eLo1} =  $self->Lo2 - ($self->Ni -1) * $self->LoInc;
    $self->{Lo_SHIFT} = 0 - $self->{eLo1};

    return;
}

#--------------------------------------------------------------------------
# sn_scan_flag( [flag] ) - getter/setter
#--------------------------------------------------------------------------
sub sn_scan_flag {
    my ( $self, $flag ) = @_;
    $self->{SN_SCAN_FLAG} = $flag if defined $flag;
    return  $self->{SN_SCAN_FLAG};
}

#--------------------------------------------------------------------------
# error( [error message] ) - getter/setter for errors
#--------------------------------------------------------------------------
sub error {
    my ( $self, $error ) = @_;
    $self->{ERROR} = $error if defined $error;
    return  $self->{ERROR};
}

#--------------------------------------------------------------------------
# Lo1( [val] ) - Getter/setter for Lo1
#--------------------------------------------------------------------------
sub Lo1 {
    my ( $self, $flag ) = @_;
    $self->{Lo1} = $flag if defined $flag;
    return  $self->{Lo1};
}

#--------------------------------------------------------------------------
# Lo2( [flag] ) - Getter/setter for Lo2
#--------------------------------------------------------------------------
sub Lo2 {
    my ( $self, $flag ) = @_;
    $self->{Lo2} = $flag if defined $flag;
    return  $self->{Lo2};
}

#--------------------------------------------------------------------------
# LoInc( [flag] ) - Getter/setter for LoInc
#--------------------------------------------------------------------------
sub LoInc {
    my ( $self, $flag ) = @_;
    $self->{LoInc} = $flag if defined $flag;
    return  $self->{LoInc};
}

#--------------------------------------------------------------------------
# La1( [flag] ) - Getter/setter for La1
#--------------------------------------------------------------------------
sub La1 {
    my ( $self, $flag ) = @_;
    $self->{La1} = $flag if defined $flag;
    return  $self->{La1};
}

#--------------------------------------------------------------------------
# TR( [flag] ) - Getter/setter for TR
#--------------------------------------------------------------------------
sub TR {
    my ( $self, $flag ) = @_;
    $self->{TR} = $flag if defined $flag;
    return  $self->{TR};
}

#--------------------------------------------------------------------------
# La2( [flag] ) - Getter/setter for La2
#--------------------------------------------------------------------------
sub La2 {
    my ( $self, $flag ) = @_;
    $self->{La2} = $flag if defined $flag;
    return  $self->{La2};
}

#--------------------------------------------------------------------------
# LaInc( [flag] )-  Getter/setter for LaInc
#--------------------------------------------------------------------------
sub LaInc {
    my ( $self, $flag ) = @_;
    $self->{LaInc} = $flag if defined $flag;
    return  $self->{LaInc};
}

#--------------------------------------------------------------------------
# Ni( [flag] ) - Getter/setter for Ni
#--------------------------------------------------------------------------
sub Ni {
    my ( $self, $flag ) = @_;
    $self->{Ni} = $flag if defined $flag;
    return  $self->{Ni};
}

#--------------------------------------------------------------------------
# Nj( [flag] ) - Getter/setter for Nj
#--------------------------------------------------------------------------
sub Nj {
    my ( $self, $flag ) = @_;
    $self->{Nj} = $flag if defined $flag;
    return  $self->{Nj};
}

#--------------------------------------------------------------------------
# clearError()
# set errors undef
#--------------------------------------------------------------------------
sub clearError {
    my $self = shift;
    undef $self->{ERROR};
}


#--------------------------------------------------------------------------
# validLa( lat )
#
# check if lats are in range and return true if they arr, else false
#--------------------------------------------------------------------------
sub validLa {

    my $self = shift;
    my $lat  = shift;

    if  ( $self->sn_scan_flag ) {
        if ( $lat < $self->La1 or $lat > $self->La2 ) {
            return 0;
        }
    }
    else {
        if ( $lat > $self->La1 or $lat < $self->La2 ) {
            return 0;
        }
    }


    return 1;
}

#--------------------------------------------------------------------------
# validLo( 1ong )
#
# check that longs are in range and return true if they are, else false.
#--------------------------------------------------------------------------
sub validLo {

    my $self = shift;
    my $lo   = shift;

    if  ( $self->sn_scan_flag ) {
        $lo += $self->{Lo_SHIFT};
        if ( $lo > 360 ) {
            $lo -= 360;
        }
 
        $lo /= $self->LoInc;
        if ( $lo < 0 or $lo > $self->Ni ) {
            return 0;
        }
    }
    else {
        if ( $lo < $self->Lo1 or $lo > $self->Lo2 ) {
            return 0;
        }
    }

    return 1;
}

#--------------------------------------------------------------------------
# adjustLong( long )
#
# takes a long and returns a effective long adjusted to the shifted grid
#--------------------------------------------------------------------------
sub adjustLong {

    my $self = shift;
    my $l1   = shift;
}

#--------------------------------------------------------------------------
# toDecimal()
#
# helper method for parseGDS()
#--------------------------------------------------------------------------
sub toDecimal {

    my $self    = shift;
    my $inArray = shift;

    # if the most segnificant bit is one it's negative...
    my $isNeg = 0;
    if ( $$inArray[0] >= 128 ) {
        $isNeg = 1;
        $$inArray[0] -= 128;
    }

    #  print "===== " . $$inArray[0] . " -- " . 2**((@$inArray -1) *8) . "\n";

    my ( $result, $m );
    for ( my $i = @$inArray - 1, my $j = 0 ; $i >= 0 ; $i--, $j++ ) {
        $m = 2**( $j * 8 );
        $result += $$inArray[$i] * $m;
    }

    $result *= -1 if $isNeg;
    return sprintf "%.2d", $result;
}

#--------------------------------------------------------------------------
# dumpit()
#--------------------------------------------------------------------------
sub dumpit {

    my $self = shift;

    use Data::Dumper;
    print Dumper($self);
    return;
}

#--------------------------------------------------------------------------
# calInc( cord1, cord2, points)
#
# finds degrees between grid points given the start and end and
# number of points. If one cord is negative South or west long/lat assumed
#--------------------------------------------------------------------------#
sub calInc {

    my $self = shift;
    my $c1   = shift;
    my $c2   = shift;
    my $pts  = shift;

    my $size;
    if ( $pts == 0 ) {
        $size = 0;
        $self->error( "calInc: \$pts = 0" );
    }
    elsif ( $c1 < 0 or $c2 < 0 ) {

        #     print "$size = (abs($c1) + abs($c2) +1) / $pts;\n";
        $size = ( abs($c1) + abs($c2) + 1 ) / $pts;
    }
    else {

        #     print "$size = (abs($c1 - $c2)) / $pts\n";
        $size = ( abs( $c1 - $c2 ) ) / $pts;
    }
    return sprintf "%.2f", $size;
}

#--------------------------------------------------------------------------
# lalo2offset(lat, long)
#
# converts long/lat pairs in degrees to grib table offset
#--------------------------------------------------------------------------
sub lalo2offset {

    my $self = shift;
    my $lat  = shift;
    my $long = shift;

    
    my $thislong = 0;

    $self->clearError;
    my $out;
    
    if ( $self->sn_scan_flag ) {

        # shift long east until Lo1 = 0 and make sure any long
        # > 360 degrees is moved back into the range of 0 - 360
        $thislong = $long + $self->{Lo_SHIFT};
        if ( $thislong > 360 ) {
            $thislong -= 360;
        }

        $out =  ( ( ( $lat - $self->La1  ) / $self->LaInc ) * $self->Ni ) 
                + ( ($thislong ) / $self->LoInc );
    }
    else {
        $out =  ( ( $self->La1 - $lat ) / $self->LaInc ) * $self->Ni 
                + ( ($long - $self->Lo1 ) / $self->LoInc );
    }
 
    return sprintf "%.0f", sprintf "%.6f", $out;
}

#--------------------------------------------------------------------------
# $plit = $w->extractLaLo( data_types, lat1, long1, lat2, long2, time )
#
#
# data_types is a scalar containing a single data type as a string or
# an array ref of data type strings.
#
# Extracts forecast data for a range of locations from (lat1, long1) to
# (lat2, long2) for the given data_type and time. 
# 
# This will be much faster than repeated calls to extract() because only one
# call to wgrib and just one file open are required.
#
# Returns a Geo::ReadGRIB::PlaceIterator object.
#
# Data is no longer stored in the current object by default as of version 
# 1.4. To turn this behavior back on use the backflip() method;
#
#
# require: lat1 >= lat2 and long1 <= long2 - that is, lat1 is north or lat2
#          and long1 is west of long2 (or is the same as)
#
#--------------------------------------------------------------------------
sub extractLaLo {

    my $self   = shift;
    my $type_s = shift;
    my $lat1   = shift;
    my $long1  = shift;
    my $lat2   = shift;
    my $long2  = shift;
    my $time   = shift;

    my $flipBack = $self->backflip() ? 1 : 0;
    my $DEBUG = $self->{DEBUG} ? 1 : 0;
    my $LoInc = $self->LoInc;

    my @types;
    if ( ref $type_s eq 'ARRAY' ) {
        push @types, @$type_s;
    }
    elsif ( $type_s =~ /\w+/ ) {
        push @types, $type_s;
    }
    else {
        $self->error( "ERROR extractLaLo() \$types required" );
        return;
    }

    my @times = sort keys %{ $self->{catalog} };

    # First see that requested values are in range...
    my ($lo1, $lo2, $la1, $la2) = ($self->Lo1, $self->Lo2, $self->La1, $self->La2, );
    if ( not $lat1 >= $lat2 or not $long1 <= $long2 ) {
        $self->error( "ERROR extractLaLo() require: lat1 >= lat2 and long1 <= long2" );
        return;
    }

    if ( not defined $time ) {
        $self->error( "ERROR extractLaLo() \$time is required " );
        return;
    }

    if ( $time < $self->{TIME} or $time > $self->{LAST_TIME} ) {
        $self->error( "ERROR extractLaLo() \$time \"$time\" out of range " 
        .  scalar gmtime( $times[0] ) . " ($times[0]) to " 
        . scalar gmtime( $times[-1] ) . " ($times[-1])" );
        return;
    }

    if ( not $self->validLa($lat1) or not $self->validLa($lat2) ) {
        $self->error( "extractLaLo(): LAT >$lat1 or $lat2< out of range $la1 to $la2" );
        return;
    }

    if ( not $self->validLo( $long1 ) or not $self->validLo( $long2 ) ) {
        $self->error( "extractLaLo(): LONG: >$long1 or $long2 < out of range $lo1 to $lo2" );
        return;
    }

    my $plit = Geo::ReadGRIB::PlaceIterator->new();

    # if time is given, use nearest time in catalog...
    if ( defined $time ) {
        $self->findNearestTime( $time );
    }

    my ( $dtaLength, $fileDump, $offset, $dump, $record, $lo, $la );
    my $tm = $self->{THIS_TIME};


    for my $type ( @types ) {
        $record = $self->{catalog}->{$tm}->{$type};

        if ( not defined $record ) {
            $self->error( "extractLaLo(): Not a valid type: $type" );
            return 1;
        }

        my $tmp = $self->tempfile();
        my $cmd = "\"$LIB_DIR\"/wgrib.exe \"$self->{fileName}\" -d $record -nh -o $tmp";
        my $res = qx($cmd);
        my $F = IO::File->new( $tmp ) or croak "Can't open temp file";

        # Make sure first offset is smallest for any scanning order 
        my ( $offsetFst, $offsetLst ) = sort {$a <=> $b} ( 
            $self->lalo2offset($lat1, $long1),  $self->lalo2offset($lat2, $long2) );
        $dtaLength = ($offsetLst - $offsetFst +1) * 4;        
        seek $F, $offsetFst * 4, 0;
        read $F, $fileDump, $dtaLength; 

        my ($x, $y);
        $dump = "";
        for ( $la = $lat1, $x = 0 ; $la >= $lat2 ; $la -= $self->LaInc, $x++ ) {
                my $num_lo = sprintf "%d", (($long2 - $long1) / $LoInc) +1;
                $offset = $self->lalo2offset( $la, $long1 ) - $offsetFst;
                my @luck = unpack "f*", substr $fileDump, $offset * 4, 4 * $num_lo;
            for ( $lo = $long1, $y = 0 ; $lo <= $long2 ; $lo += $LoInc, $y++ ) {
                my $dump = shift @luck;
                $dump = defined $dump ? sprintf "%.2f", $dump : 0.00;
                $dump = 0 if $dump eq '';
                $dump = "UNDEF" if $dump > 999900000000000000000;
                print gmtime($tm) . ": $self->{v_catalog}->{$type}  $dump\n" if $DEBUG;
                $self->{data}->{$tm}->{$la}->{$lo}->{$type} = $dump if $flipBack;
                # TODO look into the negative lats with CMS data 
#               $self->{matrix}->{$tm}->{$type}->[$x]->[$y] = $dump if $la >= 0 and $lo >= 0;
                $plit->addData( $tm, $la, $lo, $type, $dump );
            }
        }
        close $F;
        unlink $tmp;
        undef $fileDump;
    }

    return $plit;
}

#--------------------------------------------------------------------------
# backflip( [flag] ) - Getter/setter for the backflip() state.
#
# When true, certain older behaviors return. In version 1.4 this is only the
# storage in the current object of data extracted by extractLaLo(). 
#
# default false 
#--------------------------------------------------------------------------
sub backflip {
    my ( $self, $flag ) = @_;
    $self->{backflip} = $flag if defined $flag;
    return  $self->{backflip};
}

#--------------------------------------------------------------------------- 
# getMatrix({ time => time, type => type }) 
#
# return the array of the extracted region for type and time 
# POSSIBLE FUTURE FUNCTION
#--------------------------------------------------------------------------- 
#sub getMatrix {
#    my	( $self, $r ) = @_;
#    return $self->{matrix}->{ $r->{time} }->{ $r->{type} };
#}

#--------------------------------------------------------------------------
# $plit = extract(data_type, lat, long, [time])
#
# Extracts forecast data for given type and location. Ectracts data for all
# times in file unless a specific time is given in epoch seconds.
#
# Returns a Geo::ReadGRIB::PlaceIterator and extracted data is also
# retained in the ReadGRIB object.
#
# type will be one of the data types in the data
#--------------------------------------------------------------------------
sub extract {

    my $self = shift;
    my $type = shift;
    my $lat  = shift;
    my $long = shift;
    my $time = shift;

    # First see that requested values are in range...
    my ($lo1, $lo2, $la1, $la2) = ($self->Lo1, $self->Lo2, $self->La1, $self->La2, );
    if ( not $self->validLa($lat) ) {
        $self->error( "extract(): LAT >$lat< out of range $la1 to $la2" );
        return;
    }

    if ( not $self->validLo($long) ) {
        $self->error( "extract(): LONG: >$long< out of range $lo1 to $lo2" );
        return;
    }    

    my $offset = $self->lalo2offset( $lat, $long );

    if ( $offset < 0 ) {
        $self->error( "extract(): offset less than zero" );
        return 1;
    }

    $time = 0 unless defined $time;

    if (   $time != 0 and $time < $self->{TIME} 
       or $time > $self->{LAST_TIME} ) {

        my @times = sort keys %{ $self->{catalog} };
        $self->error( "ERROR extract() \$time \"$time\" out of range " 
        . scalar gmtime( $times[0] ) . " ($times[0]) to " 
        . scalar gmtime( $times[-1] ) . " ($times[-1])" );
        return 1;
    }

    # If a time is given find nearest in catalog
    if ( defined $time ) {
        $self->findNearestTime( $time );
    }

    my ( $record, $cmd, $res, $dump );

    unless ( defined $self->{v_catalog}->{$type} ) {
        $self->error( "extract() Type not found: $type" );
        return 1;
    }

    # Give avaiable data for type and offset.
    # All times returned unless $time is given.
    #
    # If record is alredy in $self->{data} use that
    # else go to disk...

    my $plit = Geo::ReadGRIB::PlaceIterator->new();

    $dump = "";
    foreach my $tm ( sort keys %{ $self->{catalog} } ) {
        if ( $time != 0 ) {
            $tm = $self->{THIS_TIME};
        }
 
        $record = $self->{catalog}->{$tm}->{$type};

        if ( not defined $record ) {
            $self->error( "extract(): Not a valid type: $type" );
            return 1;
        }

        my $tmp = $self->tempfile();
        $cmd = "\"$LIB_DIR\"/wgrib.exe \"$self->{fileName}\" -d $record -nh -o $tmp";
        $res = qx($cmd);
        print "$cmd - OFFSET: $offset " . $offset * 4 . " bytes\n"
          if $self->{DEBUG};
        my $F = IO::File->new( "$tmp" ) or croak "Can't open temp file";
        seek $F, $offset * 4, 0;
        read $F, $dump, 4;
        $dump = unpack "f", $dump;
        $dump = sprintf "%.2f", $dump;
        $dump = "UNDEF" if $dump > 999900000000000000000;
        print gmtime($tm) . ": $self->{v_catalog}->{$type}  $dump\n"
          if $self->{DEBUG};
        $self->{data}->{$tm}->{$lat}->{$long}->{$type} = $dump;
        $plit->addData( $tm, $lat, $long, $type, $dump );
        close $F;
        unlink $tmp;
        last if $time != 0;
    }
    return $plit;
}

#--------------------------------------------------------------------------
# findNearestTime( time )
# 
# Find nearest time in catalog...
#--------------------------------------------------------------------------
sub findNearestTime {

    my $self = shift;
    my $time = shift;

    my @times = sort keys %{ $self->{catalog} };

    if ( 1 == @times ) {
        $self->{THIS_TIME} = $times[0];
    }
    else {
        for ( my $i = 0, my $j = 1 ; $j <= @times ; $i++, $j++ ) {
            if ( $time >= $times[$i] and $time <= $times[$j] ) {
                if ( ( $time - $times[$i] ) <= ( $times[$j] - $time ) ) {
                    $self->{THIS_TIME} = $times[$i];
                }
                else {
                    $self->{THIS_TIME} = $times[$j];
                }
                last;
            }
        }
    }
}

#--------------------------------------------------------------------------
# getDataHash()
#
# Returns a hash ref with all the data items in the object.
# This will be all the data extracted from the GRIB file for
# in the life of the object.
#
# The structure is
#
#    $t->{time}->{lat}->{long}->{type}
#--------------------------------------------------------------------------
sub getDataHash {
    my $self = shift;
    return $self->{data};
}


#--------------------------------------------------------------------------
#  clearData( )
#--------------------------------------------------------------------------
sub clearData {
    my $self = shift;
    undef $self->{data};
    return ;
}

#--------------------------------------------------------------------------
# getError()
#
# returns error string from $self->error
#--------------------------------------------------------------------------
sub getError {
    my $self = shift;
    return defined $self->error ? $self->error : undef;
}

#--------------------------------------------------------------------------
# m2ft(meters)
#
# convert meters to feet
#--------------------------------------------------------------------------
sub m2ft {

    my $self = shift;
    my $m    = shift;
    return $m * 3.28;
}

#--------------------------------------------------------------------------
# tempfile()
#
# return a  temp file name
#--------------------------------------------------------------------------
sub tempfile {

    my $self = shift;

    use File::Temp qw(:mktemp);

    my ( $fh, $fn ) = mkstemp("wgrib.tmp.XXXXXXXXX");
    return $fn;
}

#--------------------------------------------------------------------------
# $p = getParam(parm_name)
#
# getParam(param_name) returns a scalar with the value of param_name
# getParam("show") returns a scalar listing published parameter names.
#--------------------------------------------------------------------------
sub getParam {

    my $self = shift;
    my $arg  = shift;

    my @published = qw/TIME LAST_TIME La1 La2 LaInc Lo1 Lo2 LoInc fileName/;

    my $param;
    if ( defined $arg ) {
        if ( $arg =~ /show/i ) {
            $param = "@published";
        }
        elsif ( grep /$arg/, @published ) {
            $param = $self->{$arg};
        }
        else {
            $self->error( "getParam(): $arg - Undefined or unpublished parameter" );
            return 1;
        }
    }
    else {
        $self->error( "getParam(): Usage: getParam(param_name)" );
        return 1;
    }

    return $param;
}

#--------------------------------------------------------------------------
# show()
#
# Returns a scalar containing a string with some selected meta data
# describing the GRIB file.
#--------------------------------------------------------------------------
sub show {

    my $self = shift;
    my $arg  = shift;

    my $param;

    my @published = qw/LAST_TIME La1 La2 LaInc Lo1 Lo2 LoInc TIME fileName/;

    if ( defined $arg ) {
        if ( $arg =~ /show/i ) {
            $param = "@published";
        }
        elsif ( grep /$arg/, @published ) {
            $param = $self->{$arg};
        }
        else {
            $self->error( "show(): $arg - Undefined or unpublished parameter" );
            return 1;
        }
    }
    else {
        my $types;
        foreach ( sort keys %{ $self->{v_catalog} } ) {
            $types .= sprintf "%8s: %s\n", $_, $self->{v_catalog}->{$_};
        }

        my @times = sort keys %{ $self->{catalog} };
        my $t     = scalar gmtime( $times[0] ) . " ($times[0]) to ";
        $t .= scalar gmtime( $times[-1] ) . " ($times[-1])";

        $param = <<"      PARAM";
     
      Locations:
     
      lat: $self->{La1} to $self->{La2}
      long: $self->{Lo1} to $self->{Lo2}
  
      Times:
  
      $t
     
      Types:
      \n$types
      PARAM
    }
    return $param;
}

1;

__DATA__

=pod

=head1 NAME



Geo::ReadGRIB - Perl extension that gives read access to GRIB 1 "GRIdded
Binary" format Weather data files.


=head1 SYNOPSIS

  use Geo::ReadGRIB;
  $w = new Geo::ReadGRIB "grib-file";
  
  $w->getFullCatalog() # only needed for text descriptions and units.
  
  # The object now contains the full inventory of the GRIB file
  # including the "verbose" text description of each parameter
  
  print $w->show(); 
  
  $plit = $w->extract(data_type, lat, long, time);

  # or 

  $plit = $w->extractLaLo(data_type, lat1, long1, lat2, long2, time); 
  
  die $w->getError,"\n" if $w->getError;    # undef if no error

  while (  $place =  $plit->current and $plit->next ) {
      
      # $place is a Geo::ReadGRIB::Place object

      $time       = $place->thisTime;
      $latitude   = $place->lat;
      $longitude  = $place->long;
      $data_types = $place->types; # an array ref of type names
      $data       = $place->data( data_type );

      # do something with each place in the extracted rectangular area
  }


  $data = $w->getDataHash();
  
  # $data contains a hash reference to all grib data extracted
  # by extract() the object in its lifetime.
  #
  # As of Version 1.4 extractLaLo() does not save extracted data to 
  # the object by default and so it will not be returned by getDataHash().
  # Use the backflip() method to bring back this older behavior.
  #  
  # $data->{time}->{lat}->{long}->{data_type} now contains data 
  # for data_type at lat,long and time unless there was an error
  


=head1 DESCRIPTION

Geo::ReadGRIB is an Perl module that provides read access to data 
distributed in GRIB files. Specifically, I wrote it to access NOAA Wavewatch 
III marine weather model forecasts. As of version 0.98_1 Geo::ReadGRIB is known to 
support Canadian Meteorological Center's GEM model GRIB files. It may support
many other GRIB variants which use a rectangular lat/long grid but they have not 
been tested. Please notify the maintainers and let them know if it does or doesn't 
support your files.

Version 0.98 introduced the Geo::ReadGRIB::PlaceIterator class. PlaceIterator
objects are returned by extractLaLo() and extract() and can be used for an 
ordered traversal of the extracted data for a given time. This greatly simplifies 
map image creation and other data analysis tasks. See L<Geo::ReadGRIB::PlaceIterator>
documentation and demo programs in the examples directory.

Wavewatch III GRIB's can currently be found under 

ftp://polar.ncep.noaa.gov/pub/waves/

CMC GRIB datasets currently listed at

http://www.weatheroffice.gc.ca/grib/High-resolution_GRIB_e.html

GRIB stands for "GRIdded Binary" and it's a format developed by the World
Meteorological Organization (WMO) for the exchange of weather product 
information. See for example 

http://www.nco.ncep.noaa.gov/pmb/docs/on388/

for more about the GRIB format.

=head2 wgrib.c

Geo::ReadGRIB uses the C program wgrib to retrieve the GRIB file catalog and
to extract the data. wgrib.c is included in the distribution and will
compile when you make the module. The resulting executable is named wgrib.exe
and should install in the same location as ReadGRIB.pm. ReadGRIB will search
for wgrib.exe at run time and die if it can't find it.

wgrib.c is known to compile and install correctly with Geo::ReadGRIB on 
all common platforms. See the CPAN Testers reports for this module for details.

wgrib.exe creates a file called wgrib.tmp.XXXXXXXXX in the local directory where 
the X's are random chars. The id that runs a program using Geo::ReadGRIB needs
write access to work. This temp file will be removed after use by each method 
calling wgrib.exe

=head1 Methods

=over 4

=item $O = new Geo::ReadGRIB "grib_file";

Returns a Geo::ReadGRIB object that can open GRIB format file "grib_file".
wgrib.exe is used to extract full header info from the "self describing" GRIB
file. 

=item $O->getFullCatalog();

getFullCatalog() will extract the full text descriptions of data items in the GRIB 
file and store them in the object.

=item $O->getParam("show");

I<getParam(show)> Returns a string listing the names of all published parameters.

=item $O->getParam(param);

I<getParam(param)> returns a scalar with the value of param where param is one
of TIME, LAST_TIME, La1, La2, LaInc, Lo1, Lo2, LoInc, fileName.

=over

=item

I<TIME> is the time of the earliest data items in epoch seconds. 

=item

I<LAST_TIME> is the time of the last data items in epoch seconds.

=item

I<La1> I<La2> First and last latitude points in the GRIB file (or most northerly and most southerly).

=item

I<LaInc> The increment between latitude points in the GRIB file. 

=item

I<Lo1> I<Lo2> First and last longitude points in the GRIB file (or most westerly and most easterly).

=item

I<LoInc> The increment between latitude points in the GRIB file.

=item

I<filename> The file name of the GRIB file this object will open to extract
data.

=back


=item $O->show();

Returns a formatted text string description of the data in the GRIB file.
This includes latitude, longitude, and time ranges, and data type text 
descriptions (if getFullCatalog() has been run).

=item $plit = $O->extractLaLo([data_type, ...], lat1, long1, lat2, long2, time);

Extracts forecast data for a given time and data type(s) for a range of 
locations. The locations will be all (lat, long) points in the GRIB file inside the 
rectangular area defined by (lat1, long1) and (lat2, long2) where lat1 >= lat2
and long1 <= long2. That is, lat1 is north or lat2 and long1 is west of long2
(or equal to...)

data_type is either a data type name as a string or a list of data name strings
as an array reference. 

Time will be in epoch seconds as returned, for example, by 
Time::Local. If the time requested, is in the range of times in the file, but not 
one of the exact times in the file, the nearest existing time will be used. An 
error will be set if time is out of range.

Returns a L<Geo::ReadGRIB::PlaceIterator> object containing the extracted data
which can be used to iterate through the data in order sorted by lat and then long.

Extracted data is not retained in the ReadGRIB object data structure by default
as of ReadGRIB version 1.4. Use the backflip() method to turn this behavior 
back on.

Since extractLaLo() needs only one call to wgrib and one temp file open,
this is faster than using extract() to get the same data points one at a time.

=item $plit = $O->extract(data_type, lat, long, I<time>);

Extracts forecast data for given type and location. I<time> is optional.
Extracts data for all times in file unless a specific time is given 
in epoch seconds.

lat and long will be in the range 90 to -90 degrees lat and 0 to 360 degrees
long. If lat or long is out of range for the current file an error will be 
set ( see getError() ).

time will be in epoch seconds as returned, for example, by Time::Local. If the 
time requested is in the range of times in the file, but not one of the exact 
times in the file, the nearest existing time will be used. An error will be set
if time is out of range.

data_type will be one of the data types in the GRIB file or an error is set.

Returns a L<Geo::ReadGRIB::PlaceIterator> object containing the extracted data
which can be used to iterate through the data in order sorted by lat and then long.

Extracted data is also retained in the ReadGRIB object data structure.

=item $O->getError();

Returns string messages for the last error set. If no error is set getError()
returns undef. Only the most recent error will be show. It's good practice to 
check errors after actions, especially while developing applications.

=item $bfFlag = $O->backflip();

When true, certain older behaviors return. In version 1.4 this is only the
storage in the current object of data extracted by extractLaLo().

backflip() returns false by default

=item $O->getDataHash();

Returns a hash ref with all the data items in the object. This will be all the 
data extracted from the GRIB file for in the life of the object.

As of Version 1.4 extractLaLo() does not save extracted data to the object by 
default and so it will not be returned by getDataHash(). Use the backflip() 
method to bring back this older behavior.
 
The hash structure is

   $d->{time}->{lat}->{long}->{type}

=back

=head1 DEPRECATED METHODS

=over

=item $O->getCatalog() DEPRECATED; 

=item $O->getCatalogVerbose() DEPRECATED;

getCatalog() is DEPRECATED and no longer does anything but set an error. 
It's function of Getting the critical offset index for each data type and time 
in the file is now done during object creation.

getCatalogVerbose() is also DEPRECATED as redundant and now just calls 
getFullCatalog(). and sets an error.    

=back

=head1 PRIVATE METHODS

The following  are not public methods and may be removed or changed in
future releases. Do not use these in production code.

=over

=item La1()

=item La2()

=item Lo1()

=item Lo2()

=item LaInc()

=item LoInc()

=item Ni()

=item Nj()

=item TR()

=item adjustLong()

=item calInc()

=item clearError()

=item clearData()

=item dumpit()

=item error()

=item findNearestTime()

=item lalo2offset()

=item m2ft()

=item openGrib()

=item parseGDS()

=item sn_scan_flag()

=item tempfile()

=item toDecimal()

=item validLo()

=item validLa()

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module version. Geo::ReadGRIB versions before
1.1 are known to give results that are sometimes off by one LoInc west or 
east, only on 64bit Perl where nvtype='long double'. Geo::ReadGRIB 1.1 and 
above will not exhibit this bug. 

Versions between 0.98_1 and 1.21 may not parse the time headers correctly for some
forecast records in CMC grib files.  Geo::ReadGRIB 1.3 and above will not exhibit 
this bug. 

Please report problems through

http://rt.cpan.org

or contact Frank Cox, <frank.l.cox@gmail.com> Patches are welcome.

=head1 SEE ALSO

For more on wgrib.c see 

http://www.cpc.ncep.noaa.gov/products/wesley/wgrib.html

For more on Wavewatch III see

http://polar.ncep.noaa.gov/waves/wavewatch/wavewatch.html


=head1 AUTHOR

Frank Cox, E<lt>frank.l.cox@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2009 by Frank Cox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

__C__

