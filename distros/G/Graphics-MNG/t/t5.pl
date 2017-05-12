#!perl 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 8 };
use Graphics::MNG;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Graphics::MNG qw( :util_fns MNG_FUNCTIONINVALID MNG_ACCESS_CHUNKS MNG_STORE_CHUNKS );
ok(1);   # loaded an export-ok constant

use FileHandle;
use Cwd;
use Data::Dumper;
  use constant FILENAME     => 'counter.mng';
# use constant FILENAME     => 'linux.mng';
  use constant OUT_FILENAME => 'tempfile.mng';


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

# open(STDERR,">log.txt");
main();
exit(0);


sub get_filename($)
{
   my ($fn) = @_;
   my ($match) = grep { -r $_ } ( $fn, "t/$fn" );
   return $match || ( -d 't' ? "t/$fn" : $fn );
}

sub main
{
   my ($rv,$input) = FileReadChunks(get_filename(FILENAME), \&IterateChunks );
   ok($rv, MNG_NOERROR, 'Reading chunks');

   my @chunk1 = @{ $input->get_userdata()->{'chunks'} };
   ok(int(@chunk1) ? 1:0, 1, 'Non-zero chunk count');

   writefile(OUT_FILENAME, FILENAME, \@chunk1 );

   my $reread;
   ($rv,$reread) = FileReadChunks(get_filename(OUT_FILENAME), \&IterateChunks );
   ok($rv, MNG_NOERROR, 'Re-Reading chunks');

   my @chunk2 = @{ $reread->get_userdata()->{'chunks'} };
   ok(int(@chunk2) ? 1:0, 1, 'Non-zero chunk count');

   my $len1 = int @chunk1;
   my $len2 = int @chunk2;
   my $minlen = $len1 < $len2 ? $len1 : $len2;

   foreach my $chunknum (0..$minlen-1)
   {
      my ($chunk1,$chunk2) = (@chunk1->[$chunknum],@chunk2->[$chunknum]);
      my ($name1, $name2 ) = ($chunk1->{'pChunkname'}||'?', $chunk2->{'pChunkname'}||'?');

      if ( $name1 ne $name2 )
      {
         warn("Iteration $chunknum: Chunk #1 name is $name1, Chunk #2 name is $name2\n");
      }
   }

   # clean up
 # unlink( get_filename(OUT_FILENAME) );
}


#---------------------------------------------------------------------------
sub writefile
{
   my ($fn, $orig, $chunkRef) = @_;
   my $rv;

   # delete the output filename if it exists
   unlink($fn) if (-e $fn);

   # write the file chunks
   $rv = FileWriteChunks($fn,$chunkRef);
   ok($rv,MNG_NOERROR,"Writing chunks");

   # check to see if the file is there and matches
   $rv = compare_files( $fn, $orig );
   ok($rv,0,"in/out file comparsion");

   return $rv;
}


#---------------------------------------------------------------------------
sub IterateChunks
{
   my ( $hHandle, $hChunk, $iChunktype, $iChunkseq ) = @_;
   my $userdata = $hHandle->get_userdata();

   my $rv = FileIterateChunks(@_);

   # get the last one...
   my ($info) = @{$userdata->{'chunks'}}->[-1];
   my ($name,$type) = $hHandle->getchunk_name($$info{'iChunktype'});

   # sanity check...
   if ( $iChunkseq ne $$info{'iChunkseq'} )
   {
      warn("Failed to get chunk information for seq $iChunkseq\n");
      return $rv;
   }

   # print out the length in the description
   my ($len) = map { sprintf("%4d",$$info{$_}) } ( grep { /len/i } keys %$info );
   $len ||= '   0';
   my $desc = "Chunk $iChunkseq: 0x$type/$name/$len/$rv";

 # warn("Chunk $iChunkseq:\n" . Dumper($info)) if $info->{'pChunkname'} =~ /END$/ ;
 # warn("$desc\n")                             if $iChunkseq <= 7;
 # warn("Chunk $iChunkseq:\n" . Dumper($info)) if $iChunkseq <= 7;

   return $rv;
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



