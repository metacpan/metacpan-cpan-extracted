#!perl -w
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

plan tests => 4;

#my $fontfile = 'ImUgly.ttf';
#my $font = Imager::Font->new(file=>$fontfile, type => 'ft2', aa=>1)
#  or plan skip_all => "Cannot create font object: ",Imager->errstr,"\n";
my $font = Imager::Font::Test->new();

my @data = (1 .. 7);
my @labels = qw(alpha beta gamma delta epsilon phi gi);

my $line = Imager::Graph::Line->new();
ok($line, "creating line chart object");

$line->set_font($font);
$line->add_data_series(\@data);
$line->set_labels(\@labels);
$line->use_automatic_axis();
$line->set_y_tics(5);


my $img1 = $line->draw(outline => {line => '#FF0000'});
ok($img1, "drawing line chart");

$img1->write(file=>'testout/t31tic_color.ppm') or die "Can't save img1: ".$img1->errstr."\n";

eval { require Chart::Math::Axis; };
if ($@) {
    cmpimg($img1, 'testimg/t31tic_color.png', 100_000);
}
else {
    cmpimg($img1, 'testimg/t31tic_color_CMA.png', 100_000);
}

unless (is(@warned, 0, "should be no warnings")) {
  diag($_) for @warned;
}

