#!/usr/bin/perl -w

use lib qw(blib/lib blib/arch);

use Imager;
use Imager::Plot;
use Time::Local;

Imager::Font->priorities(qw(w32 ft2 tt t1));

$plot = Imager::Plot->new(Width  => 400,
			  Height => 350,
			  GlobalFont => get_font() );

$img = Imager->new(xsize=>450, ysize => 400);
$img->box(filled=>1, color=>'white');



@height = map { $_ + 15*(rand()-.5) } 100..180;
@weight = map { ($_)/3 + 35*(rand()-.5) } 100..180;


my ($minh, $maxh) = (sort {$a<=>$b} @height)[0,-1];
my ($a, $b) = ls_fit(\@height, \@weight);

@FIT = ([$minh, $a+$b*$minh], [$maxh, $a+$b*$maxh]);




$plot->AddDataSet(X=>\@height, Y=>\@weight, style=>{code=>{
    ref=>\&bar_style,
    opts=>undef}});

$plot->AddDataSet(XY=>\@FIT, style=>{line=>{color=>'red', antialias=>1}});







#$plot->AddDataSet(XY => \@tr, style=>{code=>{
#					     ref=>\&bar_style,
#					     opts=>undef
#					    }});



$Axis = $plot->GetAxis();

# this is mighty handy for time formating

$Axis->{YgridNum} = 8;
$Axis->{XgridNum} = 10;
$Axis->{Border} = "lb";


$Axis->{make_xrange} = sub {
  $self = shift;
  my $span = $self->{XDRANGE}->[1]-$self->{XDRANGE}->[0];
  $self->{XRANGE} = [$self->{XDRANGE}->[0]-$span*0.05,
		     $self->{XDRANGE}->[1]+$span*0.05];
};

$Axis->{make_yrange} = sub {
  $self = shift;
  my $span = $self->{YDRANGE}->[1]-$self->{YDRANGE}->[0];

  $self->{YRANGE} = [$self->{YDRANGE}->[0]-$span*0.2,
		     $self->{YDRANGE}->[1]+$span*0.2];
};


$plot->{'Ylabel'} = 'Weight [kg]';
$plot->{'Xlabel'} = 'Height [cm]';
$plot->{'Title'} = 'Scatter of Relation';


sub bar_style {
  my ($DataSet, $xr, $yr, $Xmapper, $Ymapper, $img, $opts) = @_;

  my @x = @$xr;
  my @y = @$yr;

  for (0..$#x) {
      $img->box(color=>'blue', xmin=>$x[$_]-2, xmax=>$x[$_]+2, ymin=>$y[$_]-2, ymax=>$y[$_]+2, filled=>1);
  }
}


$plot->Render(Image => $img, Xoff => 40, Yoff => 370);

mkdir("sampleout", 0777) unless -d "sampleout";
$img->write(file => "sampleout/sample8.ppm");



# find the coefficients for matching
# y = a+bx in the least squares sense to input data

sub ls_fit {
  my @x = @{$_[0]};
  my @y = @{$_[1]};

  my $mx = mean(@x);
  my $my = mean(@y);
  my $varx = sum(map { $_*$_ } @x) - @x * $mx*$mx;
  my $vary = sum(map { $_*$_ } @y) - @y * $my*$my;

  my $covxy = sum(map { $x[$_]*$y[$_] } 0..$#x)-@x*$mx*$my;

  my $b = $covxy / $varx;
  my $a = $my - $b*$mx;
  return ($a, $b);
}

sub sum {
  my $t = 0;
  $t+=$_ for @_;
  $t;
}

sub mean {
  return sum(@_)/@_;
}



sub get_font {
  my %opts = (size=>12, color=>Imager::Color->new('black'));

  my $font = Imager::Font->new(file=>"ImUgly.ttf", %opts)
    || Imager::Font->new(file=>"./dcr10.pfb", %opts);
  die "Couldn't load any font!\n" unless $font;

  return $font;
}
