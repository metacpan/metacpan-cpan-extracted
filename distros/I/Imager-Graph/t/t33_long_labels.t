#!perl
use strict;

use Imager::Graph::Line;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;
use Imager::Graph::Test 'cmpimg';

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;

my @warned;
local $SIG{__WARN__} =
  sub {
    print STDERR $_[0];
    push @warned, $_[0]
  };


use Imager qw(:handy);

plan tests => 2;


my $font = Imager::Font::Test->new();

my $graph = Imager::Graph::Line->new();
$graph->set_image_width(900);
$graph->set_image_height(600);
$graph->set_font($font);

$graph->add_data_series([1, 2]);
$graph->set_labels(['AWWWWWWWWWWWWWWA', 'AWWWWWWWWWWWWWWWWWWWWWWWWWWWWWA']);

my $img = $graph->draw() || warn $graph->error;

cmpimg($img, 'testimg/t33_long_labels.png', 200_000);
$img->write(file=>'testout/t33_long_labels.ppm') or die "Can't save img1: ".$img->errstr."\n";

unless (is(@warned, 0, "should be no warnings")) {
  diag($_) for @warned;
}
