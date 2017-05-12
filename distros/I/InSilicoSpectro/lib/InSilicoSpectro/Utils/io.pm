use strict;

package InSilicoSpectro::Utils::io;
require Exporter;

=head1 NAME

InSilicoSpectro::Utils::io

=head1 DESCRIPTION

Miscelaneous I/O utilities.

=head1 FUNCTIONS

=head3 getFD()

The getFD function takes either a file string, a piped command or a file description as argument
and returns a file descriptor. In case of error while opening, it returns undef.

=head3 uncompressFile($fname, [\%args])

Uncompresses a gziped file. Returns the new uncompressed file name; Erase the original;
%args can overwrite default values

=over 4

=item remove => [1];

=item dest => filename [undef];

If defined, the uncompressed file is not the original one =~s/\.gz$//i, but it has this file name.

=back

=head3 headGz($fname, [$nblines], [$re])

Uncompresses file $fname and takes the $nblines first lines (default 10) satisfying regular expression $re (if defined).

Returns either an array or lines concatenated with \n characters, depending on the context.

=head3 compressFile($fname, [\%args])

Compresses to a gziped file. Returns the new compressed file name; Erases the original by default;
%args can overwrite default values.

=over 4

=item remove => [1];

=back

=head3 zipFiles($dest, \@files, [$baseNameOnly])

Opens a zip archive $dest and puts all the files contained in @files into it.
$dest can be either undef (means STDOUT), or a filehandle, or a file name.
If($baseNameOnly) [default undef], stores the file under its basename (removes directory name).

=head3 getMD5($file)

Returns a MD5 checksum of $file.

=head3 croakIt($msg)

Croaks with the given message, but appends a stack trace if $InSilicoSpectro::Utils::io::VERBOSE is true.

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

our (@ISA,@EXPORT,@EXPORT_OK, $VERBOSE);
@ISA = qw(Exporter);

@EXPORT = qw(&getFD $VERBOSE &compressFile &uncompressFile &zipFiles &getMD5 &croakIt &isInteractive);
@EXPORT_OK = ();

use Carp;
use File::Glob qw(:glob);

sub isInteractive{
  return -t STDIN && -t STDOUT;
}

sub getFD{
  my ($this, $v)=@_;

  if((ref $v) eq "GLOB"){
    return $v;
  }else{
    my $fd;
    open ($fd, "$v") or return undef;
    return $fd;
  }
}



use Compress::Zlib;

sub uncompressFile{
  my ($fname, $arg)=@_;

  my $rmSource=1;

  if(defined $arg){
    $rmSource=$arg->{remove} if defined $arg->{remove};
  }

  croak "try to gunzip a file without a .gz suffix [$fname]" unless $fname=~/^(.*)\.gz$/i;

  my $outFile=$1;
  $outFile=$arg->{dest} if $arg->{dest};

  open(FDOUT, ">$outFile") or croak "cannot de-inlfate towards [$outFile]: $!";

  my $gz = gzopen($fname, "rb") or croak "Cannot open $fname: $gzerrno";
  my $buffer;
  print FDOUT $buffer while $gz->gzread($buffer) > 0 ;

  croak "Error uncompressing from $fname: $gzerrno" . ($gzerrno+0) if $gzerrno != Z_STREAM_END ;
  #$gz->gzflush("Z_FINISH");
  $gz->gzclose() ;

  undef $gz;
  unlink $fname if $rmSource;
  close FDOUT;
  return $outFile;
}


sub compressFile{
  my ($fname, $arg)=@_;

  my $rmSource=1;

  if(defined $arg){
    $rmSource=$arg->{remove} if defined $arg->{remove};
  }


  open(FDIN, "<$fname") or croak "cannot compress from [$fname]: $!";

  my $outFile="$fname.gz";

  if($rmSource){
    unless (system ("gzip --version")){
      unlink $outFile;
      my $cmd="gzip $fname";
      system ($cmd) && die "cannot $cmd";
      return $outFile;
    }
  }

  my $gz = gzopen("$outFile", "wb")
    or CORE::die "Cannot open [$outFile]: $gzerrno\n" ;
  while (<FDIN>) {
    $gz->gzwrite($_) 
      or CORE::die "error writing: $gzerrno\n" ;
  }
  close FDIN;
  $gz->gzclose;
  unlink $fname if $rmSource;
  undef $gz;

  return $outFile;
}


sub headGz{
  my ($fname, $lines, $re)=@_;
  $lines=10 unless $lines;
  open(FDIN, "<$fname") or croakIt("cannot compress from [$fname]: $!");

  my @res;
  croakIt("try to gunzip a file without a .gz suffix [$fname]") unless $fname=~/^(.*)\.gz$/i;

  my $qr;
  if(defined $re){
    eval "\$qr = qr$re";
    croakIt("unable to compile regular expresion [$re]") unless defined $qr;
  }

  my $gz = gzopen($fname, "rb") or croakIt("Cannot open $fname: $gzerrno");
  my $buffer;
  my $i=0;
  while($gz->gzread($buffer) > 0){
    foreach(split /\n/, $buffer){
      if(((defined $re) and ($_=~$qr)) or (not defined $re)){
	chomp;
	push @res, $_;
	$i++;
      }
      last if $i>=$lines;
    }
    last if $i>=$lines;
  }

  $gz->gzclose() ;
  undef $gz;

  return wantarray?@res:(join "\n", @res);;
}

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use SelectSaver;
use File::Basename;

sub zipFiles{
  my ($dest, $files, $baseNameOnly)=@_;

  my $zip = Archive::Zip->new();
  #my $member = $zip->addDirectory("./");
  foreach(@$files){
    if($baseNameOnly){
      $zip->addFile($_, basename $_);
    }else{
      $zip->addFile($_);
    }
  }

  if((!defined $dest) || ((ref $dest) eq 'GLOB')){
    new SelectSaver(InSilicoSpectro::Utils::io->getFD($dest)) if defined $dest;
    croak "io::zipFiles($dest, $files): write error" unless $zip->writeToFileHandle(\*STDOUT) == AZ_OK;
  }else{
    croak "io::zipFiles($dest, $files): write error" unless $zip->writeToFileNamed($dest) == AZ_OK;
  }
}

use Digest::MD5 qw(md5);
sub getMD5{
  my $f=$_[0];
  open (*fd, "<$f") or croak "Cannot open for reading [$f]: $!";
  my $md5 = Digest::MD5->new();
  $md5->addfile(\*fd);
  close *fd;
  return $md5->b64digest();
}


sub croakIt{
  my $msg=shift;
  if($InSilicoSpectro::Utils::io::VERBOSE){
    croak "$msg\n<pre>".Carp::longmess()."\n</pre>\n";
  }else{
    croak $msg;
  }
}

1;


