use strict;
use warnings;
use Hypatia;
use Scalar::Util qw(blessed);

my $hypatia=Hypatia->new({
    back_end=>"Chart::Clicker",
    graph_type=>"Line",
    input_data=>{"a1"=>[1..10],"a2"=>[2,6,5,-7,1.4,9,9,0,8,2.71828]},
    columns=>{"x"=>"a1","y"=>"a2"},
});

my $cc=$hypatia->chart;

$cc->title->text("This is a line chart");
my $dc=$cc->get_context("default");
$cc->write_output("line.png");

