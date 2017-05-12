#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# =======================================================================
# The code used in this test script to generate an MNG file
# is a variant of the code from the following source:
#
#   MNGcount Plus Ver.0.02
#      akihiro@ua.airnet.ne.jp
#      http://www5.airnet.ne.jp/dct/
# =======================================================================



#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 52 };
use Graphics::MNG;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Graphics::MNG qw( :util_fns :chunk_names MNG_FUNCTIONINVALID MNG_ACCESS_CHUNKS MNG_STORE_CHUNKS );
ok(1);   # loaded an export-ok constant

use FileHandle;
use Cwd;
use Data::Dumper;
use constant FILENAME  => 'tmpfile1.mng';
use constant CHECKNAME => 'counter.mng';
use constant COUNT     => 'count.txt';

# global variables
my $oldcount = 1003875892;   # has to match test graphic
my $count    = $oldcount+1;


# horizontal or vertical counter?
my $vstyle = 0;

# array of PNG objects to insert into our MNG stream
my @png_objects;
my @count;
my @oldcount;


if ( !MNG_ACCESS_CHUNKS || !MNG_STORE_CHUNKS )
{
   my $msg = <<EOF;
   Your version of libmng is not built with both MNG_ACCESS_CHUNKS
   and MNG_STORE_CHUNKS defined.  This test requires those features.
   Please adjust compiler definitions in Makefile.PL and/or rebuild
   your version of libmng with these options
EOF

   print $msg;
   warn $msg;
   exit(0);
}


# open(STDERR,">log1.txt");
main();
exit(0);


#---------------------------------------------------------------------------
sub max { return $_[0] > $_[1] ? $_[0] : $_[1]; }

#---------------------------------------------------------------------------
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
   my $rv;

   # set up our counts
   $oldcount = get_count(COUNT);
   $count    = $oldcount+1;

   # figure out how many columns we have
   my $row = min(100, length( $count ));

   # get the characters of the numbers into same-sized arrays
   @count    = split('', sprintf("%0${row}d", $count   ) );
   @oldcount = split('', sprintf("%0${row}d", $oldcount) );

   my %hash = map { $_ => 1 } ( @count, @oldcount );

   # sparsly populate our object array
   foreach my $num (keys %hash)
   {
      ( $rv, @png_objects->[$num] ) =
         FileReadChunks(get_filename("$num.png"));
      last unless $rv==MNG_NOERROR;
   }
   ok($rv,MNG_NOERROR,"reading in all PNG files");

   $rv = writefile(FILENAME);
   ok($rv,MNG_NOERROR,"writing the MNG file");

   ($rv) = FileReadChunks(get_filename(FILENAME));
   ok($rv,MNG_NOERROR,"re-read the MNG file");

   $rv = compare_files( FILENAME, CHECKNAME );
   ok($rv,0,"in/out file comparsion");

   # clean up
   unlink( get_filename(FILENAME) );
}


#---------------------------------------------------------------------------
sub compare_files
{
   use FileHandle;
   my ( $f1, $f2 ) = @_;

   return "missing $f1" unless ( -e get_filename($f1) );
   return "missing $f2" unless ( -e get_filename($f2) );

   local ( $/ ) = undef;
   my @data;

   foreach my $fn ( map { get_filename($_) } ( $f1, $f2 ) )
   {
      my $fh = new FileHandle($fn);
      if ( $fh )
      {
         binmode $fh;
         my $data = <$fh>;
         push( @data, $data );
      }
      undef $fh;
   }

   warn("Didn't read both files $f1 and $f2\n") unless ( @data >= 2 );
   warn("Length of $f1 != length of $f2\n")
      if ( length($data[0]) != length($data[1]) );

   my $rv = $data[0] cmp $data[1];
   return $rv;
}


#---------------------------------------------------------------------------
sub writefile
{
   my ($outfile)  = @_;
   my $firstmove  = 0;
   my $object_id  = 0; 
   my $height_all = 0;
   my $width_all  = 0;
   my $rv;
   my $PLTE;
   my $tRNS;


   # get information about the PNG images
   foreach my $obj ( @png_objects )
   {
      next unless defined $obj;
      my $userdata    = $obj->get_userdata();
      my $width_this  = $userdata->{'width'};
      my $height_this = $userdata->{'height'};

      $width_all  = max($width_all,$width_this);
      $height_all = max($height_all,$height_this);

      $PLTE = @{ $userdata->{'PLTE'} || [] }->[-1];
      $tRNS = @{ $userdata->{'tRNS'} || [] }->[-1];
   }

   # now scale these numbers vertically or horizontally
   $height_all *= int @count if( $vstyle );
   $width_all  *= int @count if( !$vstyle );

   # now make the object
   my $obj = new Graphics::MNG();

   # hook up the callbacks
   $rv = $obj->set_userdata( { 'filename' => $outfile,
                               'fh'       => undef,
                               'fperms'   => 'w',
                               'width'    => 0,
                               'height'   => 0,
                             } );
   ok($rv,MNG_NOERROR,"setting userdata");

   $rv = $obj->setcb_openstream   ( \&FileOpenStream );
   ok($rv,MNG_NOERROR,"registering the openstream callback");

   $rv = $obj->setcb_closestream  ( \&FileCloseStream );
   ok($rv,MNG_NOERROR,"registering the closestream callback");

   $rv = $obj->setcb_writedata    ( \&FileWriteData );
   ok($rv,MNG_NOERROR,"registering the filewritedata callback");

   # indicate that we're going to make a new file...
   $rv = $obj->create();
   ok($rv,MNG_NOERROR,"creating the file");

   # now insert the header information
   $rv = $obj->putchunk_info( MNG_UINT_MHDR, { iWidth => $width_all, iHeight => $height_all, iTicks => 30, iSimplicity => 15 } );
   ok($rv,MNG_NOERROR,"writing mhdr"); 

   $rv = $obj->putchunk_info( MNG_UINT_TERM );
   ok($rv,MNG_NOERROR,"writing term"); 


   # if we picked up a palette or transparency information from the PNG files, include it now.
   $rv = $obj->putchunk_info($PLTE) if ( $PLTE );
   ok($rv,MNG_NOERROR,"writing plte"); 
   
   $rv = $obj->putchunk_info($tRNS) if ( $tRNS );
   ok($rv,MNG_NOERROR,"writing trns"); 


   # Add all of the needed numbers (from the PNG files) into this MNG file as objects
   my $xpos   = 0; 
   my $ypos  = 0; 
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

         $rv = $obj->putchunk_info( MNG_UINT_DEFI,
                                    {
                                       iObjectid  => $object_id + $changed*100,
                                       iDonotshow => 1,
                                       iConcrete  => 1,
                                       bHasloca   => MNG_TRUE,
                                       iXlocation => $vstyle ? 0 : $xpos,
                                       iYlocation => $vstyle ? $ypos : 0,
                                    }
                                  );
         ok($rv,MNG_NOERROR,"writing defi chunk"); 

         # this will magically insert all of the chunks
         my $pngfile =  @files->[$changed];
         my ( $rv, $width_this, $height_this ) = insert_chunks($obj, $pngfile);
         ok($rv,MNG_NOERROR,"inserted file $num-$changed"); 

         if ( !$changed )
         {
            $ypos += $height_this if ( $vstyle );
            $xpos += $width_this  if ( !$vstyle );
         }

         last unless $rv==MNG_NOERROR;
      }
   }


   # start a frame, specify no background except for one ahead of the very first image
   $rv = $obj->putchunk_info(MNG_UINT_FRAM, { iMode => 2 } );
   ok($rv,MNG_NOERROR,"writing fram"); 


   # move the "special" images (down) out of the clipping area
   # now they no longer overlap the original numbers
   $rv = $obj->putchunk_info( MNG_UINT_MOVE,
                              {
                                 iFirstid  => 101,
                                 iLastid   => 200,
                                 iMovetype => 1,
                                 iMovex    => $vstyle ? $width_all : 0, 
                                 iMovey    => $vstyle ? 0 : $height_all,
                              }
                            );
   ok($rv,MNG_NOERROR,"writing move"); 


   # show all objects inside of the clipping range
   $rv = $obj->putchunk_info( MNG_UINT_SHOW, { iFirstid => 1, iLastid => 200 } );
   ok($rv,MNG_NOERROR,"writing show"); 


   # now define a loop to execute the animation (length = height in pixels)
   $rv = $obj->putchunk_info( MNG_UINT_LOOP, { iLevel => 1, iRepeat => $vstyle ? $width_all : $height_all } );
   ok($rv,MNG_NOERROR,"writing loop"); 


   # start a frame, do not change framing mode
   $rv = $obj->putchunk_info( MNG_UINT_FRAM );
   ok($rv,MNG_NOERROR,"writing fram"); 


   # =======================================================
   # = this moves the images "up", one pixel at a time.
   # =======================================================

   # move all "source" objects that must change, starting with the first object
   # base movement from parent object, move deltaY=-1
   $rv = $obj->putchunk_info( MNG_UINT_MOVE,
                              {
                                 iFirstid  => $firstmove,
                                 iLastid   => 100,
                                 iMovetype => 1,
                                 iMovex    => $vstyle ? -1 : 0, 
                                 iMovey    => $vstyle ? 0 : -1,
                              } );
   ok($rv,MNG_NOERROR,"writing move"); 


   # move all "dest" objects that must change, starting with the first object
   # base movement from parent object, move deltaY=-1
   $rv = $obj->putchunk_info( MNG_UINT_MOVE,
                              {
                                 iFirstid  => 101,
                                 iLastid   => 200,
                                 iMovetype => 1,
                                 iMovex    => $vstyle ? -1 : 0, 
                                 iMovey    => $vstyle ? 0 : -1,
                              } );
   ok($rv,MNG_NOERROR,"writing move"); 


   # =======================================================
   # show all objects inside of the clipping range
   $rv = $obj->putchunk_info( MNG_UINT_SHOW, { iFirstid => 1, iLastid => 200 } );
   ok($rv,MNG_NOERROR,"writing show"); 

   # end the loop (at depth level 1)
   $rv = $obj->putchunk_info( MNG_UINT_ENDL, { iLevel => 1 } );
   ok($rv,MNG_NOERROR,"writing endl"); 

   # provide an end chunk
   $rv = $obj->putchunk_info( MNG_UINT_MEND );
   ok($rv,MNG_NOERROR,"writing mend"); 

   # now put it all together
   $rv = $obj->write();
   ok($rv,MNG_NOERROR,"writing file");

   return $rv;
}



#---------------------------------------------------------------------------
sub insert_chunks
{  # PNG Mode
   my ( $obj, $file ) = @_;
   my $rv = MNG_NOERROR;

   my $userdata = @png_objects->[$file]->get_userdata();
   my $chunks = $userdata->{'chunks'};

   foreach my $chunk ( @$chunks )
   {
      $rv = $obj->putchunk_info($chunk);
      warn("putchunk_info() failed ($rv)\n") unless defined $rv && $rv==MNG_NOERROR;
      last unless $rv==MNG_NOERROR;
   }

   my $width_this  = $userdata->{'width'};
   my $height_this = $userdata->{'height'};

   return ( $rv, $width_this, $height_this );
}



 


