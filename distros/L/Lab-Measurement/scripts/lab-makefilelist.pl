#!/usr/bin/perl

use strict;
use Lab::Data::Meta;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

my @files = <*>;

open FILELIST,">filelist.txt" or die;

my $file;

foreach $file (@files) {
   if (($file =~ /\.meta$/) || ($file =~ /\.META$/)) {
      print "Processing file $file\n";

      my $meta=Lab::Data::Meta->new_from_file($file);
      my %plots=$meta->plot();
      for (sort keys %plots) {
         print "  Adding plot $_\n";
         print FILELIST "$_\t$file\n";
      };
      undef $meta;
   };
};



1;

=pod

=encoding utf-8

=head1 NAME

make_filelist.pl - Generate a list of all plots defined in all metafiles of the current directory

=head1 SYNOPSIS

  huettel@pc55508 ~ $ make_filelist.pl

=head1 DESCRIPTION

This is a commandline tool to quickly generate a list of all plots defined in the current
directory. It generates a file C<filelist.txt> suitable as input of C<make_overview.pl>.

=head1 SEE ALSO

=over 2

=item gnuplot(1)

=item L<Lab::Measurement>

=item L<Lab::Data::Plotter>

=item L<Lab::Data::Meta>

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2004 Daniel Schröer
            2011 Andreas K. Hüttel

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
