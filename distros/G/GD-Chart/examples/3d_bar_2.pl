use strict;
use GD::Chart;

my(@cols)=( hex 'ff8080', hex '8080ff' );
my(@labels)=("Chicago","New York","L.A.","Atlanta","Paris, MD\n(USA)","London");
my(@data)=([0.09,0.5,0.85,1.0,0.0,0.90] ,[1.9,1.3,0.6,0.75,0.1,2.0]);


my(%opts) = (
	'data' => \@data,
	'bgcolor' => hex 'ffffff',
	'color' => \@cols,
	'image_type' => $GD::Chart::GDC_PNG,
	'chart_type' => $GD::Chart::GDC_3DBAR,
	'labels'  => \@labels,
);

my $c = new GD::Chart(250, 250);

$c->options( \%opts );

$c->fd(\*STDOUT);

$c->draw();

exit;
