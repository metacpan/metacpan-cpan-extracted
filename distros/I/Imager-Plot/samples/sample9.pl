#!/usr/bin/perl -w

use lib qw(blib/lib blib/arch);

use Imager;
use Imager::Plot::Axis;

Imager::Font->priorities(qw(w32 ft2 tt t1));

# Create our dummy data
@X = -10..10;
@Y = map { $_**2+$_**3 } @X;

# Create Axis object

$Axis = Imager::Plot::Axis->new(Width => 200, Height => 180, GlobalFont=>get_font());
$Axis->AddDataSet(X => \@X, Y => \@Y, style=>{area=>{color=>"red"}});

$Axis->{XgridShow} = 1;  # Xgrid enabled
$Axis->{YgridShow} = 0;  # Ygrid disabled

$Axis->{Border} = "lrb"; # left right and bottom edges

# See Imager::Color manpage for color specification
$Axis->{BackGround} = "#cccccc";

# Override the default function that chooses the x range
# of the graph, similar exists for y range

$Axis->{make_xrange} = sub {
    $self = shift;
    my $min = $self->{XDRANGE}->[0]-1;
    my $max = $self->{XDRANGE}->[1]+1;
    $self->{XRANGE} = [$min, $max];
};

$img = Imager->new(xsize=>240, ysize => 230);
$img->box(filled=>1, color=>"white");

$Axis->Render(Xoff=>30, Yoff=>200, Image=>$img);

mkdir("sampleout", 0777) unless -d "sampleout";
$img->write(file => "sampleout/sample9.ppm")
    or die $img->errstr;


sub get_font {
  my %opts = (size=>12, color=>Imager::Color->new('black'));

  my $font = Imager::Font->new(file=>"ImUgly.ttf", %opts)
    || Imager::Font->new(file=>"./dcr10.pfb", %opts);
  die "Couldn't load any font!\n" unless $font;

  return $font;
}
