use strict;
use GD::Chart;

### Example taken from gdchart test2.c

my(@cols)=( hex 'C0C0FF', hex 'FF4040', hex 'FFFFFF' );
my(@labels)= qw(May Jun Jul Aug Sep Oct Nov Dec Jan Feb Mar Apr);
my(@data)=(

[ 17.8, 17.1, 17.3, $GD::Chart::GDC_NOVALUE, 17.2, 17.1, 17.3, 17.3, 17.3, 17.1,    17.5, 17.4 ],


[ 16.8, 16.8, 16.7, $GD::Chart::GDC_NOVALUE, 16.5, 16.0, 16.1, 16.8, 16.5, 16.9,    16.2, 16.0],

[ 17.0, 16.8, 16.9, $GD::Chart::GDC_NOVALUE, 16.9, 16.8, 17.2, 16.8, 17.0, 16.9,    16.4, 16.1],
);

my(@v) = ( 150.0, 100.0, 340.0, $GD::Chart::GDC_NOVALUE, 999.0, 390.0, 420.0, 150.0, 100.0,  340.0, 1590.0, 700.0);

my $c = new GD::Chart(200, 175);

my $anno = new GD::Chart::note("Did Not\nTrade", hex '00ff00', 3, $GD::Chart::GDC_TINY);

my(%opts) = (
hlc_style => $GD::Chart::GDC_HLC_I_CAP | $GD::Chart::GDC_HLC_CLOSE_CONNECTED,
hlc_cap_width => 45,
title => "Widget Corp.",
ytitle => "Price (\$)",
ytitle2 => "Volume (K)",
title_size => $GD::Chart::GDC_SMALL,
ytitle_size => $GD::Chart::GDC_SMALL,
volcolor => hex '4040ff',
'3d_depth' => 4.0,
plotcolor => hex 'ffffff',
grid => $GD::Chart::FALSE,
bgcolor => hex '000000',
chart_type => $GD::Chart::GDC_COMBO_HLC_AREA,
image_type => $GD::Chart::GDC_PNG,
data => \@data,
labels => \@labels,
volume => \@v,
bar_width => 75,
note => $anno
);

$c->options( \%opts );

open(FD, ">note.png");

$c->fd(\*FD);

$c->draw();

close(FD);

exit;
