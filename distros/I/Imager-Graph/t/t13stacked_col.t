#!perl -w
use strict;
use Imager::Graph::StackedColumn;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;

use Imager qw(:handy);

plan tests => 5;

my @warned;
local $SIG{__WARN__} =
  sub {
    print STDERR $_[0];
    push @warned, $_[0]
  };


#my $fontfile = 'ImUgly.ttf';
#my $font = Imager::Font->new(file=>$fontfile, type => 'ft2', aa=>1)
#  or plan skip_all => "Cannot create font object: ",Imager->errstr,"\n";
my $font = Imager::Font::Test->new();

my @data = ( 100, 180, 80, 20, 2, 1, 0.5 );
my @labels = qw(alpha beta gamma delta epsilon phi gi);

{
  my $stacked_col = Imager::Graph::StackedColumn->new();
  ok($stacked_col, "creating stacked_col chart object");

  $stacked_col->add_data_series(\@data);
  $stacked_col->set_labels(\@labels);

  my $img1 = $stacked_col->draw();
  ok($img1, "drawing stacked_col chart");

  $img1->write(file=>'testout/t13_stacked.ppm') or die "Can't save img1: ".$img1->errstr."\n";
}

{
  my $stacked_col = Imager::Graph::StackedColumn->new();
  ok($stacked_col, "creating stacked_col chart object");

  $stacked_col->add_data_series(\@data);
  $stacked_col->add_data_series([ -50, -30, 20, 10, -10, 25, 10 ]);
  $stacked_col->set_labels(\@labels);

  my $img1 = $stacked_col->draw
    (
     features => "outline",
     column_padding => 10,
    );
  ok($img1, "drawing stacked_col chart");

  $img1->write(file=>'testout/t13_stacked2.ppm') or die "Can't save stacked2: ".$img1->errstr."\n";
}

unless (is(@warned, 0, "should be no warnings")) {
  diag($_) for @warned;
}
