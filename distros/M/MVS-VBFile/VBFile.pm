package MVS::VBFile;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Carp;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(vbget);
@EXPORT_OK = qw(vbget vbopen vbput vbclose vb_blocks_written);
$VERSION = '0.05';

%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

my $blib = 0;  # Bytes left in block
$MVS::VBFile::bdws = 0;
$MVS::VBFile::keep_rdw = 0;

%MVS::VBFile::outblock = ();
%MVS::VBFile::blksizes = ();
%MVS::VBFile::blocks_written = ();

#--- vbget gets a single record; if called in array context (the user
#--- wants all records in a single array), it calls vbget_array.
#
sub vbget {
 my $FH = shift;  # Filehandle
 if (wantarray) {
    return vbget_array($FH);
 }

 my ($bdw, $rdw, $reclen, $v_record, $n);
 if ($blib == 0 && $MVS::VBFile::bdws) {
	#--- Beginning of a block: read the Block Descriptor Word
	#--- if we've been told to.
    $n = read($FH, $bdw, 4);
    if ($n < 4) {  # End of file
       return undef();
    }
    $blib = unpack("n2", substr($bdw, 0,2)) - 4;
 }
	#--- Now read the Record Descriptor Word
 $n = read($FH, $rdw, 4);
 if ($n < 4) {
    return undef() if ! $MVS::VBFile::bdws;  # End of file
    Carp::carp "vbget: Unexpected end of file";
    return undef();
 }
 $reclen = unpack("n2", substr($rdw, 0,2)) - 4;
 
 $n = read($FH, $v_record, $reclen);
 if ($n != $reclen) {
    Carp::carp "vbget: Unexpected end of file";
 }
 $blib = $blib - ($reclen + 4)  if $MVS::VBFile::bdws;
 $v_record = $rdw.$v_record  if $MVS::VBFile::keep_rdw;

 return $v_record;
}

#--- Get all records in a single array.
#
sub vbget_array {
 my $FH = shift;  # Filehandle
 my ($bdw, $rdw, $reclen, $v_record, $n);
 my @out = ();

 while (1) {
    if ($blib == 0 && $MVS::VBFile::bdws) {
	#--- Beginning of a block: read the Block Descriptor Word
	#--- if we've been told to.
       $n = read($FH, $bdw, 4);
       if ($n < 4) {  # End of file
          return @out;
       }
       $blib = unpack("n2", substr($bdw, 0,2)) - 4;
    }
	#--- Now read the Record Descriptor Word
    $n = read($FH, $rdw, 4);
    if ($n < 4) {
       return @out if ! $MVS::VBFile::bdws;  # End of file
       Carp::carp "vbget: Unexpected end of file";
       return @out;
    }
    $reclen = unpack("n2", substr($rdw, 0,2)) - 4;
 
    $n = read($FH, $v_record, $reclen);
    if ($n != $reclen) {
       Carp::carp "vbget: Unexpected end of file";
       return @out;
    }
    $blib = $blib - ($reclen + 4)  if $MVS::VBFile::bdws;
    $v_record = $rdw.$v_record  if $MVS::VBFile::keep_rdw;

    push @out, $v_record;
 }
}

#---------------------------------------
#  OUTPUT: vbopen, vbput, vbclose
#---------------------------------------

#--- vbopen: pretty much the same as open() except that it also sets
#--- the blksize for the file.
#
sub vbopen {
 my ($FH, $expr, $blksize) = @_;
 $blksize ||= 32760;
 $blksize = 32760 if $blksize < 9;
 $blksize = 32760 if $blksize > 262_144;

 $MVS::VBFile::blksizes{ $FH } = $blksize;
 $MVS::VBFile::outblock{$FH} = pack('x4');  # Start with a dummy BDW
 $MVS::VBFile::blocks_written{$FH} = 0;
 return open($FH, $expr);
}

#--- vbput puts a single logical record.  When a block is filled up,
#--- write the block and start a new one.
#
sub vbput {
 my ($FH, $record) = @_;
 Carp::croak "vbput: No filehandle specified" unless $FH;
 Carp::croak "vbput: No record specified" unless $record;
 my $blksize = $MVS::VBFile::blksizes{ $FH };

 my $L = length($record) + 4;
 if ($L + length($MVS::VBFile::outblock{$FH}) > $blksize) {
    _put_block($FH);
    $MVS::VBFile::outblock{$FH} = pack('x4');  # Start with a dummy BDW
 }
 my $rdw = pack("n x2",$L);
 $MVS::VBFile::outblock{$FH} .= $rdw.$record;
}

sub _put_block {
 my $FH = shift;
 my $outrec = $MVS::VBFile::outblock{$FH};

 substr($outrec,0,4) = pack("n x2",length($outrec));

 print $FH $outrec  or Carp::croak "Error in vbput: $!";
 $MVS::VBFile::blocks_written{$FH}++;
}

#--- vbclose: close the output file, but first write out the last
#--- block if necessary.
#
sub vbclose {
 my $FH = shift;
 Carp::croak "vbput: No filehandle specified" unless $FH;

 _put_block($FH)  if length($MVS::VBFile::outblock{$FH}) > 4;

 return close($FH);
}

sub vb_blocks_written {
 my $FH = shift;
 Carp::croak "vb_blocks_written: No filehandle specified" unless $FH;
 return $MVS::VBFile::blocks_written{ $FH };
}

1;

__END__

=head1 NAME

MVS::VBFile - Perl extension to read and write variable-length MVS files

=head1 SYNOPSIS

  use MVS::VBFile qw(:all);  # only vbget is exported by default
  $next_record = vbget(*FILEHANDLE);
  @whole_enchilada = vbget(*FILEHANDLE);

  vbopen(*FILEHANDLE, ">output_file", $blksize);
  vbput(*FILEHANDLE, $record);
  vbclose(*FILEHANDLE);
  $b = vb_blocks_written(*FILEHANDLE);

=head1 DESCRIPTION

This module provides functions to get records from mainframe MVS files
in variable blocked (VB) format and to write records in a similar
format.

=head1 FUNCTIONS

vbget is exported by default; if you want any other functions, you
must ask for them by name.  C<qw(:all)> exports all functions.

=over 2

=item B<vbget> *FILEHANDLE

The input function, vbget(), works like
the angle operator: when called in scalar context, it returns the next
record; when in array context, it returns the entire file in a single
array.  The file must be in "binary" format (no translation of bytes)
and include record descriptor words.  The file may include block
descriptor words but need not.

The rationale behind this is as follows.  Most files from MVS
systems are either fixed-length (record format FB) or variable-length
(recfm VB).  Perl can read fixed-length mainframe files just as it
reads other fixed-length files -- open, read a certain number of bytes,
close -- but variable-length files require some special handling.
Since Perl provides open and close, the only function needed is one to 
get the next record.

Read the file as follows:

  open FILEHANDLE, "..name..";
  while (vbget(*FILEHANDLE)) {  # Be sure to use '*'!!
     # process and reality...
  }
  # OR do this:
  @much_in_little = vbget(*FILEHANDLE);
  # and then process the array (only on small files, of course).
  close FILEHANDLE;

=item B<vbopen> *FILEHANDLE EXPR [BLKSIZE]

Three output functions are provided: vbopen(), vbput(), and vbclose().
These functions allow you to write out records (to tape, most likely)
that can later be read by an MVS system.  Like vbget(), these functions
do not translate any of the data given to them; any translation to
EBCDIC (or anything else) must be done before the record is written.

vbopen() is similar to Perl's open, but you must pass a typeglob as
the first argument (in other words, put a B<*> on the front of it).
The third argument is the blksize
of the file.  The minimum blksize is 9 bytes; the maximum, 256KB
(262_144 bytes); the default, 32760.
If you wish to use a blksize larger than 32760, make
sure that your MVS system will support it.  Your output must be
blocked; in other words, you cannot write out files with RDW's but
no BDW's.

You may have more than one filehandle open at a time.

=item B<vbput> *FILEHANDLE RECORD

Puts a single logical record to the file.

=item B<vbclose> *FILEHANDLE

Closes the file.  Be sure to use this function, since it will write
a final block that contains any remaining logical records.

=item B<vb_blocks_written> *FILEHANDLE

Can be called at any time to find the number of blocks written to the
file.  This would be most useful after closing the file; the count
could, for instance, be used to build an MVS-style tape header.

Here's a full example of writing output:

  vbopen(*VBO, ">$outfile", 32760);
  foreach $record (@my_array) {
     vbput(*VBO, $record);
  }
  vbclose(*VBO);
  $b = vb_blocks_written(*VBO);

=head1 VARIABLES

The variable B<MVS::VBFile::bdws> applies only to input.  It tells the
module whether the file to be read contains block descriptor words.
The default is 0 (false); set it to 1 or any other true value if the
file contains BDW's.

The variable B<MVS::VBFile::keep_rdw> applies only to input.
It tells vbget whether to keep the RDW on each record when getting it.
The default is 0 (false); set it to 1 or any other true value if you
want to keep the RDW's on the records.

=head1 RESTRICTIONS

For input, both VB (blocked) and V (unblocked) formats are supported.
vbget() will not work properly on format VBS (spanned).  Since VB is
by far the most commonly used format, this should not be a major snag.

Output must be blocked (VB); in other words, you cannot write out
files with RDW's but no BDW's.

=head1 MORE ABOUT DESCRIPTOR WORDS

Record descriptor words are 4 bytes that appear at the beginning of
each record in a VB file.  The first two bytes contain the record
length in binary (16 bits, signed, big-endian); the last two are used
only by spanned records and are ignored by this module.  Block
descriptor words, likewise, are 4 bytes that appear at the beginning
of each block, having the same format.

My experience with FTP from MVS is limited, but it seems that if you
transfer a file from an MVS host via FTP including the RDW's, the
RDW's will be transferred but the BDW's will not.  Most applications
do not require BDW's, but if you want them, they can be transferred
by converting the VB file to undefined records (recfm=U) under MVS
and then transferring the converted file.

=head1 AUTHOR

W. Geoffrey Rommel, GROMMEL@cpan.org, March 1999.

Thanks to Bob Shair for suggesting vbput and
providing preliminary code.

=cut
