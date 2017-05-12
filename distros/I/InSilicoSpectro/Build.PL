#!/usr/bin/env perl
use strict;
use English;

=head1 NAME

InSilico Build.PL

=head1 SYNOPSIS

For building a distribution:

=over 4

=item perl Build.PL

=item  perl Build dist

(version and README are taken from lib/InSilicoSpectro.pm)
A InSilicoSpectro-VERSION.tar.gz is ready to be shipped.

=back

For install

=over 4

=item perl Build.PL

=item perl Build

=item perl Build test

=item perl Build install

=back

see Actions for more informations

WARNING:
use perl Buil ppm to make to ppm dist (and not the standard ppmdist, because for pre-requisite are changed)

=head1 DESCRIPTION

Script based on the Module::Build package to make InSilicoSpectro distribution

=head1 ARGUMENTS

=head3 misc arguments

=over 4

=item --help

=back


=head1 COMMENTS

To recover this list of used packages throughout the perl files:
grep -e '^use ' -h `find . -name \*.p?`| perl -e 'while(<>){ print "".((split)[1])."\n";}' | grep -v strict | grep -v vars | grep -v InSilicoSpectro::| sort -u  | sed "s/;//"


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


BEGIN{
  push @INC, "..";
}

use Module::Build;

my %requires=(
	      'perl' => '5.6.1',
	      'Archive::Zip' => 0,
	      'Archive::Tar' => 0,
	      'Compress::Zlib' => 0,
	      'Digest::MD5' => 0,
	      'Data::Serializer'=>0,
	      'File::Find::Rule' => 0,
	      'File::Temp' => 0,
	      'Getopt::Long' => 0,
	      'GD' => 0,
	      'MIME::Base64' => 0,
	      'XML::Parser' => 0,
	      'XML::SemanticDiff' => '0',
	      'XML::Twig' => '>=3.14',
	     );

if ($OSNAME=~/win/){
  $requires{'File::Glob'};
  $requires{'GDGraph'}=0;
  $requires{'GDTextUtil'}=0;
}else{
  $requires{'GD::Graph'}=0;
  $requires{'GD::Text'}=0;
}

my %recommends=(
		'Statistics::Regression'=>0,
		'Statistics::Basic'=>0,
		'Math::FixedPrecision'=>0,
		'Math::Spline'=>0,
		'Math::Derivative'=>0,
		'AI::NNFlex'=>0,
		'XML::Dumper'=>0,
		'XML::Merge'=>0,
		'XML::Parser::PerlSAX'=>0,
		'Bio::Perl' => 1.4,
	       );

#see PhenyBuild.pm for extra config

my ($help, $man, $verbose);
use Getopt::Long;
use Pod::Usage;
if(!GetOptions(
	       "help"=>\$help,
	       "man"=>\$man,
	       "verbose"=>\$verbose,
	      )
   or $help or $man){
  pod2usage(-verbose=>2, -exitval=>2) if defined $man;
  pod2usage(-verbose=>1, -exitval=>2);
}


use lib qw(../ ./);

my @scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  push @scripts, $_ if /^(scripts)\//;
}
my %cgi_scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  $cgi_scripts{$_}=$_ if /^(cgi)\//;
}
close fd;

my $build=Module::Build->new
  ( module_name => 'InSilicoSpectro',
    requires => \%requires,
    recommends => \%recommends,
    dist_version_from => './lib/InSilicoSpectro.pm',
    create_makefile_pl => 'traditional',
    create_readme => 'README',
    license => 'lgpl',
    dist_author => 'Alexandre Masselot <alexandre.masselot@genebio.com>, Jacques Colinge <Jacques.Colinge@fh-hagenberg.at>',
    recursive_test_files=>1,
    script_files=>\@scripts,
    cgi_files=>\%cgi_scripts,
  );

$build->add_build_element('cgi') || die "cannot add build element [cgi]";
$build->add_build_element('xml') || die "cannot add build element [xml]";
$build->prereq_failures() && $build->prereq_failures()->{requires}  && die "conflicts (missing requirem\ents?)";
$build->create_build_script;

