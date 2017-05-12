#!perl
#
#   Most of this script has been copied from another source, and some of
#   the content has been modified to fit a particular purpose.
#
#   The web page that hosts the original source is all in japanese,
#   but it does say this at the bottom:
#   Copyright(C) COCKY(cocky@cocky.to), All Rights Reserved. 
#
#   So, inclusion of this script may violate a copyright somewhere.
#   I'd suggest that you do *not* assume that you can distribute this
#   file under the same terms as PERL itself.  It's probably a bad idea.
#   Don't do that.
#
#   Here's the original file header:
#
#   MNGcount Plus Ver.0.02
#      akihiro@ua.airnet.ne.jp
#      http://www5.airnet.ne.jp/dct/
#
#      Last Modified: 2000/11/16
#

use strict;
use Test;
BEGIN { plan tests => 1 };

use CGI;
use constant OUTFILE => 'counter.mng';
use constant COUNT   => 'count.txt';
ok(1);

# global variables
my $oldcount = time();
my $count    = $oldcount+1;

# more global variables
my $PLTE = "";      
my $tRNS = "";      

# horizontal or vertical counter?
my $vstyle = 0;

main();
exit(0);


sub max { return $_[0] > $_[1] ? $_[0] : $_[1]; }
sub min { return $_[0] < $_[1] ? $_[0] : $_[1]; }

#---------------------------------------------------------------------------
sub get_filename($)
{
   my ($fn) = @_;
   my ($match) = grep { -r $_ } ( $fn, "t/$fn" );
   return $match || ( -d 't' ? "t/$fn" : $fn );
}

#---------------------------------------------------------------------------
sub get_count($)
{
   my ( $fn ) = @_;
   my $count = 0;
   if( open(CNT, get_filename($fn)) )
   {
      $count = <CNT>;
      close CNT;
   }
   return $count;
}

#---------------------------------------------------------------------------
sub main
{
   my $width_all   = 0; 
   my $height_all  = 0; 
   my $height_this = 0;
   my $width_this  = 0;
   my $firstmove   = 0;
   my $object_id   = 0; 
   my @datagram;
   my $row;
   my $non_cgi = !defined $ENV{'DOCUMENT_ROOT'};

   if ( $non_cgi )
   {
      $oldcount = get_count(COUNT);
      $count    = $oldcount+1;
   }

   # figure out how many columns we have
   my $query = new CGI;
   $row = $query->param( 'row' ) || length( $count );
   $row = 100 if ( $row > 100 );

   if ( defined $query->param('vstyle') )
   {
      $vstyle = $query->param('vstyle');
   }


   # get the characters of the numbers into same-sized arrays
   my @count    = split('', sprintf("%0${row}d", $count   ) );
   my @oldcount = split('', sprintf("%0${row}d", $oldcount) );

   # Add all of the needed numbers (from the PNG files) into this MNG file as objects
   foreach my $num ( @count ) {
      $object_id++;
      my $oldnum = $oldcount[ $object_id - 1 ];
      my $numChanged = ($num ne $oldnum) ? 1 : 0;
      my @files = ($oldnum,$num);
      my $tmp;

      # make an image definition for the number(s) to display.
      # if the number will change, also make a definition for the new image.
      for my $changed ( reverse(0..$numChanged) )
      {
         $firstmove ||= $object_id if $changed;

         $tmp = read_file(@files->[$changed]);
         next if( $tmp !~ /^\x89PNG/ );   

         push( @datagram, &makeDEFI( $object_id + $changed*100, $width_all, $height_all ) );
         push( @datagram, &GetPNGinfo( $tmp, \$width_this, \$height_this ) );

         {
            if( $vstyle ) { 
               $width_all = max($width_all,$width_this);
               $height_all += $height_this if !$changed;
            }
            else {
               $width_all += $width_this if !$changed;
               $height_all = max($height_all,$height_this);
            }
         }
      }
   }


   # start a frame, specify no background except for one ahead of the very first image
   push( @datagram, &makechunk( 'FRAM', pack( "C", 2 ) ) );      

   # move the "special" images (down) out of the clipping area
   # now they no longer overlap the original numbers
   push( @datagram, &makeMOVE( 101, 200, 1, $vstyle ? $width_all : 0, $vstyle ? 0 : $height_all ) );

   # show all objects inside of the clipping range
   push( @datagram, &makeSHOW( 1, 200, 0 ) );                  

   # now define a loop to execute the animation (length = height in pixels)
   my $loop = pack( "C", 1 ) . pack( "N", $vstyle ? $width_all : $height_all );
   push( @datagram, &makechunk( 'LOOP', $loop ) );

   # start a frame, do not change framing mode
   push( @datagram, &makechunk( 'FRAM', pack( "C", 0 ) ) );


   # =======================================================
   # = this moves the images "up", one pixel at a time.
   # =======================================================

   # move all "source" objects that must change, starting with the first object
   # base movement from parent object, move deltaY=-1
   push( @datagram, &makeMOVE( $firstmove, 100, 1, $vstyle ? -1 : 0, $vstyle ? 0 : -1 ) );

   # move all "dest" objects that must change, starting with the first object
   # base movement from parent object, move deltaY=-1
   push( @datagram, &makeMOVE( 101, 200, 1, $vstyle ? -1 : 0, $vstyle ? 0 : -1 ) );

   # =======================================================



   # show all objects inside of the clipping range
   push( @datagram, &makeSHOW( 1, 200, 0 ) );

   # end the loop (at depth level 1)
   push( @datagram, &makechunk( 'ENDL', pack( "C", 1 ) ) ); 

   # make a header for this file
   unshift( @datagram, &MakeHeader($width_all,$height_all) );

   # provide an end chunk
   push( @datagram, &makechunk( 'MEND', "" ) ); 

   # make browsers happy with a correct content length 
   my $content = join('', @datagram);
   my $length = length($content);



   if ( !$ENV{'DOCUMENT_ROOT'} )
   {
      my $outfile = get_filename($ARGV[0] || OUTFILE());
      print "Writing file $outfile\n";
      open(FILE, ">$outfile") || die "Can't open $outfile for writing\n";
      binmode FILE;
      print FILE $content;
      close FILE;
   }
   else
   {
      print "Content-Length: $length\n";     # correct content length for this file
      print "Content-type: video/x-mng\n";   # Content-type for MNG
      print "\n";                            # MIME Header needs an extra return
      print $content;                        # send the file
   }
      
}


#---------------------------------------------------------------------------
sub read_file
{  # PNG Mode
   my ( $file ) = @_;

   # added to make sure that 0..9.png exists!
   make_numbers() unless ( -r "$file.png" );

   open( GH, get_filename("$file.png") ) || die "Can't open file $file.png\n";
   binmode GH;
   local ( $/ ) = undef;
   my $content = <GH>;
   close( GH );
   return $content;
}

#---------------------------------------------------------------------------
# generate the CRC Table
sub MakeCrcTable(){
   my $crc;
   my @crc_table;

   @crc_table = ();
   for(0 .. 255){
      $crc = $_;
      for(0 .. 7){
         if( $crc & 1 ){
            $crc = 0xedb88320 ^ ($crc >> 1);
         }
         else{
            $crc = $crc >> 1;
         }
      }
      $crc_table[$_] = $crc;
   }

   return @crc_table;
}

#---------------------------------------------------------------------------
# calculate a CRC
{
   # private variable
   my @crc_table;

   sub calculatecrc {
      my( $buf ) = @_;
      my $crc;

      @crc_table = &MakeCrcTable() unless @crc_table;

      $crc = 0xffffffff;
      foreach( unpack( 'C*', $buf ) ){
         $crc = $crc_table[ ( $crc ^ $_ ) & 0xff ] ^ ( $crc >> 8 );
      }
      $crc = ~$crc;
      $crc = pack( "N", $crc );

      return $crc;
   }
}


#---------------------------------------------------------------------------
sub GetPNGinfo {
   my( $tmp, $widthRef, $heightRef ) = @_;
 # my( $tmp ) = @_;

   my $png = substr( $tmp, 8 );
   my $dists = $png;

   while( length( $png ) ) {
      my $block_size = substr( $png, 0, 4 );
      my $chunk_type = substr( $png, 4, 4 );
      $block_size = unpack( "N", $block_size );
      my $chunk_data = substr( $png, 8, $block_size );
      if( $chunk_type eq "IHDR" || $chunk_type eq "JHDR" ) {
         my $width    = substr( $chunk_data, 0, 4 );
         my $height   = substr( $chunk_data, 4, 4 );
         $$widthRef   = unpack( "N", $width );
         $$heightRef  = unpack( "N", $height );
      }
      elsif( $chunk_type eq "PLTE" ) {
         $PLTE = substr( $png, 0, $block_size + 12 );
      }
      elsif( $chunk_type eq "tRNS" ) {
         $tRNS = substr( $png, 0, $block_size + 12 );
      }
      $png = substr( $png, $block_size + 12 );
   }

   $dists;
}

#---------------------------------------------------------------------------
sub makechunk {
   my($chunk_type, $chunk_data) = @_;

   my $size  = pack( "N", length( $chunk_data ) );
   my $tmp   = $chunk_type. $chunk_data;
   my $dists = $size. $tmp. &calculatecrc( $tmp );

   return $dists;
}

#---------------------------------------------------------------------------
sub makeDEFI {
   my ($object_id, $xpos, $ypos ) = @_;
   my ($dists, $chunk_data);

   $chunk_data  = pack( "n", $object_id );
   $chunk_data .= pack( "C", 1 );
   $chunk_data .= pack( "C", 1 );

   $chunk_data .= pack( "N", $vstyle ?     0 : $xpos );
   $chunk_data .= pack( "N", $vstyle ? $ypos :     0 );

   $dists = &makechunk( 'DEFI', $chunk_data );

   return $dists;
}

#---------------------------------------------------------------------------
sub MakeHeader {
   my ( $width, $height ) = @_;

   my $dists = "\x8aMNG\x0d\x0a\x1a\x0a";

   $dists .= &makeMHDR($width, $height);

   # show the last frame indefinitely
   $dists .= &makechunk( 'TERM', pack( "C", 0 ) );

   # if we picked up a palette or transparency information from the PNG files, include it now.
   {  # PNG mode
      $dists .= $PLTE;
      $dists .= $tRNS;
   }

   $dists;
}

#---------------------------------------------------------------------------
sub makeMHDR {
   my ( $width, $height ) = @_;
   my ($dists, $chunk_data, $crc);

   $chunk_data = pack( "N", $width );
   $chunk_data .= pack( "N", $height );
   $chunk_data .= pack( "N", 30 );
   $chunk_data .= pack( "N", 0 );
   $chunk_data .= pack( "N", 0 );
   $chunk_data .= pack( "N", 0 );
   {  # PNG mode
      $chunk_data .= pack( "N", 15 );
   }

   $dists = &makechunk( 'MHDR', $chunk_data );

   return $dists;
}

#---------------------------------------------------------------------------
sub makeMOVE {
   my( $first_id, $last_id, $delta_type, $x, $y ) = @_;
   my ($dists,$chunk_data);

   $chunk_data  = pack( "n", $first_id );
   $chunk_data .= pack( "n", $last_id );
   $chunk_data .= pack( "C", $delta_type );
   $chunk_data .= pack( "N", $x );
   $chunk_data .= pack( "N", $y );

   $dists = &makechunk( 'MOVE', $chunk_data );

   return $dists;
}

#---------------------------------------------------------------------------
sub makeSHOW {
   my( $first_id, $last_id, $show_mode ) = @_;
   my ($dists,$chunk_data);

   $chunk_data  = pack( "n", $first_id );
   $chunk_data .= pack( "n", $last_id )    if ( ($last_id != $first_id) || $show_mode);
   $chunk_data .= pack( "C", $show_mode )  if ( $show_mode );

   $dists = &makechunk( 'SHOW', $chunk_data );

   return $dists;
}

#---------------------------------------------------------------------------
sub make_numbers
{
   eval { require Gd; };
   if ( $@ )
   {
      warn $@;
      warn "You do not have Gd installed on your system.  I can't make the support files\n";
      return;
   }

   use Gd;
   use constant FONTCOLOR => (  0,  0,  0);
   use constant CLEAR     => (255,255,255);
   use constant FONTDIR   => 'c:/windows/fonts';
   use constant FONTFACE  => (grep { -r } map { FONTDIR."/$_" } ('comic.ttf','cour.ttf','times.ttf'))[0];
   use constant FONTSIZE  => 16;
   use constant HEIGHT    => 21;
   use constant WIDTH     => HEIGHT * 0.70;
   use constant INTERLACE => 0;

   foreach my $num ( 0..9 )
   {
      my $file = get_filename("$num.png");
      next if -r $file;

      my $number    = new GD::Image( WIDTH, HEIGHT );
      my $fontcolor = $number->colorResolve(FONTCOLOR);
      my $clear     = $number->colorResolve(CLEAR);

      $number->filledRectangle(0,0,WIDTH,HEIGHT,$clear);

   #  yucky, bad things happen when we turn this on...
   #  $number->transparent($clear);
      $number->interlaced( INTERLACE );


      # add the text to the office space
      $number->stringTTF( $fontcolor, 
                          FONTFACE,
                          FONTSIZE,
                          0,              # rotation
                          0,              # x-position
                          0.85 * HEIGHT,  # y-position
                          $num,
                        );
      local(*FILE);
      open(FILE, ">$file");
      binmode FILE;
      print FILE $number->png();
      close FILE;
   }
}

