#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

indexXml.pl

=head1 DESCRIPTION

Builds a xml index for large xml files. From a source.xml file, extract info as requested in a indexmaker.xml and write an index.xml

=head1 SYNOPSIS

See perldoc InSilicoSpectro::Utils::XML::SaxIndexMaker for the indexmaker and output formats.

See the lib/Phenyx/Utils/SaxIndexMaker/test directory for examples

=head1 ARGUMENTS

=over 4

=item -src=xmlfile

The file to be indexed (typically a large file, too large to be handled by DOM technology).

If this file is gziped, it will be gunziped temporarly in the defaut temp directory

=item -indexmaker=xmlfile

The file with the description of what is to be index from the source file.

=back

=head1 OPTIONS

=over 4

=item --save=xmlfile

Where to save the index [STDOUT]

=item --help

=item --man

=item --verbose

=back

=head1 Example

./prepareDb.pl --src=dat:/tmp/human.seq -db=SwissProtHuman --xtraconfigtags="phenyx.databases:/tmp;phenyx.users.default=/tmp"

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
my($srcFile, $saveFile, $indexMakerFile, $help, $man);

if (!GetOptions(
		"src=s"=>\$srcFile,
		"indexmaker=s"=>\$indexMakerFile,
		"save=s"=>\$saveFile,

                "verbose" => \$InSilicoSpectro::Utils::io::VERBOSE,
                "help" => \$help,
                "man" => \$man,
               )
    || $help|| $man || (not defined $srcFile) ||(not defined $indexMakerFile) ){

  print STDERR "must define --src=xmlfile" unless defined $srcFile;
  print STDERR "must define --indexmaker=xmlfile" unless defined $indexMakerFile;
  pod2usage(-verbose=>2, -exitval=>2) if(defined $man);
  pod2usage(-verbose=>1, -exitval=>2);
}

use InSilicoSpectro::Utils::XML::SaxIndexMaker;
use File::Temp qw/ tempfile tempdir /;

eval{
  $srcFile.='.gz' if(! -f $srcFile) && (-f "$srcFile.gz");
  my $realSrc=$srcFile;
  if($srcFile=~/\.gz/i){
    (undef, $realSrc) = tempfile( "src-XXXXXX", SUFFIX => '.xml', UNLINK=>1, DIR => File::Spec->tmpdir);
    print STDERR "gunziping to $realSrc\n" if $InSilicoSpectro::Utils::io::VERBOSE;
    InSilicoSpectro::Utils::io::uncompressFile($srcFile, {remove=>0, dest=>$realSrc});
  }

  my $sim=InSilicoSpectro::Utils::XML::SaxIndexMaker->new();
  $sim->readXmlIndexMaker($indexMakerFile);
  $sim->makeIndex($realSrc, $saveFile, {origSrc=>$srcFile});

};
if ($@){
  print STDERR "error trapped in main\n";
  carp $@;
}

