#!/usr/bin/perl
use warnings;
use strict;
use Graphics::TIFF ':all';
use feature 'switch';
no if $] >= 5.018, warnings => 'experimental::smartmatch';
use English qw( -no_match_vars );
use Readonly;
Readonly my $EXIT_ERROR => -1;
Readonly my $TIFF_4_4_0 => 4.004000;

our $VERSION;

my ( $optarg, $dirnum, $showdata, $rawdata, $showwords, $readdata,
    $chopstrips );
my $optind    = 0;
my $stoponerr = 1;
my $diroff    = 0;

sub main {
    my $flags = 0;
    my $order = 0;

    while ( my $c = getopt('f:o:cdDijrswz0123456789') ) {
        given ($c) {
            when (/\d/xsm) {
                $dirnum = substr $ARGV[ $optind - 1 ], 1;
            }
            when ('c') {
                $flags |= TIFFPRINT_COLORMAP | TIFFPRINT_CURVES;
            }
            when ('d') {
                $showdata++;
                $readdata++;
            }
            when ('D') {
                $readdata++;
            }
            when ('f') {
                if ( $optarg eq 'lsb2msb' ) {
                    $order = FILLORDER_LSB2MSB;
                }
                elsif ( $optarg eq 'msb2lsb' ) {
                    $order = FILLORDER_MSB2LSB;
                }
            }
            when ('i') {
                $stoponerr = 0;
            }
            when ('j') {
                $flags |=
                  TIFFPRINT_JPEGQTABLES | TIFFPRINT_JPEGACTABLES |
                  TIFFPRINT_JPEGDCTABLES;
            }
            when ('o') {
                $diroff = $optarg;
            }
            when ('r') {
                $rawdata = 1;
            }
            when ('s') {
                $flags |= TIFFPRINT_STRIPS;
            }
            when ('w') {
                $showwords = 1;
            }
            when ('z') {
                $chopstrips = 1;
            }
            default {
                usage();
            }
        }
    }

    my $multiplefiles = @ARGV - $optind > 1;
    while ( $optind < @ARGV ) {
        if ($multiplefiles) { print "$ARGV[$optind]\n" }
        process_file( $ARGV[ $optind++ ], $order, $flags );
    }
    return 0;
}

sub getopt {
    my ($options) = @_;
    my $c;
    if ( substr( $ARGV[$optind], 0, 1 ) eq qw{-} ) {
        $c = substr $ARGV[ $optind++ ], 1, 1;
        my $regex = $c;
        if ( $regex eq qw{?} ) { $regex = qw{\?} }
        if ( $options =~ /$regex(:)?/xsm ) {
            if ( defined $1 ) { $optarg = $ARGV[ $optind++ ] }
        }
        else {
            if ( $OSNAME eq 'freebsd' ) {
                warn "tiffinfo: illegal option -- $c\n";
            }
            else {
                warn "tiffinfo: invalid option -- $c\n";
            }
            usage();
        }
    }
    return $c;
}

sub usage {
    warn Graphics::TIFF->GetVersion() . "\n\n";
    warn <<'EOS';
usage: tiffinfo [options] input...
where options are:
 -D		read data
 -i		ignore read errors
 -c		display data for grey/color response curve or colormap
 -d		display raw/decoded image data
 -f lsb2msb	force lsb-to-msb FillOrder for input
 -f msb2lsb	force msb-to-lsb FillOrder for input
 -j		show JPEG tables
 -o offset	set initial directory offset
 -r		read/display raw image data instead of decoded data
 -s		display strip offsets and byte counts
 -w		display raw data in words rather than bytes
 -z		enable strip chopping
 -#		set initial directory (first directory is # 0)
EOS
    exit $EXIT_ERROR;
}

sub process_file {
    my ( $file, $order, $flags ) = @_;
    my $tif = Graphics::TIFF->Open( $file, $chopstrips ? 'rC' : 'rc' );
    if ( defined $tif ) {
        if ( defined $dirnum ) {
            if ( $tif->SetDirectory($dirnum) ) {
                tiffinfo( $tif, $order, $flags, 1 );
            }
        }
        elsif ( $diroff != 0 ) {
            if ( $tif->SetSubDirectory($diroff) ) {
                tiffinfo( $tif, $order, $flags, 1 );
            }
        }
        else {
            my $next = 1;
            while ($next) {
                tiffinfo( $tif, $order, $flags, 1 );
                my $offset = $tif->GetField(TIFFTAG_EXIFIFD);
                if ( defined $offset ) {
                    if ( $tif->ReadEXIFDirectory($offset) ) {
                        tiffinfo( $tif, $order, $flags, 0 );
                    }
                }
                $next = $tif->ReadDirectory;
            }
        }
    }
    $tif->Close;
    return;
}

sub showstrip {
    my ( $strip, $pp, $nrow, $scanline ) = @_;

    printf "Strip %lu:\n", $strip;
    my $i = 0;
    while ( $nrow-- > 0 ) {
        for my $cc ( 0 .. $scanline - 1 ) {
            printf ' %02x', ord( substr $pp, $i++, 1 );
            if ( ( ( $cc + 1 ) % 24 ) == 0 ) ## no critic (ProhibitMagicNumbers)
            {
                print "\n";
            }
        }
        print "\n";
    }
    return;
}

sub readcontigstripdata {
    my ($tif) = @_;

    my $scanline     = $tif->ScanlineSize;
    my $h            = $tif->GetField(TIFFTAG_IMAGELENGTH);
    my $rowsperstrip = $tif->GetField(TIFFTAG_ROWSPERSTRIP);
    for ( my $row = 0 ; $row < $h ; $row += $rowsperstrip )
    {    ## no critic (ProhibitCStyleForLoops)
        my $nrow  = ( $row + $rowsperstrip > $h ? $h - $row : $rowsperstrip );
        my $strip = $tif->ComputeStrip( $row, 0 );
        if (
            not( my $buf = $tif->ReadEncodedStrip( $strip, $nrow * $scanline ) )
          )
        {
            if ($stoponerr) { last }
        }
        elsif ($showdata) {
            showstrip( $strip, $buf, $nrow, $scanline );
        }
    }
    return;
}

sub readdata {
    my ($tif) = @_;

    my $config = $tif->GetField(TIFFTAG_PLANARCONFIG);

    if ( $tif->IsTiled ) {
        if ( $config == PLANARCONFIG_CONTIG ) {
            TIFFReadContigTileData($tif);
        }
        else {
            TIFFReadSeparateTileData($tif);
        }
    }
    else {
        if ( $config == PLANARCONFIG_CONTIG ) {
            readcontigstripdata($tif);
        }
        else {
            ReadSeparateStripData($tif);
        }
    }
    return;
}

sub showrawbytes {
    my ( $pp, $n ) = @_;

    for my $i ( 0 .. $n - 1 ) {
        printf ' %02x', ord( substr $pp, $i, 1 );
        if ( ( ( $i + 1 ) % 24 ) == 0 ) {    ## no critic (ProhibitMagicNumbers)
            print "\n ";
        }
    }
    print "\n";
    return;
}

sub showrawwords {
    my ( $pp, $n ) = @_;

    for my $i ( 0 .. $n - 1 ) {
        printf ' %04x', ord( substr $pp, $i, 1 );
        if ( ( ( $i + 1 ) % 15 ) == 0 ) {    ## no critic (ProhibitMagicNumbers)
            print "\n ";
        }
    }
    print "\n";
    return;
}

sub readrawdata {
    my ( $tif, $bitrev ) = @_;

    my $nstrips = $tif->NumberOfStrips();
    my $what    = $tif->IsTiled() ? 'Tile' : 'Strip';

    my @stripbc = $tif->GetField(TIFFTAG_STRIPBYTECOUNTS);
    if ( $nstrips > 0 ) {

        for my $s ( 0 .. $#stripbc ) {
            my $buf;
            if ( $buf = $tif->ReadRawStrip( $s, $stripbc[$s] ) ) {
                if ($showdata) {
                    if ($bitrev) {
                        TIFFReverseBits( $buf, $stripbc[$s] );
                        printf "%s %lu: (bit reversed)\n ", $what, $s;
                    }
                    else {
                        printf "%s %lu:\n ", $what, $s;
                    }
                    if ($showwords) {
                        showrawwords( $buf, $stripbc[$s] >> 1 );
                    }
                    else {
                        showrawbytes( $buf, $stripbc[$s] );
                    }
                }
            }
            else {
                warn "Error reading strip $s\n";
                if ($stoponerr) { last }
            }
        }
    }
    return;
}

sub tiffinfo {
    my ( $tif, $order, $flags, $is_image ) = @_;
    if ( Graphics::TIFF->get_version_scalar >= $TIFF_4_4_0 ) {
        printf "=== TIFF directory %d ===\n", $tif->CurrentDirectory;
    }
    $tif->PrintDirectory( *STDOUT, $flags );
    if ( not $readdata or not $is_image ) { return }
    if ($rawdata) {
        if ($order) {
            my $o = $tif->GetFieldDefaulted(TIFFTAG_FILLORDER);
            readrawdata( $tif, $o != $order );
        }
        else {
            readrawdata( $tif, 0 );
        }
    }
    else {
        if ($order) { $tif->SetField( TIFFTAG_FILLORDER, $order ) }
        readdata($tif);
    }
    return;
}

exit main();
