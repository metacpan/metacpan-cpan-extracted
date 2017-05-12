#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

splice-idj.pl - extract a subset of spectra from an idj to porduce another one

=head1 DESCRIPTION

The idea is to have a tool to extract a list of compounds spectra from an idj file

=head1 SYNOPSIS

=begin verbatim

#make a subset of msms compound spectra 1, 5, and from 10 to 20 (start is 0) from idj-xml to idj-short.xml
 splice-idj.pl --in=idj.xml --out=idj-short.xml --compounds=1,5,10-20

#Only count the size
 splice-idj.pl --in=idj.xml --count

=end verbatim

=head1 ARGUMENTS

=head1 OPTIONS

=head3 --in=file

input idj.xml file (default is STDIN)

=head3 --out=file

output idj.xml file (default is STDOUT)

=head3 --count

only report counting

=head3 --coumpond=range

print only the compond with index within the range (e.g --compound=2,5,6-11,35)

=head3 --version

=head3 --help

=head3 --man

=head3 --verbose

=head1 COPYRIGHT

Copyright (C) 2004-2007  Geneva Bioinformatics www.genebio.com

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

my $VERSION="0.0.1";
use strict;
use Getopt::Long;
use Bit::Vector;
my ($infile, $outfile)=('-', '-');
my ($help, $man, $verbose);

my($onlyCounts, $compoundList);

if (!GetOptions(
		"in=s"=>\$infile,
		"out=s"=>\$outfile,

		"compound=s"=>\$compoundList,
		"count"=>\$onlyCounts,

                "help" => \$help,
                "man" => \$man,
                "verbose" => \$verbose,
               )
    || $help || $man ){

  pod2usage(-verbose=>2, -exitval=>2) if(defined $man);
  pod2usage(-verbose=>1, -exitval=>2);
}


my $maxPept=0;
open (FDIN, "<$infile") or die "cannot open [$infile]: $!";
while (<FDIN>){
  $maxPept++ if /<(ple:)?peptide\b/;
}
close FDIN;

if($onlyCounts){
  print "max_compounds\t$maxPept\n";
  exit(0);
}

my $vectPept=Bit::Vector->new($maxPept+1);
$vectPept->from_Enum($compoundList);
my $n=0;
($vectPept->bit_test($_) && $n++) foreach (0..$maxPept);
warn "extracting $n/".($maxPept+1)." compounds\n";

open (FDIN, "<$infile") or die "cannot open [$infile]: $!";
open (FDOUT, ">$outfile") or die "cannot open [$outfile]: $!";
my $printing=1;
my $ipept=0;
while (<FDIN>){
  $printing=$vectPept->bit_test($ipept++) if /<(ple:)?peptide\b/;
  print FDOUT $_ if $printing;
  $printing=1 if /<\/(ple:)?peptide\b/;
}
close FDIN;
