#!/usr/bin/env perl
use strict;

use Carp;
use strict;
use Carp;
use  Pod::Usage;

=head1 NAME

split-mgf.pl 

=head1 DESCRIPTION

split input mgf into slices

=head1 SYNOPSIS

./split.mgf.pl --slicesize=100 --outdir=/tmp/splitmgf

=head1 ARGUMENTS


=head3 --slicesize=n

the size of the slices

=head3 --outdir=/path/to/out

the directory where split_\d{9} files will be created

=head1 OPTIONS

=head3 --in=file.mgf

input file (default is STDIN)

=head3 --help

=head3 --man

=head3 --verbose


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

use Getopt::Long;
my($sliceSize, $outDir, $help, $man, $verbose);
my $inFile='-';

if (!GetOptions(
		"slicesize=i"=>\$sliceSize,
		"outdir=s"=>\$outDir,
		"in=s"=>\$inFile,
                "verbose" => \$verbose,
                "help" => \$help,
                "man" => \$man,
               )
    || $help|| $man ){

  pod2usage(-verbose=>2, -exitval=>2) if(defined $man);
  pod2usage(-verbose=>1, -exitval=>2);
}

use File::Temp qw/ tempfile tempdir /;
use File::Copy;

CORE::die "must give --slicesize=n argument" unless defined $sliceSize;
CORE::die "must define --outdir=path/to/dir" unless defined $outDir;

mkdir $outDir or CORE::die "cannot mkdir [$outDir]: $!" unless (-d $outDir);

print "STDERR opening input [-]\n" if $verbose;
open (fdin, "<$inFile") or CORE::die "cannot open for reading [$inFile]: $!";

my $cptSlice;
my $nSlice=0;
my $f=newFileSlice();
open (fdout, ">$f") or CORE::die "cannot open file for writing [$f]:!";
while (<fdin>){
  print fdout $_;
  if (/^END IONS\b/){
    $cptSlice++;
    print STDERR "." if $verbose;
    if($cptSlice>$sliceSize){
      print STDERR "\n" if $verbose;
      $cptSlice=0;
      close fdout;
      my $f=newFileSlice();
      open (fdout, ">$f") or CORE::die "cannot open file for writing [$f]:!";
    }
  }
}

sub newFileSlice{
  my $f=sprintf("$outDir/slice_%9.9d.mgf", $nSlice++);
  print STDERR "new output file $f\n" if $verbose;
  return $f;
}
