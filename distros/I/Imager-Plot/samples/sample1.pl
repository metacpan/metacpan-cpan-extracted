#!/usr/bin/perl -w

use lib qw(blib/lib blib/arch);

use Imager qw(:handy);
use Imager::Plot;

Imager::Font->priorities(qw(w32 ft2 tt t1));

@X  = map { $_/10.0 } 0..100;
@Y  = map { sin } @X;
@XY = map { [$X[$_]+1, $Y[$_]+1] } 0..$#X;


$plot = Imager::Plot->new(Width  => 500,
			  Height => 300,
			  GlobalFont => get_font() );

$plot->AddDataSet(X  => \@X, Y => \@Y);
$plot->AddDataSet(XY => \@XY,
		  style=>{marker=>{size   => 2,
				   symbol => 'circle',
				   color  => NC(0,120,0)
				  },
			 });


$Axis = $plot->GetAxis();
# Make a cleaner plot with less chartjunk


# Skip grid

$Axis->{XgridShow} = 1;
$Axis->{YgridShow} = 0;

# Only draw left and bottom edge

$Axis->{Border} = "bt";

# Put 10% white space on each border from data

$Axis->{make_xrange} = sub {
  $self = shift;
  my @drange = @{$self->{XDRANGE}};
  my $diff = $drange[1]-$drange[0];
  $self->{XRANGE} = [$drange[0] - $diff/10,
		     $drange[1] + $diff/10];
};

$Axis->{make_yrange} = sub {
  $self = shift;
  my @drange = @{$self->{YDRANGE}};
  my $diff = $drange[1]-$drange[0];
  $self->{YRANGE} = [$drange[0] - $diff/10,
		     $drange[1] + $diff/10];
};




$img = Imager->new(xsize=>600, ysize => 400);
$img->box(filled=>1, color=>Imager::Color->new(255,255,255));

$plot->Render(Image => $img, Xoff => 30, Yoff => 340);


mkdir("sampleout", 0777) unless -d "sampleout";
$img->write(file => "sampleout/sample1.ppm")
    or die $img->errstr;



sub get_font {
  my %opts = (size=>12, color=>Imager::Color->new('black'));

  my $font = Imager::Font->new(file=>"ImUgly.ttf", %opts)
    || Imager::Font->new(file=>"./dcr10.pfb", %opts);
  die "Couldn't load any font!\n" unless $font;

  return $font;
}
