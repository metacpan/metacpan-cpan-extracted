#!perl -w -I ../lib
#
# example: diveplot.pl --data ../t/data/deep_deco.txt --file deep.png --timefactor 20 --separator ','
use strict;
use Deco::Dive;
use Deco::Dive::Plot;
use Getopt::Long;

# some defaults
my $model = 'haldane';
my $confdir = '../conf';
my $file    = 'pressures.png';
my $data    = '../t/data/dive.txt';
my $width   = 600;
my $height  = 400;
my $factor  = 1;
my $separator = ';';

GetOptions ( "file=s"   => \$file ,
             "data=s"   => \$data ,
             "width=i"   => \$width ,
             "height=i"   => \$height ,
	     "model=s"   => \$model,
	     "timefactor=i"   => \$factor,
	     "separator=s"   => \$separator,
	     "confdir=s"  => \$confdir,
             );

my $dive = Deco::Dive->new(configdir => $confdir );
# first load some data
$dive->load_data_from_file( file => $data, timefactor => $factor, separator => $separator );

# and simulate haldane model
$dive->simulate( model => $model);

my $diveplot = Deco::Dive::Plot->new( $dive, width => $width, height => $height );

# do the pressure graph
if (-e $file) {
   unlink($file);
}
$diveplot->pressures( file => $file);

$diveplot->depth( );

$diveplot->nodeco( );

