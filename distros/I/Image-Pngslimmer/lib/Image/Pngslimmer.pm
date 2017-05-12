package Image::Pngslimmer;

use 5.008004;
use strict;
use warnings;
use Compress::Zlib;
use Compress::Raw::Zlib;
use POSIX();

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::Pngslimmer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [qw()] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.30';

sub checkcrc {
    my $chunk = shift;
    my ( $chunklength, $subtocheck, $generatedcrc, $readcrc );

    #get length of data
    $chunklength = unpack( "N", substr( $chunk, 0, 4 ) );
    $subtocheck   = substr( $chunk, 4, $chunklength + 4 );
    $generatedcrc = crc32($subtocheck);
    $readcrc      = unpack( "N", substr( $chunk, $chunklength + 8, 4 ) );
    if ( $generatedcrc eq $readcrc ) { return 1; }

    #don't match
    return 0;
}

sub ispng {
    my ( $pngsig, $startpng, $ihdr_len, $pnglength, $searchindex );
    my ( $idatfound, $nextindex );
    my $blob = shift;

    #check for signature
    $pngsig = pack( "C8", ( 137, 80, 78, 71, 13, 10, 26, 10 ) );
    $startpng = substr( $blob, 0, 8 );
    if ( $startpng ne $pngsig ) {
        return 0;
    }

    #check for IHDR
    if ( substr( $blob, 12, 4 ) ne "IHDR" ) {
        return 0;
    }
    if ( checkcrc( substr( $blob, 8 ) ) < 1 ) {
        return 0;
    }
    $ihdr_len = unpack( "N", substr( $blob, 8, 4 ) );

    #check for IDAT - scanning CRCs as we go
    #scan through all the chunks looking for an IDAT header
    $pnglength = length($blob);

    #start searching from end of IHDR chunk
    $searchindex = 16 + $ihdr_len + 4 + 4;
    $idatfound   = 0;
    while ( $searchindex < ( $pnglength - 4 ) ) {
        if ( checkcrc( substr( $blob, $searchindex - 4 ) ) < 1 ) {
            return 0;
        }
        if ( substr( $blob, $searchindex, 4 ) eq "IDAT" ) {
            $idatfound = 1;
            last;
        }
        $nextindex = unpack( "N", substr( $blob, $searchindex - 4, 4 ) );
        if ( $nextindex == 0 ) {
            $searchindex += 5;    #after a CRC if there is an empty
                                  #chunk
        }
        else {
            $searchindex += ( $nextindex + 4 + 4 + 4 );
        }
    }
    if ( $idatfound == 0 ) {
        return 0;
    }

    #check for IEND chunk
    #check CRC first
    if ( checkcrc( substr( $blob, $pnglength - 12 ) ) < 1 ) { return 0; }
    if ( substr( $blob, $pnglength - 8, 4 ) ne "IEND" ) {
        return 0;
    }

    return 1;
}

sub shrinkchunk {
    my ( $bitblob, $blobout, $status, $y );
    my ( $blobin, $strategy, $level ) = @_;
    unless ( defined($level) ) {
        $level = Z_BEST_COMPRESSION;
    }
    if ( $strategy eq "Z_FILTERED" ) {
        ( $y, $status ) = new Compress::Raw::Zlib::Deflate(
            -Level        => $level,
            -WindowBits   => -&MAX_WBITS(),
            -Bufsize      => 0x1000,
            -Strategy     => Z_FILTERED,
            -AppendOutput => 1
        );
    }
    else {
        ( $y, $status ) = new Compress::Raw::Zlib::Deflate(
            -Level        => $level,
            -WindowBits   => -&MAX_WBITS(),
            -Bufsize      => 0x1000,
            -AppendOutput => 1
        );
    }
    unless ( $status == Z_OK ) {
        return $blobin;
    }
    $status = $y->deflate( $blobin, $bitblob );
    unless ( $status == Z_OK ) {
        return $blobin;
    }
    $status  = $y->flush($bitblob);
    $blobout = $blobout . $bitblob;
    unless ( $status == Z_OK ) {
        return $blobin;
    }
    return $blobout;
}

sub getuncompressed_data {
    my ( $output, $puredata, @idats, $x, $status, $outputlump );
    my ( $calc_crc, $uncompcrc, $searchindex );
    my ( $chunklength, $numberofidats, $chunknumber, $outlength );
    my $blobin    = shift;
    my $pnglength = length($blobin);
    $searchindex = 8 + 25;    #start looking at the end of the IHDR
    while ( $searchindex < ( $pnglength - 8 ) ) {
        $chunklength = unpack( "N", substr( $blobin, $searchindex, 4 ) );
        if ( substr( $blobin, $searchindex + 4, 4 ) eq "IDAT" ) {
            push( @idats, $searchindex );
        }
        $searchindex += $chunklength + 12;
    }
    $numberofidats = @idats;
    if ( $numberofidats == 0 ) {
        return undef;
    }
    $chunknumber = 0;
    while ( $chunknumber < $numberofidats ) {
        $chunklength =
          unpack( "N", substr( $blobin, $idats[$chunknumber], 4 ) );
        if ( $chunknumber == 0 ) {
            if ( $numberofidats == 1 ) {
                $output = substr( $blobin, $idats[0] + 10, $chunklength - 2 );
                last;
            }
            else {
                $output = substr( $blobin, $idats[0] + 10, $chunklength - 2 );
            }
        }
        else {
            if ( ( $numberofidats - 1 ) == $chunknumber ) {
                $puredata =
                  substr( $blobin, $idats[$chunknumber] + 8, $chunklength );
                $output = $output . $puredata;
                last;
            }
            else {
                $puredata =
                  substr( $blobin, $idats[$chunknumber] + 8, $chunklength );
                $output = $output . $puredata;
            }
        }
        $chunknumber++;
    }

    #have the output chunk now uncompress it
    $x = new Compress::Raw::Zlib::Inflate(
        -WindowBits   => -&MAX_WBITS(),
        -ADLER32      => 1,
        -AppendOutput => 1
    ) or return undef;
    $outlength = length($output);
    $uncompcrc = unpack( "N", substr( $output, $outlength - 4 ) );
    $status = $x->inflate( substr( $output, 0, $outlength - 4 ), $outputlump );
    unless ( defined($outputlump) ) {
        return undef;
    }
    $calc_crc = $x->adler32();
    if ( $calc_crc != $uncompcrc ) {
        return undef;
    }
    return $outputlump;    # done
}

sub crushdatachunk {

    #look to inner stream, uncompress that, then recompress
    my ( $chunkin, $blobin ) = @_;
    my $output = getuncompressed_data($blobin);
    unless ( defined($output) ) {
        return $chunkin;
    }
    my $rawlength = length($output);
    my $purecrc   = adler32($output);

    # now crush it at the maximum level
    my $crusheddata = shrinkchunk( $output, Z_FILTERED, Z_BEST_COMPRESSION );
    my $lencompo = length($crusheddata);
    unless ( length($crusheddata) < $rawlength ) {
        $crusheddata =
          shrinkchunk( $output, Z_DEFAULT_STRATEGY, Z_BEST_COMPRESSION );
    }
    my $newlength = length($crusheddata) + 6;

    #now we have compressed the data, write the chunk
    my $chunkout = pack( "N", $newlength );
    my $rfc1950stuff = pack( "C2", ( 0x78, 0xDA ) );
    my $output2 = "IDAT" . $rfc1950stuff . $crusheddata . pack( "N", $purecrc );
    my $outcrc = crc32($output2);
    $chunkout = $chunkout . $output2 . pack( "N", $outcrc );
    return $chunkout;
}

sub zlibshrink {
    my $chunktocopy;
    my ( $chunklength, $processedchunk, $lenidat );
    my $blobin = shift;

    #find the data chunks
    #decompress and then recompress
    #work out the CRC and write it out
    #but first check it is actually a PNG
    if ( ispng($blobin) < 1 ) {
        return undef;
    }
    my $pnglength   = length($blobin);
    my $ihdr_len    = unpack( "N", substr( $blobin, 8, 4 ) );
    my $searchindex = 16 + $ihdr_len + 4 + 4;

    #copy the start of the incoming blob
    my $blobout = substr( $blobin, 0, 16 + $ihdr_len + 4 );
    my $idatfound = 0;
    while ( $searchindex < ( $pnglength - 4 ) ) {

        #Copy the chunk
        $chunklength = unpack( "N", substr( $blobin, $searchindex - 4, 4 ) );
        $chunktocopy = substr( $blobin, $searchindex - 4, $chunklength + 12 );
        if ( substr( $blobin, $searchindex, 4 ) eq "IDAT" ) {
            if ( $idatfound == 0 ) {
                $processedchunk = crushdatachunk( $chunktocopy, $blobin );
                $chunktocopy    = $processedchunk;
                $idatfound      = 1;
            }
            else {
                $chunktocopy = "";
            }
        }

        $lenidat = length($chunktocopy);
        $blobout = $blobout . $chunktocopy;
        $searchindex += $chunklength + 12;
    }
    return $blobout;
}

sub linebyline {

    #analyze the data line by line
    my ( $count, $return_filtered, $filtertype );
    my ( $data, $ihdr ) = @_;
    my $width      = $ihdr->{"imagewidth"};
    my $height     = $ihdr->{"imageheight"};
    my $depth      = $ihdr->{"bitdepth"};
    my $colourtype = $ihdr->{"colourtype"};
    if ( ( $colourtype != 2 ) || ( $depth != 8 ) ) {
        return -1;
    }
    $count           = 0;
    $return_filtered = 1;
    while ( $count < $height ) {
        $filtertype =
          unpack( "C1", substr( $data, $count * $width * 3 + $count, 1 ) );
        if ( $filtertype != 0 ) {

            #already filtered
            $return_filtered = -1;
            last;
        }
        $count++;
    }
    return $return_filtered;    #can be filtered?
}

sub comp_width {
	
    # ctypes:
    # 0: greyscale
    # 2: truecolour
    # 3: indexed-colour
    # 4: greyscale plus alpha
    # 6: truecolour plus alpha

    my $ihdr       = shift;
    my $comp_width = 3;
    my $alpha      = 0;
    my $ctype      = $ihdr->{"colourtype"};
    my $bdepth     = $ihdr->{"bitdepth"};
    if ( $ctype == 2 ) {        #truecolour with no alpha
        if ( $bdepth == 8 ) {
            $comp_width = 3;
        }
        else {
            $comp_width = 6;
        }
    }
    elsif ( $ctype == 0 ) {
        if ( $bdepth == 16 ) {

            #16 bit greyscale
            $comp_width = 2;
        }
        elsif ( $bdepth == 8 ) {

            #8 bit greyscale
            $comp_width = 1;
        }

        #less than a byte greyscale
        elsif ( $bdepth == 4 ) {
            $comp_width = 0.5;
        }
        elsif ( $bdepth == 2 ) {
            $comp_width = 0.25;
        }
        elsif ( $bdepth == 1 ) {
            $comp_width = 0.125;
        }
    }
    elsif ( $ctype == 4 ) {    #grayscale with alpha
        $alpha = 1;
        if ( $bdepth == 8 ) {
            $comp_width = 2;
        }
        else {
            $comp_width = 4;
        }
    }
    elsif ( $ctype == 6 ) {    #truecolour with alpha
        $alpha = 1;
        if ( $bdepth == 8 ) {
            $comp_width = 4;
        }
        else {
            $comp_width = 8;
        }
    }

    return ( $comp_width, $alpha );
}

sub filter_sub {

    #filter data schunk using Sub type
    #http://www.w3.org/TR/PNG/#9Filters
    #Filt(x) = Orig(x) - Orig(a)
    #x is byte to be filtered, a is byte to left
    my ( $origbyte, $leftbyte );
    my $unfiltereddata = shift;
    my $ihdr           = shift;
    my $count          = 0;
    my $count_width    = 0;
    my $newbyte        = 0;
    my ( $comp_width, $alpha ) = comp_width($ihdr);
    my $totalwidth   = $ihdr->{"imagewidth"} * $comp_width;
    my $filtereddata = "";
    my $lines        = $ihdr->{"imageheight"};

    while ( $count < $lines ) {

        #start - add filtertype byte
        $filtereddata = $filtereddata . "\1";
        while ( $count_width < $totalwidth ) {
            $origbyte = unpack(
                "C",
                substr(
                    $unfiltereddata,
                    1 + ( $count * $totalwidth ) + $count_width + $count, 1
                )
            );
            if ( $count_width < $comp_width ) {
                $leftbyte = 0;
            }
            else {
                $leftbyte = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        1 + $count + ( $count * $totalwidth ) + $count_width -
                          $comp_width,
                        1
                    )
                );
            }
            $newbyte = ( $origbyte - $leftbyte ) % 256;
            $filtereddata = $filtereddata . pack( "C", $newbyte );
            $count_width++;
        }
        $count_width = 0;
        $count++;
    }
    return $filtereddata;
}

sub filter_up {

    #filter data schunk using Up type
    my ( $origbyte, $upbyte );
    my $unfiltereddata = shift;
    my $ihdr           = shift;
    my ( $comp_width, $alpha ) = comp_width($ihdr);
    my $count        = 0;
    my $count_width  = 0;
    my $newbyte      = 0;
    my $totalwidth   = $ihdr->{"imagewidth"} * $comp_width;
    my $filtereddata = "";
    my $lines        = $ihdr->{"imageheight"};
    while ( $count < $lines ) {

        #start - add filtertype byte
        $filtereddata = $filtereddata . "\2";
        while ( $count_width < $totalwidth ) {
            $origbyte = unpack(
                "C",
                substr(
                    $unfiltereddata,
                    1 + ( $count * $totalwidth ) + $count_width + $count, 1
                )
            );
            if ( $count == 0 ) {
                $upbyte = 0;
            }
            else {
                $upbyte = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        $count + ( ( $count - 1 ) * $totalwidth ) +
                          $count_width,
                        1
                    )
                );
            }
            $newbyte = ( $origbyte - $upbyte ) % 256;
            $filtereddata = $filtereddata . pack( "C", $newbyte );
            $count_width++;
        }
        $count_width = 0;
        $count++;
    }
    return $filtereddata;
}

sub filter_ave {

    #filter data schunk using Ave type
    my ( $origbyte,      $avebyte );
    my ( $top_predictor, $left_predictor );
    my $unfiltereddata = shift;
    my $ihdr           = shift;
    my ( $comp_width, $alpha ) = comp_width($ihdr);
    my $count        = 0;
    my $count_width  = 0;
    my $newbyte      = 0;
    my $totalwidth   = $ihdr->{"imagewidth"} * $comp_width;
    my $filtereddata = "";
    my $lines        = $ihdr->{"imageheight"};
    while ( $count < $lines ) {

        #start - add filtertype byte
        $filtereddata = $filtereddata . "\3";
        while ( $count_width < $totalwidth ) {
            $origbyte = unpack(
                "C",
                substr(
                    $unfiltereddata,
                    1 + ( $count * $totalwidth ) + $count_width + $count, 1
                )
            );
            if ( $count > 0 ) {
                $top_predictor = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        $count + ( ( $count - 1 ) * $totalwidth ) +
                          $count_width,
                        1
                    )
                );
            }
            else { $top_predictor = 0; }
            if ( $count_width >= $comp_width ) {
                $left_predictor = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        1 + $count + ( $count * $totalwidth ) + $count_width -
                          $comp_width,
                        1
                    )
                );
            }
            else {
                $left_predictor = 0;
            }
            $avebyte      = ( $top_predictor + $left_predictor ) / 2;
            $avebyte      = POSIX::floor($avebyte);
            $newbyte      = ( $origbyte - $avebyte ) % 256;
            $filtereddata = $filtereddata . pack( "C", $newbyte );
            $count_width++;
        }
        $count_width = 0;
        $count++;
    }
    return $filtereddata;
}

sub filter_paeth {    #paeth predictor type filtering
    my ( $origbyte, $paethbyte_a, $paethbyte_b, $paethbyte_c, $paeth_p );
    my ( $paeth_pa, $paeth_pb, $paeth_pc, $paeth_predictor );
    my $unfiltereddata = shift;
    my $ihdr           = shift;
    my ( $comp_width, $alpha ) = comp_width($ihdr);
    my $count        = 0;
    my $count_width  = 0;
    my $newbyte      = 0;
    my $totalwidth   = $ihdr->{"imagewidth"} * $comp_width;
    my $filtereddata = "";
    my $lines        = $ihdr->{"imageheight"};
    while ( $count < $lines ) {

        #start - add filtertype byte
        $filtereddata = $filtereddata . "\4";
        while ( $count_width < $totalwidth ) {
            $origbyte = unpack(
                "C",
                substr(
                    $unfiltereddata,
                    1 + ( $count * $totalwidth ) + $count_width + $count, 1
                )
            );
            if ( $count > 0 ) {
                $paethbyte_b = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        $count + ( ( $count - 1 ) * $totalwidth ) +
                          $count_width,
                        1
                    )
                );
            }
            else { $paethbyte_b = 0; }
            if ( $count_width >= $comp_width ) {
                $paethbyte_a = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        1 + $count + ( $count * $totalwidth ) + $count_width -
                          $comp_width,
                        1
                    )
                );
            }
            else {
                $paethbyte_a = 0;
            }
            if ( ( $count_width >= $comp_width ) && ( $count > 0 ) ) {
                $paethbyte_c = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        $count + ( ( $count - 1 ) * $totalwidth ) +
                          $count_width - $comp_width,
                        1
                    )
                );
            }
            else {
                $paethbyte_c = 0;
            }
            $paeth_p  = $paethbyte_a + $paethbyte_b - $paethbyte_c;
            $paeth_pa = abs( $paeth_p - $paethbyte_a );
            $paeth_pb = abs( $paeth_p - $paethbyte_b );
            $paeth_pc = abs( $paeth_p - $paethbyte_c );
            if (   ( $paeth_pa <= $paeth_pb )
                && ( $paeth_pa <= $paeth_pc ) )
            {
                $paeth_predictor = $paethbyte_a;
            }
            elsif ( $paeth_pb <= $paeth_pc ) {
                $paeth_predictor = $paethbyte_b;
            }
            else {
                $paeth_predictor = $paethbyte_c;
            }
            $newbyte = ( $origbyte - $paeth_predictor ) % 256;
            $filtereddata = $filtereddata . pack( "C", $newbyte );
            $count_width++;
        }
        $count_width = 0;
        $count++;
    }
    return $filtereddata;
}

sub filterdata {
    my ( $filtereddata, $finalfiltered );
    my $unfiltereddata = shift;
    my $ihdr           = shift;
    my $filtered_sub   = filter_sub( $unfiltereddata, $ihdr );
    my $filtered_up    = filter_up( $unfiltereddata, $ihdr );
    my $filtered_ave   = filter_ave( $unfiltereddata, $ihdr );
    my $filtered_paeth = filter_paeth( $unfiltereddata, $ihdr );

    my $pixels = $ihdr->{"imagewidth"};
    my $rows   = $ihdr->{"imageheight"};
    my ( $comp_width, $alpha ) = comp_width($ihdr);
    my $bytesperline = $pixels * $comp_width;
    my $countout     = 0;
    my $rows_done    = 0;
    my $count_sub    = 0;
    my $count_up     = 0;
    my $count_ave    = 0;
    my $count_zero   = 0;
    my $count_paeth  = 0;
    while ( $rows_done < $rows ) {

        while ( ($countout) < $bytesperline ) {
            $count_sub += unpack(
                "c",
                substr(
                    $filtered_sub,
                    1 + ( $rows_done * $bytesperline ) + $countout + $rows_done,
                    1
                )
            );
            $count_up += unpack(
                "c",
                substr(
                    $filtered_up,
                    1 + ( $rows_done * $bytesperline ) + $countout + $rows_done,
                    1
                )
            );
            $count_ave += unpack(
                "c",
                substr(
                    $filtered_ave,
                    1 + ( $rows_done * $bytesperline ) + $countout + $rows_done,
                    1
                )
            );
            $count_zero += unpack(
                "c",
                substr(
                    $unfiltereddata,
                    1 + ( $rows_done * $bytesperline ) + $countout + $rows_done,
                    1
                )
            );
            $count_paeth += unpack(
                "c",
                substr(
                    $filtered_paeth,
                    1 + ( $rows_done * $bytesperline ) + $countout + $rows_done,
                    1
                )
            );
            $countout++;
        }
        $count_paeth = abs($count_paeth);
        $count_zero  = abs($count_zero);
        $count_ave   = abs($count_ave);
        $count_up    = abs($count_up);
        $count_sub   = abs($count_sub);
        if (   ( $count_paeth <= $count_zero )
            && ( $count_paeth <= $count_sub )
            && ( $count_paeth <= $count_up )
            && ( $count_paeth <= $count_ave ) )
        {
            $finalfiltered = $finalfiltered
              . substr(
                $filtered_paeth,
                $rows_done + $rows_done * $bytesperline,
                $bytesperline + 1
              );
        }
        elsif (( $count_ave <= $count_zero )
            && ( $count_ave <= $count_sub )
            && ( $count_ave <= $count_up ) )
        {
            $finalfiltered = $finalfiltered
              . substr(
                $filtered_ave,
                $rows_done + $rows_done * $bytesperline,
                $bytesperline + 1
              );
        }
        elsif (( $count_up <= $count_zero )
            && ( $count_up <= $count_sub ) )
        {
            $finalfiltered = $finalfiltered
              . substr(
                $filtered_up,
                $rows_done + $rows_done * $bytesperline,
                $bytesperline + 1
              );
        }
        elsif ( $count_sub <= $count_zero ) {
            $finalfiltered = $finalfiltered
              . substr(
                $filtered_sub,
                $rows_done + $rows_done * $bytesperline,
                $bytesperline + 1
              );
        }
        else {
            $finalfiltered = $finalfiltered
              . substr(
                $unfiltereddata,
                $rows_done + $rows_done * $bytesperline,
                $bytesperline + 1
              );
        }
        $countout    = 0;
        $count_up    = 0;
        $count_sub   = 0;
        $count_zero  = 0;
        $count_ave   = 0;
        $count_paeth = 0;
        $rows_done++;
    }
    return $finalfiltered;
}

sub getihdr {
    my %ihdr;
    my $blobin = shift;
    $ihdr{"imagewidth"}  = unpack( "N", substr( $blobin, 16, 4 ) );
    $ihdr{"imageheight"} = unpack( "N", substr( $blobin, 20, 4 ) );
    $ihdr{"bitdepth"}    = unpack( "C", substr( $blobin, 24, 1 ) );
    $ihdr{"colourtype"}  = unpack( "C", substr( $blobin, 25, 1 ) );
    $ihdr{"compression"} = unpack( "C", substr( $blobin, 26, 1 ) );
    $ihdr{"filter"}      = unpack( "C", substr( $blobin, 27, 1 ) );
    $ihdr{"interlace"}   = unpack( "C", substr( $blobin, 28, 1 ) );
    return \%ihdr;
}

sub filter {
    my ( $chunklength, $chunktocopy, $rfc1950stuff, $output, $newlength );
    my ( $outcrc, $processedchunk, $filtereddata );
    my $blobin = shift;

    #basic check so we do not waste our time
    if ( ispng($blobin) < 1 ) {
        return undef;
    }

    #read some basic info about the PNG
    my $ihdr = getihdr($blobin);
    if ( $ihdr->{"colourtype"} == 3 ) {

        #already palettized
        return $blobin;
    }
    if ( $ihdr->{"bitdepth"} < 8 ) {

        #colour depth too low to be worth it
        return $blobin;
    }
    if ( $ihdr->{"compression"} != 0 ) {

        #non-standard compression
        return $blobin;
    }
    if ( $ihdr->{"filter"} != 0 ) {

        #non-standard filtering
        return $blobin;
    }
    if ( $ihdr->{"interlace"} != 0 ) {

        #FIXME: support interlacing
        return $blobin;
    }
    my $datachunk = getuncompressed_data($blobin);
    unless ( defined($datachunk) ) {
        return $blobin;
    }
    my $canfilter = linebyline( $datachunk, $ihdr );
    if ( $canfilter > 0 ) {
        $filtereddata = filterdata( $datachunk, $ihdr );
    }
    else {
        return $blobin;
    }

    #Now stick the uncompressed data into a chunk
    #and return - leaving the compression to a different process
    my $filteredcrc = adler32($filtereddata);
    $filtereddata = shrinkchunk( $filtereddata, Z_FILTERED, Z_BEST_SPEED );
    my $filterlen = length($filtereddata);

    #now push the data into the PNG
    my $pnglength   = length($blobin);
    my $ihdr_len    = unpack( "N", substr( $blobin, 8, 4 ) );
    my $searchindex = 16 + $ihdr_len + 4 + 4;

    #copy the start of the incoming blob
    my $blobout = substr( $blobin, 0, 16 + $ihdr_len + 4 );
    my $foundidat = 0;
    while ( $searchindex < ( $pnglength - 4 ) ) {

        #Copy the chunk
        $chunklength = unpack( "N", substr( $blobin, $searchindex - 4, 4 ) );
        $chunktocopy = substr( $blobin, $searchindex - 4, $chunklength + 12 );
        if ( substr( $blobin, $searchindex, 4 ) eq "IDAT" ) {
            if ( $foundidat == 0 ) {

                #ignore any additional IDAT chunks
                $rfc1950stuff = pack( "C2", ( 0x78, 0x5E ) );
                $output = "IDAT"
                  . $rfc1950stuff
                  . $filtereddata
                  . pack( "N", $filteredcrc );
                $newlength = $filterlen + 6;
                $outcrc    = crc32($output);
                $processedchunk =
                  pack( "N", $newlength ) . $output . pack( "N", $outcrc );
                $chunktocopy = $processedchunk;
                $foundidat   = 1;
            }
            else {
                $chunktocopy = "";
            }
        }
        $blobout = $blobout . $chunktocopy;
        $searchindex += $chunklength + 12;
    }
    return $blobout;
}

sub discard_noncritical {
    my $chunktext;
    my $nextindex;
    my $blob = shift;
    if ( ispng($blob) < 1 ) {

        #not a PNG
        return $blob;
    }

    #we know we have a png = so go straight to the IHDR chunk
    #copy signature and text + length from IHDR
    my $cleanblob = substr( $blob, 0, 16 );

    #get length of IHDR
    my $ihdr_len = unpack( "N", substr( $blob, 8, 4 ) );

    #copy IHDR data + CRC
    $cleanblob = $cleanblob . substr( $blob, 16, $ihdr_len + 4 );

    #move on to next text field
    my $searchindex = 16 + $ihdr_len + 8;
    my $pnglength   = length($blob);
    while ( $searchindex < ( $pnglength - 4 ) ) {

        #how big is chunk?
        $nextindex = unpack( "N", substr( $blob, $searchindex - 4, 4 ) );

        #is chunk critcial?
        $chunktext = substr( $blob, $searchindex, 1 );
        if ( ( ord($chunktext) & 0x20 ) == 0 ) {

            #critcial chunk so copy
            #copy length (4), text (4), data, CRC (4)
            $cleanblob = $cleanblob
              . substr( $blob, $searchindex - 4, 4 + 4 + $nextindex + 4 );
        }

        #update the searchpoint -
        #4 + data length + CRC (4) + 4 to get to the text
        $searchindex += $nextindex + 12;
    }
    return $cleanblob;
}

sub ispalettized {
    my $blobin = shift;
    my $ihdr   = getihdr($blobin);
    return 0 unless $ihdr->{"colourtype"} == 3;
    return 1;
}

sub unfiltersub {
    my $lineout;
    my ( $addition, $reconbyte );
    my ( $chunkin, $lines_done, $linelength, $comp_width ) = @_;
    my $pointis = 1;
    while ( $pointis < $linelength ) {
        $reconbyte =
          unpack( "C",
            substr( $chunkin, $lines_done * $linelength + $pointis, 1 ) );
        if ( $pointis > $comp_width ) {
            $addition =
              unpack( "C", substr( $lineout, $pointis - $comp_width - 1, 1 ) );
        }
        else {
            $addition = 0;
        }
        $reconbyte = ( $reconbyte + $addition ) % 256;
        $lineout = $lineout . pack( "C", $reconbyte );
        $pointis++;
    }
    $lineout = "\0" . $lineout;
    return $lineout;
}

sub unfilterup {
    my $lineout;
    my ( $addition, $reconbyte );
    my ( $chunkin, $chunkout, $lines_done, $linelength ) = @_;
    my $pointis = 1;
    while ( $pointis < $linelength ) {
        $reconbyte =
          unpack( "C",
            substr( $chunkin, $lines_done * $linelength + $pointis, 1 ) );
        if ( $lines_done > 0 ) {
            $addition = unpack(
                "C",
                substr(
                    $chunkout, ( $lines_done - 1 ) * $linelength + $pointis, 1
                )
            );
        }
        else {
            $addition = 0;
        }
        $reconbyte = ( $reconbyte + $addition ) % 256;
        $lineout = $lineout . pack( "C", $reconbyte );
        $pointis++;
    }
    $lineout = "\0" . $lineout;
    return $lineout;
}

sub unfilterave {
    my $lineout;
    my ( $addition, $addition_up, $addition_left );
    my $reconbyte;
    my ( $chunkin, $chunkout, $lines_done, $linelength, $compwidth ) = @_;
    my $pointis = 1;
    while ( $pointis < $linelength ) {
        $reconbyte =
          unpack( "C",
            substr( $chunkin, $lines_done * $linelength + $pointis, 1 ) );
        if ( $lines_done > 0 ) {
            $addition_up = unpack(
                "C",
                substr(
                    $chunkout, ( $lines_done - 1 ) * $linelength + $pointis, 1
                )
            );
        }
        else {
            $addition_up = 0;
        }
        if ( $pointis > $compwidth ) {
            $addition_left =
              unpack( "C", substr( $lineout, $pointis - $compwidth - 1, 1 ) );
        }
        else {
            $addition_left = 0;
        }
        $addition  = POSIX::floor( ( $addition_up + $addition_left ) / 2 );
        $reconbyte = ( $reconbyte + $addition ) % 256;
        $lineout   = $lineout . pack( "C", $reconbyte );
        $pointis++;
    }
    $lineout = "\0" . $lineout;
    return $lineout;
}

sub unfilterpaeth {
    my $lineout;
    my ( $addition, $addition_up, $addition_left );
    my ( $addition_uleft, $reconbyte, $paeth_p, $paeth_a, $paeth_b );
    my ( $paeth_c, $recbyte );
    my ( $chunkin, $chunkout, $lines_done, $linelength, $compwidth ) = @_;
    my $pointis = 1;
    while ( $pointis < $linelength ) {
        $reconbyte =
          unpack( "C",
            substr( $chunkin, $lines_done * $linelength + $pointis, 1 ) );
        if ( $lines_done > 0 ) {
            $addition_up = unpack(
                "C",
                substr(
                    $chunkout, ( $lines_done - 1 ) * $linelength + $pointis, 1
                )
            );
            if ( $pointis > $compwidth ) {
                $addition_uleft = unpack(
                    "C",
                    substr(
                        $chunkout,
                        ( $lines_done - 1 ) * $linelength + $pointis -
                          $compwidth,
                        1
                    )
                );
            }
            else {
                $addition_uleft = 0;
            }
        }
        else {
            $addition_up    = 0;
            $addition_uleft = 0;
        }
        if ( $pointis > $compwidth ) {
            $addition_left =
              unpack( "C", substr( $lineout, $pointis - $compwidth - 1, 1 ) );
        }
        else {
            $addition_left = 0;
        }
        $paeth_p = $addition_up + $addition_left - $addition_uleft;
        $paeth_a = abs( $paeth_p - $addition_left );
        $paeth_b = abs( $paeth_p - $addition_up );
        $paeth_c = abs( $paeth_p - $addition_uleft );
        if ( ( $paeth_a <= $paeth_b ) && ( $paeth_a <= $paeth_c ) ) {
            $addition = $addition_left;
        }
        elsif ( $paeth_b <= $paeth_c ) {
            $addition = $addition_up;
        }
        else {
            $addition = $addition_uleft;
        }
        $recbyte = ( $reconbyte + $addition ) % 256;
        $lineout = $lineout . pack( "C", $recbyte );
        $pointis++;
    }
    $lineout = "\0" . $lineout;
    return $lineout;
}

sub unfilter {
    my $chunkout;
    my $filtertype;
    my $chunkin     = shift;
    my $ihdr        = shift;
    my $imageheight = $ihdr->{"imageheight"};
    my $imagewidth  = $ihdr->{"imagewidth"};

    #get each line
    my $lines_done  = 0;
    my $pixels_done = 0;
    my ( $comp_width, $alpha ) = comp_width($ihdr);
    my $linelength = $comp_width * $imagewidth + 1;
    while ( $lines_done < $imageheight ) {
        $filtertype =
          unpack( "C", substr( $chunkin, $lines_done * $linelength, 1 ) );
        if ( $filtertype == 0 ) {

            #line not filtered at all
            $chunkout = $chunkout
              . substr( $chunkin, $lines_done * $linelength, $linelength );
        }
        elsif ( $filtertype == 4 ) {
            $chunkout = $chunkout
              . unfilterpaeth( $chunkin, $chunkout, $lines_done, $linelength,
                $comp_width );
        }
        elsif ( $filtertype == 1 ) {
            $chunkout = $chunkout
              . unfiltersub( $chunkin, $lines_done, $linelength, $comp_width );
        }
        elsif ( $filtertype == 2 ) {
            $chunkout = $chunkout
              . unfilterup( $chunkin, $chunkout, $lines_done, $linelength );
        }
        else {
            $chunkout = $chunkout
              . unfilterave( $chunkin, $chunkout, $lines_done, $linelength,
                $comp_width );
        }
        $lines_done++;
    }
    return $chunkout;
}

sub countcolours {
    my ( $limit, $totallines, $width );
    my ( $cdepth, $x, $colourfound, $pixelpoint, $colour, $alpha, $ndepth );
    my %colourlist;
    my $bdepth;
    my ( $chunk, $ihdr ) = @_;
    $totallines = $ihdr->{"imageheight"};
    $width      = $ihdr->{"imagewidth"};
    ( $cdepth, $alpha ) = comp_width($ihdr);
    my $linesdone    = 0;
    my $linelength   = $width * $cdepth + 1;
    my $coloursfound = 0;
    $ndepth = $cdepth;

    if ($alpha) {

        #truecolour first
        if ( $cdepth == 4 ) {
            $bdepth = $ihdr->{"bitdepth"};
            if ( $bdepth == 8 ) {
                $ndepth = 3;
            }
            else {
                $ndepth = 2;
            }
        }
        elsif ( $cdepth == 8 ) {
            $ndepth = 6;
        }

        #now greyscale
        elsif ( $cdepth == 2 ) {
            $ndepth = 1;
        }
    }
    while ( $linesdone < $totallines ) {
        $pixelpoint = 0;
        while ( $pixelpoint < $width ) {
            $colourfound =
              substr( $chunk,
                ( $pixelpoint * $cdepth ) + ( $linesdone * $linelength ) + 1,
                $ndepth );
            $colour = 0;
            for ( $x = 0 ; $x < $ndepth ; $x++ ) {
                $colour = $colour << 8 | ord( substr( $colourfound, $x, 1 ) );
            }
            if ( defined( $colourlist{$colour} ) ) {
                $colourlist{$colour}++;
            }
            else {
                $colourlist{$colour} = 1;
                $coloursfound++;
            }
            $pixelpoint++;
        }
        $linesdone++;
    }

    return ( $coloursfound, \%colourlist );
}

sub reportcolours {
    my $blobin = shift;

    #is it a PNG
    unless ( ispng($blobin) > 0 ) {
        print "Supplied image is not a PNG\n";
        return -1;
    }

    #is it already palettized?
    unless ( ispalettized($blobin) < 1 ) {
        print "Supplied image is indexed.\n";
        return -1;
    }
    my $filtereddata   = getuncompressed_data($blobin);
    my $ihdr           = getihdr($blobin);
    my $unfiltereddata = unfilter( $filtereddata, $ihdr );
    my ( $colours, $colourlist ) = countcolours( $unfiltereddata, $ihdr );
    return $colourlist;
}

sub indexcolours {

    # take PNG and count colours
    my $blobout;
    my ( $ihdr_chunk, $pal_chunk, $x, $palindex, $colourfound );
    my $ihdrcrc;
    my ( $searchindex, $pnglength, $foundidat, $chunklength, $chunktocopy );
    my ( $palcount, $pal_crc, $len_pal, $dataout, $linesdone, $totallines );
    my ( $width, $cdepth, $linelength, $pixelpoint, $colour, $rfc1950stuff );
    my ( $rfc1951stuff, $output, $newlength, $outcrc, $processedchunk );
    my ( $alpha, $ndepth, $bdepth );

    my $blobin = shift;

    #is it a PNG
    return $blobin unless ispng($blobin) > 0;

    #is it already palettized?
    return $blobin unless ispalettized($blobin) < 1;
    my $colour_limit = shift;

    #0 means no limit
    $colour_limit = 0 unless $colour_limit;
    my $filtereddata   = getuncompressed_data($blobin);
    my $ihdr           = getihdr($blobin);
    my $unfiltereddata = unfilter( $filtereddata, $ihdr );
    my ( $colours, $colourlist ) = countcolours( $unfiltereddata, $ihdr );
    if ( $colours < 1 ) { return $blobin }

    #to write out an indexed version $colours has to be less than 256
    if ( $colours < 256 ) {

        #have to rewrite the whole thing now
        #start with the PNG header
        $blobout = pack( "C8", ( 137, 80, 78, 71, 13, 10, 26, 10 ) );

        #now the IHDR
        $blobout    = $blobout . pack( "N", 0x0D );
        $ihdr_chunk = "IHDR";
        $ihdr_chunk = $ihdr_chunk
          . pack( "N2", ( $ihdr->{"imagewidth"}, $ihdr->{"imageheight"} ) );

        #FIXME: Support index of less than 8 bits
        #8 bit indexed colour
        $ihdr_chunk = $ihdr_chunk . pack( "C2", ( 8, 3 ) );
        $ihdr_chunk = $ihdr_chunk
          . pack( "C3",
            ( $ihdr->{"compression"}, $ihdr->{"filter"}, $ihdr->{"interlace"} )
          );
        $ihdrcrc = crc32($ihdr_chunk);
        $blobout = $blobout . $ihdr_chunk . pack( "N", $ihdrcrc );

        #now any chunk before the IDAT
        $searchindex = 16 + 13 + 4 + 4;
        $pnglength   = length($blobin);
        $foundidat   = 0;
        while ( $searchindex < ( $pnglength - 4 ) ) {

            #Copy the chunk
            $chunklength =
              unpack( "N", substr( $blobin, $searchindex - 4, 4 ) );
            $chunktocopy =
              substr( $blobin, $searchindex - 4, $chunklength + 12 );
            if ( substr( $blobin, $searchindex, 4 ) eq "IDAT" ) {
                if ( $foundidat == 0 ) {

                    #ignore any additional IDAT chunks
                    #now the palette chunk
                    $pal_chunk = "";
                    my %colourlist = %{$colourlist};
                    $palcount = 0;
                    my %palindex;
                    my @keyslist = keys(%colourlist);
                    keys(%palindex) = scalar(@keyslist);
                    foreach $x (@keyslist) {
                        $pal_chunk = $pal_chunk
                          . pack( "C3",
                            ( $x >> 16, ( $x & 0xFF00 ) >> 8, $x & 0xFF ) );

                        #use a second hash to record
                        #where the colour is in the
                        #palette
                        $palindex{$x} = $palcount;
                        $palcount++;
                    }
                    $pal_crc = crc32( "PLTE" . $pal_chunk );
                    $len_pal = length($pal_chunk);
                    $blobout = $blobout
                      . pack( "N", $len_pal ) . "PLTE"
                      . $pal_chunk
                      . pack( "N", $pal_crc );

                    #now process the IDAT
                    $linesdone  = 0;
                    $totallines = $ihdr->{"imageheight"};
                    $width      = $ihdr->{"imagewidth"};
                    ( $cdepth, $alpha ) = comp_width($ihdr);
                    $ndepth = $cdepth;

                    if ($alpha) {

                        #truecolour first
                        if ( $cdepth == 4 ) {
                            $bdepth = $ihdr->{"bitdepth"};
                            if ( $bdepth == 8 ) {
                                $ndepth = 3;
                            }
                            else {
                                $ndepth = 2;
                            }
                        }
                        elsif ( $cdepth == 8 ) {
                            $ndepth = 6;
                        }

                        #now greyscale
                        elsif ( $cdepth == 2 ) {
                            $ndepth = 1;
                        }
                    }

                    $linelength = $width * $cdepth + 1;
                    while ( $linesdone < $totallines ) {
                        $dataout    = $dataout . "\0";
                        $pixelpoint = 0;
                        while ( $pixelpoint < $width ) {
                            $colourfound = substr(
                                $unfiltereddata,
                                ( $pixelpoint * $cdepth ) +
                                  ( $linesdone * $linelength ) + 1,
                                $ndepth
                            );
                            $colour = 0;
                            for ( $x = 0 ; $x < $ndepth ; $x++ ) {
                                $colour =
                                  $colour << 8 |
                                  ord( substr( $colourfound, $x, 1 ) );
                            }
                            $dataout =
                              $dataout . pack( "C", $palindex{$colour} );
                            $pixelpoint++;
                        }
                        $linesdone++;
                    }

                    #now to deflate $dataout to get
                    #proper stream

                    $rfc1950stuff = pack( "C2", ( 0x78, 0x5E ) );
                    $rfc1951stuff =
                      shrinkchunk( $dataout, Z_DEFAULT_STRATEGY, Z_BEST_SPEED );
                    $output = "IDAT"
                      . $rfc1950stuff
                      . $rfc1951stuff
                      . pack( "N", adler32($dataout) );
                    $newlength = length($output) - 4;
                    $outcrc    = crc32($output);
                    $processedchunk =
                      pack( "N", $newlength ) . $output . pack( "N", $outcrc );
                    $chunktocopy = $processedchunk;
                    $foundidat   = 1;
                }
                else {
                    $chunktocopy = "";
                }
            }
            $blobout = $blobout . $chunktocopy;
            $searchindex += $chunklength + 12;
        }
    }
    else {
        return $blobin;
    }
    return $blobout;
}

sub convert_toxyz {

    #convert 24 bit number to cartesian point
    my $inpoint = shift;
    return ( $inpoint >> 16, ( $inpoint & 0xFF00 ) >> 8, $inpoint & 0xFF );
}

sub convert_tocolour {

    #convert cartesian to RGB colour
    my ( $x, $y, $z ) = @_;
    return ( ( $x << 16 ) | ( $y << 8 ) | ($z) );
}

sub getcolour_ave {
    my ( $red, $green, $blue, $numb, $x, $rt, $gt, $bt );
    my $coloursin = shift;
    $numb = scalar(@$coloursin);
    if ( $numb == 0 ) { return ( 0, 0, 0 ) }
    for ( $x = 0 ; $x < $numb ; $x++ ) {
        ( $rt, $gt, $bt ) = convert_toxyz( $coloursin->[$x] );
        $red   += $rt;
        $green += $gt;
        $blue  += $bt;
    }
    $red   = ( $red / $numb );
    $green = ( $green / $numb );
    $blue  = ( $blue / $numb );
    return ( $red, $green, $blue );
}

sub getaxis_details {

    #return a reference to the longestaxis and its length
    my ( $longestaxis, $length, $i, );
    my $boundingbox = shift;
    return ( 0, 0 ) unless defined( $boundingbox->[5] );
    $longestaxis = 0;
    my @lengths = (
        $boundingbox->[3] - $boundingbox->[0],
        $boundingbox->[4] - $boundingbox->[1],
        $boundingbox->[5] - $boundingbox->[2]
    );
    for ( $i = 1 ; $i < 3 ; $i++ ) {
        if ( $lengths[$i] > $lengths[$longestaxis] ) {
            $longestaxis = $i;
        }
    }
    my $longestaxis_cor = 2 - $longestaxis;
    return ( $longestaxis_cor, $lengths[$longestaxis] );
}

sub getbiggestbox {

    #return the index to the biggest box
    my ( $boxesin, $n ) = @_;
    my $index = 0;
    my $length;
    my $biggest = $boxesin->[3];
    if ($n > 1) {
	for ( my $i = 1 ; $i < $n ; $i++ ) {

            #length is 4th item per box
	    $length = $boxesin->[ $i * 4 + 3 ];
	    if ($length > $biggest) {
	    	$index = $i;
		$biggest = $length;
	    }	  
	}
    }
    return $index;
}

sub sortonaxes {
    my ( $coloursref, $longestaxis ) = @_;
    my @newcolours = @$coloursref;

    #FIXME: This only works for 24 bit colour
    if ( $longestaxis == 2 ) {

        #can just sort on the whole number if red
        return [sort { $a <=> $b } @newcolours];
    }
    my $colshift = 0xFFFFFF >> ( 16 - ( $longestaxis * 8 ) );
    my ( $x, %distances );
    keys(%distances) = scalar(@newcolours);
    foreach $x (@newcolours) {
        $distances{$x} = $x & $colshift;
    }
    return [sort { $distances{$a} <=> $distances{$b} } keys %distances];
}

sub generate_box {

    #convert colours to cartesian points
    #and then return the bounding box
    if ( scalar(@_) == 1 ) {
        return [ convert_toxyz( pop @_ ) ];
    }
    my ( @reds, @greens, @blues );
    my ( $x, $rd, $gn, $bl, $boundref );
    foreach $x (@_) {
        ( $rd, $gn, $bl ) = convert_toxyz($x);
        push @reds,   $rd;
        push @greens, $gn;
        push @blues,  $bl;
    }
    @reds   = sort { $a <=> $b } @reds;
    @greens = sort { $a <=> $b } @greens;
    @blues  = sort { $a <=> $b } @blues;
    $boundref = [
        shift @reds,
        shift @greens,
        shift @blues,
        pop @reds,
        pop @greens,
        pop @blues
    ];
    return $boundref;
}

sub getpalette {
    my ( $x, @palette, %lookup, $lookup, $boxes, $z );
    my ( $colnumbers, $colours );
    my @boxes = @_;

    #eachbox has four references
    $colnumbers = scalar(@boxes) / 4;
    for ( $x = 0 ; $x < $colnumbers ; $x++ ) {
        $colours = $boxes[ $x * 4 + 1 ];
        my @colours = @$colours;
        push @palette, getcolour_ave( \@colours );
        foreach $z (@colours) { $lookup{$z} = $x }
    }
    return ( \@palette, \%lookup );
}

sub closestmatch_inRGB {
    my ( $colourin, $pr, $pg, $pb );
    my ( $maxindex, $x, $q );
    my ( $index, $distance, $newdistance );

    $distance = 0xFFFFF;
    my ( $palref, $cir, $cig, $cib ) = @_;
    my @pallist = @$palref;
    $maxindex = scalar(@pallist) / 3;    # assuming three colours
    $q = 0;
    for ( $x = 0 ; $x < $maxindex ; $x++ ) {
        $pr = $pallist[ $q++ ] - $cir;
        $pg = $pallist[ $q++ ] - $cig;
        $pb = $pallist[ $q++ ] - $cib;
        $newdistance = $pr * $pr + $pg * $pg + $pb * $pb;
        if ( $newdistance < $distance ) {
            $distance = $newdistance;
            $index    = $x;

            #approximate
            if ( $distance <= 12 ) { last }
        }
    }
    return $index;
}

sub index_mediancut {
    my $colour_numbers;
    my ( @boundingbox,   $colcount, @boxes );
    my ( $boxtocut,      $median,   $biggestbox );
    my ( $sortedcolours, $boxout,   $refbigbox );
    my ( $colourlist, $colourspaces ) = @_;
    if ( !defined($colourspaces) || ( $colourspaces == 0 ) ) {
        $colourspaces = 256;
    }
    $colcount = 0;
    my %colourlist = %{$colourlist};
    my @colourkeys = keys(%colourlist);

    #can now define the colour space
    # boxes data is
    # reftoboundingboxarray, reftocoloursarray, longest_axis,
    # length_of_longest_axis
    $refbigbox = generate_box(@colourkeys);
    push @boxes, $refbigbox;
    push @boxes, \@colourkeys;
    push @boxes, getaxis_details($refbigbox);
    $boxtocut = 0;
    do {

        #find the biggest box
        $boxtocut = getbiggestbox( \@boxes, $colcount )
          unless $colcount == 0;
        my @biggestbox = splice( @boxes, $boxtocut * 4, 4 );

        #now sort on the axis
        $sortedcolours = sortonaxes( $biggestbox[1], $biggestbox[2] );
        my @sortedcolours = @$sortedcolours;
        $median = POSIX::floor( scalar(@sortedcolours) / 2 );

        #cut the colours in half
        my @lowercolours = splice( @sortedcolours, 0, $median );

        #generate two boxes
        my $refboxa = generate_box(@lowercolours);
        push @boxes, $refboxa;
        push @boxes, \@lowercolours;
        push @boxes, getaxis_details($refboxa);
        my $refboxb = generate_box(@sortedcolours);
        push @boxes, $refboxb;
        push @boxes, \@sortedcolours;
        push @boxes, getaxis_details($refboxb);
        $colcount = scalar(@boxes) / 4;
    } until ( $colourspaces == $colcount );
    return getpalette(@boxes);
}

sub dither {

    #implement Floyd - Steinberg error diffusion dither
    my ( $linelength, $rcomp, $gcomp, $bcomp,     $palnumber );
    my ( $rp,         $rg,    $rb,    $max_value, $currentoffset_w );
    my ( $currentoffset_h, $nextoffset_h, $ll );

    my (
        $colour,    $unfiltereddata, $cdepth,     $ndepth,
        $linesdone, $pixelpoint,     $totallines, $pallookref,
        $paloutref, $pal_chunk,      $width
    ) = @_;
    $linelength = $width * $cdepth + 1;

    #FIXME not just 24 bit depth
    ( $rcomp, $gcomp, $bcomp ) = convert_toxyz($colour);
    $palnumber = $pallookref->{$colour};
    if ( !$palnumber ) {
        $palnumber = closestmatch_inRGB( $paloutref, $rcomp, $gcomp, $bcomp );
    }

    ( $rp, $rg, $rb ) = unpack( "C3", substr( $pal_chunk, $palnumber * 3, 3 ) );

    #calculate the errors
    my @colerror = ( $rcomp - $rp, $gcomp - $rg, $bcomp - $rb );

    #now diffuse the errors
    if ( $cdepth >= 6 ) {
        $max_value = 0xFFFF;
    }
    else {
        $max_value = 0xFF;
    }
    $currentoffset_w = $pixelpoint * $cdepth;
    $currentoffset_h = $linesdone * $linelength;
    $nextoffset_h    = ( $linesdone + 1 ) * $linelength;
    for ( $ll = 0 ; $ll < $ndepth ; $ll++ ) {
        if ( $colerror[$ll] == 0 ) {
            next;
        }
        my $sign = 1;
        if ( $colerror[$ll] < 1 ) {
            $sign = -1;
            $colerror[$ll] = abs( $colerror[$ll] );
        }
        if ( ( $pixelpoint + 1 ) < $width ) {
            my $unpacked = unpack(
                "C",
                substr(
                    $unfiltereddata,
                    $currentoffset_w + $currentoffset_h + 1 + $cdepth + $ll, 1
                )
            );

            $unpacked += ( ( $colerror[$ll] * 7 ) >> 4 ) * $sign;
            if ( $unpacked > $max_value ) {
                $unpacked = $max_value;
            }
            elsif ( $unpacked < 0 ) {
                $unpacked = 0;
            }
            substr( $unfiltereddata,
                $currentoffset_w + $currentoffset_h + 1 + $cdepth + $ll, 1 )
              = pack( "C", $unpacked );
            if ( ( $linesdone + 1 ) < $totallines ) {
                $unpacked = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        $currentoffset_w + ( ( $linesdone + 1 ) * $linelength )
                          + 1 + $cdepth + $ll,
                        1
                    )
                );
                $unpacked += ( $colerror[$ll] >> 4 ) * $sign;
                if ( $unpacked > $max_value ) {
                    $unpacked = $max_value;
                }
                elsif ( $unpacked < 0 ) {
                    $unpacked = 0;
                }
                substr( $unfiltereddata,
                    $currentoffset_w + $nextoffset_h + 1 + $cdepth + $ll, 1 )
                  = pack( "C", $unpacked );
            }
        }
        if ( ( $linesdone + 1 ) < $totallines ) {
            my $unpacked = unpack(
                "C",
                substr(
                    $unfiltereddata, $currentoffset_w + $nextoffset_h + 1 + $ll,
                    1
                )
            );
            $unpacked += ( ( $colerror[$ll] * 5 ) >> 4 ) * $sign;
            if ( $unpacked > $max_value ) {
                $unpacked = $max_value;
            }
            elsif ( $unpacked < 0 ) {
                $unpacked = 0;
            }
            substr( $unfiltereddata, $currentoffset_w + $nextoffset_h + 1 + $ll,
                1 )
              = pack( "C", $unpacked );
            if ( $pixelpoint > 0 ) {
                $unpacked = unpack(
                    "C",
                    substr(
                        $unfiltereddata,
                        $currentoffset_w + $nextoffset_h + 1 - $cdepth + $ll, 1
                    )
                );
                $unpacked += ( ( $colerror[$ll] * 3 ) >> 4 ) * $sign;
                if ( $unpacked > $max_value ) {
                    $unpacked = $max_value;
                }
                elsif ( $unpacked < 0 ) {
                    $unpacked = 0;
                }
                substr( $unfiltereddata,
                    $currentoffset_w + $nextoffset_h + 1 - $cdepth + $ll, 1 )
                  = pack( "C", $unpacked );
            }
        }
    }
    return ( $palnumber, $unfiltereddata );
}

sub palettize {

    # take PNG and count colours
    my ( $pal_chunk, $x, $colourfound );
    my $palnumb;
    my ( $chunklength, $chunktocopy );
    my ( $palcount, $pal_crc, $len_pal, $dataout, $linesdone, $totallines );
    my ( $width, $linelength, $colour, $palnumber );
    my ( $pixelpoint, $linemarker, $rfc1950stuff, $rfc1951stuff, $output );
    my ( $newlength, $outcrc, $processedchunk );
    my $bdepth;

    my $blobin = shift;

    #is it a PNG
    return $blobin unless ispng($blobin) > 0;

    #is it already palettized?
    return $blobin unless ispalettized($blobin) < 1;
    my $colour_limit = shift;

    #0 means no limit
    $colour_limit = 0 unless $colour_limit;
    my $dither = shift;
    $dither = 0 unless $dither;
    my $filtereddata   = getuncompressed_data($blobin);
    my $ihdr           = getihdr($blobin);
    my $unfiltereddata = unfilter( $filtereddata, $ihdr );
    my ( $colours, $colourlist ) = countcolours( $unfiltereddata, $ihdr );
    if ( $colours < 1 ) {
        return $blobin;
    }
    if (
        ( $colours < 256 )
        && (   ( $colours < $colour_limit )
            || ( $colour_limit == 0 ) )
      )
    {
        return indexcolours($blobin);
    }
    if ( $colour_limit > 256 ) {
        return undef;
    }
    my ( $paloutref, $pallookref ) =
      index_mediancut( $colourlist, $colour_limit );

    #have to rewrite the whole thing now
    #start with the PNG header
    my $blobout = pack( "C8", ( 137, 80, 78, 71, 13, 10, 26, 10 ) );

    my ( $cdepth, $alpha ) = comp_width($ihdr);
    my $ndepth = $cdepth;
    if ($alpha) {

        #truecolour first
        if ( $cdepth == 4 ) {
            $bdepth = $ihdr->{"bitdepth"};
            if ( $bdepth == 8 ) {
                $ndepth = 3;
            }
            else {
                $ndepth = 2;
            }
        }
        elsif ( $cdepth == 8 ) {
            $ndepth = 6;
        }

        #now greyscale
        elsif ( $cdepth == 2 ) {
            $ndepth = 1;
        }
    }

    #now the IHDR
    $blobout = $blobout . pack( "N", 0x0D );
    my $ihdr_chunk = "IHDR";
    $ihdr_chunk = $ihdr_chunk
      . pack( "N2", ( $ihdr->{"imagewidth"}, $ihdr->{"imageheight"} ) );

    #FIXME: Support index of less than 8 bits
    $ihdr_chunk = $ihdr_chunk . pack( "C2", ( 8, 3 ) );    #8 bit indexed colour
    $ihdr_chunk = $ihdr_chunk
      . pack( "C3",
        ( $ihdr->{"compression"}, $ihdr->{"filter"}, $ihdr->{"interlace"} ) );
    my $ihdrcrc = crc32($ihdr_chunk);
    $blobout = $blobout . $ihdr_chunk . pack( "N", $ihdrcrc );

    #now any chunk before the IDAT
    my $searchindex = 16 + 13 + 4 + 4;
    my $pnglength   = length($blobin);
    my $foundidat   = 0;
    while ( $searchindex < ( $pnglength - 4 ) ) {

        #Copy the chunk
        $chunklength = unpack( "N", substr( $blobin, $searchindex - 4, 4 ) );
        $chunktocopy = substr( $blobin, $searchindex - 4, $chunklength + 12 );
        if ( substr( $blobin, $searchindex, 4 ) eq "IDAT" ) {
            if ( $foundidat == 0 ) {    #ignore any additional IDATs
                                        #now the palette chunk
                $pal_chunk = "";
                my @colourlist = @$paloutref;
                $palcount = 0;
                foreach $x (@colourlist) {
                    $pal_chunk = $pal_chunk . pack( "C", $x );
                }
                $pal_crc = crc32( "PLTE" . $pal_chunk );
                $len_pal = length($pal_chunk);
                $blobout = $blobout
                  . pack( "N", $len_pal ) . "PLTE"
                  . $pal_chunk
                  . pack( "N", $pal_crc );

                #now process the IDAT
                $linesdone  = 0;
                $totallines = $ihdr->{"imageheight"};
                $width      = $ihdr->{"imagewidth"};

                $linelength = $width * $cdepth + 1;
                my %colourlookup = %{$pallookref};
                while ( $linesdone < $totallines ) {
                    $dataout    = $dataout . "\0";
                    $pixelpoint = 0;
                    $linemarker = $linesdone * $linelength + 1;
                    while ( $pixelpoint < $width ) {
                        $colourfound =
                          substr( $unfiltereddata,
                            ( $pixelpoint * $cdepth ) + $linemarker, $ndepth );
                        $colour = 0;
                        for ( $x = 0 ; $x < $ndepth ; $x++ ) {
                            $colour =
                              ( $colour << 8 |
                                  ord( substr( $colourfound, $x, 1 ) ) );
                        }
                        if ( $dither == 1 ) {

                            #add the new
                            #match to
                            #the palette if
                            #required
                            ( $palnumb, $unfiltereddata ) = dither(
                                $colour,     $unfiltereddata, $cdepth,
                                $ndepth,     $linesdone,      $pixelpoint,
                                $totallines, \%colourlookup,  $paloutref,
                                $pal_chunk,  $width
                            );
                            if ( !$colourlookup{$colour} ) {
                                $colourlookup{$colour} = $palnumb;
                            }
                        }
                        $dataout =
                          $dataout . pack( "C", $colourlookup{$colour} );
                        $pixelpoint++;
                    }
                    $linesdone++;
                }

                #now to deflate $dataout to get proper stream
                $rfc1950stuff = pack( "C2", ( 0x78, 0x5E ) );
                $rfc1951stuff =
                  shrinkchunk( $dataout, Z_DEFAULT_STRATEGY, Z_BEST_SPEED );
                $output = "IDAT"
                  . $rfc1950stuff
                  . $rfc1951stuff
                  . pack( "N", adler32($dataout) );
                $newlength = length($output) - 4;
                $outcrc    = crc32($output);
                $processedchunk =
                  pack( "N", $newlength ) . $output . pack( "N", $outcrc );
                $chunktocopy = $processedchunk;
                $foundidat   = 1;
            }
            else {
                $chunktocopy = "";
            }
        }
        $blobout = $blobout . $chunktocopy;
        $searchindex += $chunklength + 12;
    }
    return $blobout;
}

sub analyze {
    my ( $chunk_desc, $chunk_text, $chunk_length, $chunk_crc );
    my ( $crit_status, $pub_status, @chunk_array, $searchindex, $pnglength );
    my ( $chunk_crc_checked, $nextindex );
    my $blob = shift;

    #is it a PNG?
    if ( Image::Pngslimmer::ispng($blob) < 1 ) {

        #no it's not, so return a simple array stating so
        push( @chunk_array, "Not a PNG file" );
        return @chunk_array;
    }

    #ignore signature - it's not a chunk
    #so straight to IHDR
    $searchindex = 12;
    $pnglength   = length($blob);
    while ( $searchindex < ( $pnglength - 4 ) ) {

        #get datalength
        $chunk_length = unpack( "N", substr( $blob, $searchindex - 4, 4 ) );

        #name of chunk
        $chunk_text = substr( $blob, $searchindex, 4 );

        #chunk CRC
        $chunk_crc =
          unpack( "N", substr( $blob, $searchindex + $chunk_length, 4 ) );

        #is CRC correct?
        $chunk_crc_checked = checkcrc( substr( $blob, $searchindex - 4 ) );

        #critcal chunk?
        $crit_status = 0;
        if ( ( ord($chunk_text) & 0x20 ) == 0 ) {
            $crit_status = 1;
        }

        #public or private chunk?
        $pub_status = 0;
        if ( ( ord( substr( $blob, $searchindex + 1, 1 ) ) & 0x20 ) == 0 ) {
            $pub_status = 1;
        }
        $nextindex  = $searchindex - 4;
        $chunk_desc = $chunk_text
          . " begins at offset $nextindex has data length "
          . $chunk_length
          . " with CRC $chunk_crc";
        if ( $chunk_crc_checked == 1 ) {
            $chunk_desc = $chunk_desc . " and the CRC is good -";
        }
        else {
            $chunk_desc = $chunk_desc . " and there is an ERROR in the CRC -";
        }
        if ( $crit_status > 0 ) {
            $chunk_desc =
              $chunk_desc . " the chunk is critical to the display of the PNG";
        }
        else {
            $chunk_desc = $chunk_desc
              . " the chunk is not critical to the display of the PNG";
        }
        if ( $pub_status > 0 ) {
            $chunk_desc = $chunk_desc . " and is public\n";
        }
        else {
            $chunk_desc = $chunk_desc . " and is private\n";
        }
        push( @chunk_array, $chunk_desc );
        $searchindex += $chunk_length + 12;
    }
    return @chunk_array;
}

1;
__END__

=pod

=head1 NAME

Image::Pngslimmer - slims (dynamically created) PNGs

=head1 SYNOPSIS

	$ping = ispng($blob)				#is this a PNG? 
							$ping == 1 if it is
	$newblob = discard_noncritical($blob)  		#discard non critcal
							chunks and return a new
							PNG
	my @chunklist = analyze($blob) 			#get the chunklist as
							an array
	$newblob = zlibshrink($blob)			#attempt to better
							compress the PNG
	$newblob = filter($blob)			#apply adaptive
							filtering and then
							compress
	$newblob = indexcolours($blob)			#attempt to replace
							RGB IDAT with palette
							(usually losslessly)
	$newblob = palettize($blob[, $colourlimit
					[, $dither]])	#replace RGB IDAT with
							colour index palette
							(usually lossy)
	\%colourhash = reportcolours($blob)		#return details of the
							colours in the PNG
	

=head1 DESCRIPTION

Image::Pngslimmer aims to cut down the size of PNGs. Users pass a PNG to
various functions and a slimmer version is returned. Image::Pngslimmer
was designed for use where PNGs are being generated on the fly and where size
matters more than speed- eg for J2ME use or any similiar low speed or high
latency environment. There are other options - probably better ones - for
handling static PNGs, though you may still find the fuctions useful.

Filtering and recompressing an image is not fast - for example on a 4300
BogoMIPS box with 1G of memory the author processes PNGs at about 30KB per
second.

=head2 Functions

Call Image::Pngslimmer::discard_noncritical($blob) on a stream of bytes
(eg as created by Perl Magick's Image::Magick package) to remove sections of
the PNG that are not essential for display.

Do not expect this to result in a big saving - the author suggests maybe
200 bytes is typical - but in an environment such as the backend of J2ME
applications that may still be a worthwhile reduction.

Image::Pngslimmer::discard_noncritical($blob) will call ispng($blob) before
attempting to manipulate the supplied stream of bytes - hopefully, therefore,
avoiding the accidental mangling of JPEGs or other files. ispng checks for PNG
definition conformity - it looks for a correct signature, an image header
(IHDR) chunk in the right place, looks for (but does not check beyond the CRC)
an image data (IDAT) chunk and checks there is an end (IEND) chunk in the right
place. CRCs are also checked throughout.

Image::Pngslimmer::analyze($blob) is supplied for completeness and to aid
debugging. It is not called by discard_noncritical but may be used to show
'before-and-after' to demonstrate the savings delivered by discard_noncritical.

Image::Pngslimmer::zlibshrink($blob) will attempt to better compress the
supplied PNG and will achieve good results with poorly compressed PNGs.

Image::Pngsimmer::filter($blob) will attempt to apply adaptive filtering to the
PNG - filtering should deliver better compression results (though the results
can be mixed).  Please note that filter() will compress the image with
Z_BEST_SPEED and so the blob returned from the function may even be larger
than the blob passed in. You must call zlibshrink if you want to recompress
the blob at maximum level. All PNG compression and filtering is lossless.

Image::Pngslimmer::indexcolours($blob) will attempt to replace an RGB image
with a colourmapped image. NB This is not the same as quantization - this
process is lossless, but also only works if there are less than 256 colours
in the image.

(indexcolours now supports PNGs with alpha channels but all alpha information
is lost in the indexed PNG.)

Image::Pngslimmer::palettize($blob[, $colourlimit[, $dither]]) will replace a
24 bit RGB image with a colourmapped (256 or less colours) image. If the
original image has less than $colourlimit colours it will do this by calling
indexcolours and so losslessly (except for any alpha channel)process the image.
More generally it will process the image using the lossy median cut algorithm.
Currently this only works for 24 bit images, though now also supports the alpha
channel (ie the alpha channel is accounted for in quantization - there is no
alpha in the quantized image). Again this process is relatively slow - the
author can process images at about 30 - 50KB per second - meaning it can be
used for J2ME in "real time" but is likely to be too slow for many other
dynamic uses. Setting $colourlimit between 1 and 255 allows control over the
size of the generated palette (the default is 0 which generates a 256 colour
palette). Setting $dither to 1 will turn on the much slower dithering. It is
not recommended for anything that requires quick image display.

$hashref  = Image::Pngslimmer::reportcolours($blob) will return a reference to
a hash with a frequency table of the colours in the image.

=head1 LICENCE AND COPYRIGHT

This is free software and is licensed under the same terms as Perl itself
ie Artistic and GPL

It is copyright (c) Adrian McMenamin, 2006, 2007, 2008

=head1 REQUIREMENTS

	POSIX
	Compress::Zlib
	Compress::Raw::Zlib

=head1 TODO

To make Pngslimmer really useful it needs to handle a broader range of bit map
depths etc. The work goes on and the range of PNG types supported is growing.
But at the moment it really only works well with 24 bit images (though 
discard_noncritical will work with all PNGs).

=head1 AUTHOR

	Adrian McMenamin <adrian AT mcmen DOT demon DOT co DOT uk>

=head1 SEE ALSO

	Image::Magick

=cut

