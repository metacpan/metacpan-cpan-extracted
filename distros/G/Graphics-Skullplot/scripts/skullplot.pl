#!/usr/bin/perl
# skullplot.pl                   doom@kzsu.stanford.edu
#                                27 Jul 2016

=head1 NAME

skullplot.pl - plot data from a manual db select

=head1 SYNOPSIS

  # default to first column on x-axis, all following columns on y-axis
  skullplot.pl input_data.dbox

  # specifying that explicitly
  skullplot.pl --dependents='x_axis_field' --independents='y_axis_field1,y_axis_field2' input_data.dbox

  # additional "dependents" fields determine color/shape of points
  skullplot.pl --dependents='x_axis_field1,category_field1' --independents='y_axis_field1,y_axis_field2' input_data.dbox

  # compact way of specifying similar case: first two columns independent, remaining columns dependent
  skullplot.pl --indie_count=2 input_data.dbox

  # don't use /tmp as working area
  skullplot.pl --working_loc='/var/scratch'  input_data.dbox

  # turn on debugging
  skullplot.pl -d  input_data.dbox

=head1 DESCRIPTION

B<skullplot.pl> is a script which use's the R ggplot2 library to
plot data input in the form of the output from a SELECT as
performed manually in a db shell, e.g.:

  +------------+---------------+-------------+
  | date       | type          | amount      |
  +------------+---------------+-------------+
  | 2010-09-01 | factory       |   146035.00 |
  | 2010-10-01 | factory       |   208816.00 |
  | 2011-01-01 | factory       |   191239.00 |
  | 2010-09-01 | marketing     |   467087.00 |
  | 2010-10-01 | marketing     |   409430.00 |
  +------------+---------------+-------------+

I call this "box format data" (file extension: *.dbox).

This script takes the name of the *.dbox file containing the data as an argument.
It has a number of options that control how it uses the data


The second argument is a comma-separated list of names of dependent variables
(the x-axis).
The third argument is a comma-separated list of the independent variables to
plot (the y-axis).

The default for dependent variables: the first column.
The default of independent variables: all of the following columns

The supported input data formats are as in the L<Table::BoxFormat> module.
At present, this is mysql and postgresql (including the unicode form).

=cut

use warnings;
use strict;
$|=1;
use Carp;
use Data::Dumper;

use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use autodie         qw( :all mkpath copy move ); # system/exec along with open, close, etc
use Env             qw( HOME );
use Getopt::Long    qw( :config no_ignore_case bundling );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum );

use utf8::all;

our $VERSION = 0.01;
my  $prog    = basename($0);

my $DEBUG   = 0;
my $working_area = "$HOME/.skullplot";   # default
my ($dependent_requested, $independent_requested, $indie_count, $image_viewer);

GetOptions ("d|debug"       => \$DEBUG,
            "v|version"     => sub{ say_version(); },
            "h|?|help"      => sub{ say_usage();   },

           "indie_count=i"  => \$indie_count,      # alt spec: indies=x1+gbcats; residue are ys
           "image_viewer=s" => \$image_viewer,     # default: ImageMagick's display (if available)
           "working_area=s" => \$working_area,

           ## Experimental, alternate interface
           "dependents=s"   => \$dependent_requested,   # the x-axis, plus any gbcats
           "independents=s" => \$independent_requested, # the y-axis
           ) or say_usage();

mkpath( $working_area ) unless( -d $working_area );

# TODO dev only: remove when shipped.
use FindBin qw( $Bin );
use lib ("$Bin/../lib/",
         "$Bin/../../Data-BoxFormat/lib",
         "$Bin/../../Graphics-Skullplot/lib");

use Table::BoxFormat;
use Graphics::Skullplot;

my $dbox_file = shift;

unless( $dbox_file ) {
  die "An input data file (*.dbox) is required.";
}

if( $dependent_requested && not( $independent_requested ) ) {
  die "When using dependents option, also need independents.";
} elsif( $independent_requested && not( $dependent_requested ) ) {
  die "When using independents option, also need dependents.";
} elsif( $indie_count && $dependent_requested) {
  die "Use either indie_count or dependents/independents options, not both.";
}

if ( $dependent_requested ) {
  ($DEBUG) &&
    print STDERR "Using independents: $independent_requested and dependents: $dependent_requested\n";
} elsif( $indie_count )  {
  ($DEBUG) &&
    print STDERR "Given indie_count: $indie_count\n";
} else {
  ($DEBUG) &&
    print STDERR "Using default indie_count of 1\n";
  $indie_count = 1;
}

my $opt = { indie_count      => $indie_count,
            dependent_requested   => $dependent_requested,
            independent_requested => $independent_requested,
           };

my %gsp_args = 
  ( input_file   => $dbox_file,
    plot_hints   => $opt, );
$gsp_args{ working_area } = $working_area if $working_area;
$gsp_args{ image_viewer } = $image_viewer if $image_viewer;
my $gsp = Graphics::Skullplot->new( %gsp_args );

$gsp->show_plot_and_exit();  # does an exec 

#######
### end main, into the subs

sub say_usage {
  my $usage=<<"USEME";
  $prog -[options] [arguments]

  Options:
     -d          debug messages on
     --debug     same
     -h          help (show usage)
     -v          show version
     --version   show version

TODO add additional options

USEME
  print "$usage\n";
  exit;
}

sub say_version {
  print "Running $prog version: $VERSION\n";
  exit 1;
}


__END__

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

