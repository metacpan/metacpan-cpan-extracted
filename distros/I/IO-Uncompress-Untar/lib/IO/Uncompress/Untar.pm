package IO::Uncompress::Untar;

require 5.006;
use strict;
use warnings;
use IO::File;
use Archive::Tar::Stream;
use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError) ;

require Exporter;

our @ISA = qw(Exporter);
our($VERSION)='1.01';
our($UntarError) = '';

our %EXPORT_TAGS = ( 'all' => [ qw( $UntarError ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


sub new {
  my $class = shift;
  my $this={};
  $this->{handle}=shift;
  $this->{z} = new IO::Uncompress::AnyUncompress $this->{handle};
  $this->{ts} = Archive::Tar::Stream->new(infh => $this->{z}); $this->{ts}->SafeCopy(0);
  $this->{opt}=shift;
  $this->{raw}='';
  $this->{header}={};
  $this->{loc}=0;
  $this->{i}=0;
  $this->{readoffset}=0;
  bless $this,$class;
  return $this;
} # new


sub nextStream {
  my $this = shift ;
  $this->{readoffset}=0;
  if(!$this->{loc}) {
    $this->{header}=$this->{ts}->ReadHeader();
    $this->{loc}+=512;
  } else {
    while(($this->{header}->{size} > $this->{i} )&&(defined $this->{raw})) {
      my $blks=int(($this->{header}->{size}-$this->{i}-1)/512)+1;
      $blks=1602 if($blks>1602);
      $this->{raw} = $this->{ts}->ReadBlocks($blks);
      $this->{i}+=$blks*512;
      $this->{loc}+=$blks*512;
    }
    $this->{header}=$this->{ts}->ReadHeader();
    $this->{loc}+=512; $this->{i}=0;
  }

  return 0 if(!((defined $this->{raw})&&(ref $this->{header})));
  return 1;
} # nextStream


sub getHeaderInfo {
  my $this = shift ;
  $this->nextStream() unless($this->{loc});
  return undef if(!ref $this->{header});
  $this->{header}->{UncompressedLength}=$this->{header}->{size};
  $this->{header}->{Name}=$this->{header}->{name};
  $this->{header}->{Time}=$this->{header}->{mtime};
  return $this->{header};
} # getHeaderInfo


sub read {
  my $this = shift;
  my $bytes = $_[1] || 512*1600;
  ++$this->{rec}; # debugging - block accidental recursion
#warn "$this $bytes r=" . $this->{rec};
  my $offset = $_[2];
  die "non zero offset not implimented" if($offset);
  my $maxleft=$this->{header}->{size}-$this->{i};
  $bytes=$maxleft if($bytes>$maxleft);
  if((!defined $this->{raw})||($bytes>length($this->{raw}))) {
    my $blks=int(($bytes-length( $this->{raw} )-1 )/512)+1;
    $this->{raw}.=$this->{ts}->ReadBlocks($blks) if($this->{rec}<2);
warn "Blocked recursion $this->{rec}" if($this->{rec}>1);    
    $this->{i}+=$blks*512; $this->{loc}+=$blks*512;
  }
  --$this->{rec};
  $_[0]=substr($this->{raw},$this->{readoffset},$bytes);
  $this->{raw}=substr($this->{raw},$bytes);
  #$this->{readoffset}+=$bytes;
#warn "$this got=" . length($_[0]);
  return length($_[0]);
} # read

sub close {
  my $this = shift;
  # $this->{ts}->close();
  $this->{z}->close();
}

1;

__END__


=head1 NAME

IO::Uncompress::Untar - Pure-perl extension to read tar (and tgz and .tar.bz2 etc) files/buffers

=head1 SYNOPSIS


    #!/usr/bin/perl -w
      
    use strict;
    use warnings;
    use IO::Uncompress::Untar qw($UntarError);

    my $u = new IO::Uncompress::Untar *STDIN or die "Cannot open";       # Prints the names of all the files in the tar / tgz / tar.bz2 / etc.
    my $status;

    for ($status = 1; $status > 0; $status = $u->nextStream()) {
      my $hdr = $u->getHeaderInfo();
      my $fn = $hdr->{Name};
      last if(!defined $fn);
      my @sz= ref $hdr->{UncompressedLength} ? @{$hdr->{UncompressedLength}} : ($hdr->{UncompressedLength});

      my $buff;
      while (($status = $u->read($buff)) > 0) {
	# Do something here
      }   
      print "$hdr->{Time}\t$sz[0]\t$fn\n"; 
      last if $status < 0;
    } # for status


=head1 DESCRIPTION

This module provides a minimal pure-Perl interface that allows the reading of tar files/buffers.
It maintains basic compatability/functionality of IO::Uncompress::Unzip


=head2 EXPORT

None by default.


=head2 Notes

Only these are implimented: new nextStream getHeaderInfo read


=head2 new

    my $u = new IO::Uncompress::Untar *STDIN or die "Cannot open";

    my $u = new IO::Uncompress::Untar 'somefile.tgz' or die "Cannot open";

Uses AnyUncompress internally, so the stream or file can be a plain tar, or a gzip, bzip2, Z, or anything else compressed that AnyUncompress knows.


=head2 read

Usage is

    $status = $z->read($buffer, $length)
    $status = $z->read($buffer, $length, $offset)

    $status = read($z, $buffer, $length)
    $status = read($z, $buffer, $length, $offset)

Attempt to read C<$length> bytes of uncompressed data into C<$buffer>.


=head2 getHeaderInfo

Usage is

    $hdr  = $z->getHeaderInfo();
    @hdrs = $z->getHeaderInfo();

This method returns a hash reference (in scalar context) that contains information about the current file


=head2 nextStream

Usage is

    my $status = $z->nextStream();

Skips to the next compressed data stream in the input file/buffer. If a new
compressed data stream is found, the eof marker will be cleared and C<$.>
will be reset to 0.

Returns 1 if a new stream was found, 0 if none was found, and -1 if an
error was encountered.



=head1 SEE ALSO

L<Compress::Zlib>, L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip>, L<IO::Compress::Deflate>, L<IO::Uncompress::Inflate>, L<IO::Compress::RawDeflate>, L<IO::Uncompress::RawInflate>, L<IO::Compress::Bzip2>, L<IO::Uncompress::Bunzip2>, L<IO::Compress::Lzma>, L<IO::Uncompress::UnLzma>, L<IO::Compress::Xz>, L<IO::Uncompress::UnXz>, L<IO::Compress::Lzop>, L<IO::Uncompress::UnLzop>, L<IO::Compress::Lzf>, L<IO::Uncompress::UnLzf>, L<IO::Uncompress::AnyInflate>, L<IO::Uncompress::AnyUncompress>

L<IO::Compress::FAQ|IO::Compress::FAQ>

L<File::GlobMapper|File::GlobMapper>, L<Archive::Zip|Archive::Zip>,
L<Archive::Tar|Archive::Tar>,
L<IO::Zlib|IO::Zlib>


=head1 AUTHOR

This module was written by Chris Drake F<cdrake@cpan.org>. 


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

