#!/usr/bin/perl -w

use lib qw(blib/lib blib/arch);

use Imager;
use Imager::Plot;

Imager::Font->priorities(qw(w32 ft2 tt t1));

$plot = Imager::Plot->new(Width  => 550,
			  Height => 350,
			  GlobalFont => get_font());

my @X = map { $_+ 0.5*cos($_/2) } 0..20;
my @Y = map { sin($_/2) } @X;
my @Z = map { [$Y[$_] + 0.2 + 0.3*cos($_/20)**2, $Y[$_]-.13] } 0..$#X;


sub magic_marker {
    my ($DataSet, $xr, $yr, $Xmapper, $Ymapper, $img, $opts) = @_;

    my @x = @$xr;
    my @y = @$yr;
    my @z = @{$DataSet->{Z}};

    for (0..$#x) {
	$img->circle(x=>$x[$_], y=>$y[$_], r=>3, color=>"blue", aa=>1);
	my @ym = $Ymapper->(@{$z[$_]});
	$img->line(x1=>$x[$_], x2=>$x[$_], y1=>$ym[0], y2=>$ym[1], color=>"red");
    }
}



$plot->AddDataSet(X  => \@X, Y => \@Y, Z=>\@Z, style=>{
    code=>{
	ref=>\&magic_marker,
	opts=>undef
	}});

$Axis = $plot->GetAxis();

$Axis->{make_xrange} = sub {
    $self = shift;
    my $min = $self->{XDRANGE}->[0]-1;
    my $max = $self->{XDRANGE}->[1]+1;
    $self->{XRANGE} = [$min, $max];
};

$Axis->{make_yrange} = sub {
    $self = shift;
    my $min = $self->{YDRANGE}->[0]-2;
    my $max = $self->{YDRANGE}->[1]+2;
    $self->{YRANGE} = [$min, $max];
};

$Axis->{Border} = ""; # No edges of graph area

$img = Imager->new(xsize=>600, ysize => 400);
$img->box(filled=>1, color=>'white');

$plot->{'Ylabel'} = 'Acceleration';
$plot->{'Xlabel'} = 'time';
$plot->{'Title'} = 'Acceleration of a sled';

$plot->Render(Image => $img, Xoff => 40, Yoff => 370);

mkdir("sampleout", 0777) unless -d "sampleout";
$img->write(file => "sampleout/sample4.ppm");



sub get_font {
  my %opts = (size=>12, color=>Imager::Color->new('black'));

  my $font = Imager::Font->new(file=>"ImUgly.ttf", %opts)
    || Imager::Font->new(file=>"./dcr10.pfb", %opts);
  die "Couldn't load any font!\n" unless $font;

  return $font;
}
