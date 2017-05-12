#!perl -w
use strict;
use Imager::Graph::Bar;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;
use Imager::Graph::Test 'cmpimg';

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;

use Imager qw(:handy);

plan tests => 11;

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
  my $bar = Imager::Graph::Bar->new();
  $bar->set_font($font);
  ok($bar, "creating bar chart object");

  $bar->add_data_series(\@data);
  $bar->set_labels(\@labels);

  my $img1 = $bar->draw();
  ok($img1, "drawing bar chart");

  $img1->write(file=>'testout/t14_bar.ppm') or die "Can't save img1: ".$img1->errstr."\n";
  cmpimg($img1, 'testimg/t14_bar.png', 80_000);
}

{ # alternative interfaces
  my $bar = Imager::Graph::Horizontal->new();
  $bar->set_font($font);
  ok($bar, "creating bar chart object");

  $bar->add_bar_data_series(\@data);
  $bar->set_labels(\@labels);

  my $img1 = $bar->draw();
  ok($img1, "drawing bar chart");

  $img1->write(file=>'testout/t14_bar2.ppm') or die "Can't save img1: ".$img1->errstr."\n";
  cmpimg($img1, 'testimg/t14_bar.png', 80_000);
}

{
  my $bar = Imager::Graph::Bar->new();
  $bar->set_font($font);
  ok($bar, "creating bar chart object");

  $bar->add_data_series([ @data, -25 ]);
  $bar->set_labels([ @labels, "neg" ]);

  my $img1 = $bar->draw();
  ok($img1, "drawing bar chart (negative values)");

  $img1->write(file=>'testout/t14_bar3.ppm') or die "Can't save img1: ".$img1->errstr."\n";
  #cmpimg($img1, 'testimg/t14_bar.ppm', 80_000);
}

{
  my $bar = Imager::Graph::Bar->new();
  $bar->set_font($font);
  ok($bar, "creating bar chart object");

  $bar->add_data_series([ @data, -25 ]);
  $bar->set_labels([ @labels, "neg" ]);

  my $fountain = Imager::Fountain->simple(colors => [ "#C0C0FF", "#E0E0FF" ],
					  positions => [ 0, 1 ]);

  my %fill =
    (
     fountain => "linear",
     segments => $fountain,
     xa_ratio => 0.5,
     ya_ratio => -0.1,
     xb_ratio => 0.55,
     yb_ratio => 1.1,
    );

  $bar->set_negative_background(\%fill);

  my $img1 = $bar->draw();
  ok($img1, "drawing bar chart (negative values, custom fill)");

  $img1->write(file=>'testout/t14_bar4.ppm') or die "Can't save img1: ".$img1->errstr."\n";
  #cmpimg($img1, 'testimg/t14_bar.ppm', 80_000);
}

unless (is(@warned, 0, "should be no warnings")) {
  diag($_) for @warned;
}

