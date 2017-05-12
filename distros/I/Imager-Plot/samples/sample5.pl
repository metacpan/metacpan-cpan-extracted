#!/usr/bin/perl -w

use lib qw(blib/lib blib/arch);

use Imager;
use Imager::Plot;

Imager::Font->priorities(qw(w32 ft2 tt t1));

$plot = Imager::Plot->new(Width  => 550,
			  Height => 350,
			  GlobalFont => get_font() );

my @X = 0..100;
my @Y = map { sin($_/10) } @X;
my @Z = map { 2.5+2*cos($_/10) } @X;


sub magic_marker {
    my ($DataSet, $xr, $yr, $Xmapper, $Ymapper, $img, $opts) = @_;

    my @x = @$xr;
    my @y = @$yr;
    my @z = @{$DataSet->{Z}};

    for (0..$#x) {
	$img->circle(x=>$x[$_], y=>$y[$_], r=>$z[$_], color=>"blue", aa=>1);
    }
}



$plot->AddDataSet(X  => \@X, Y => \@Y, Z=>\@Z, style=>{
    code=>{
	ref=>\&magic_marker,
	opts=>undef
	}});

$img = Imager->new(xsize=>600, ysize => 400);
$img->box(filled=>1, color=>'white');

$Axis = $plot->GetAxis();

# this is mighty handy for time formating

$Axis->{Xformat} = sub {
  my @n = qw(zero one two three four five six seven eight nine ten);
  my $t = sprintf("%.0f",$_[0]/10);
  $t = 0 if $t<0;
  $t = 10 if $t>10;
  return $n[$t];
};

$plot->{'Ylabel'} = 'angst';
$plot->{'Xlabel'} = 'time';
$plot->{'Title'} = 'Quality time';

$plot->Render(Image => $img, Xoff => 40, Yoff => 370);

mkdir("sampleout", 0777) unless -d "sampleout";
$img->write(file => "sampleout/sample5.ppm");


sub get_font {
  my %opts = (size=>12, color=>Imager::Color->new('black'));

  my $font = Imager::Font->new(file=>"ImUgly.ttf", %opts)
    || Imager::Font->new(file=>"./dcr10.pfb", %opts);
  die "Couldn't load any font!\n" unless $font;

  return $font;
}
