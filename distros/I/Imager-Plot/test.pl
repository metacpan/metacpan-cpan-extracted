# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Imager::Plot;
use Imager qw(:handy);
$loaded = 1;
print "ok 1\n";

mkdir("testout", 0777) unless -d "testout";


@X = -10..10;
@Y = map { $_**3 } @X;

$Axis = Imager::Plot::Axis->new(Width => 200, Height => 180, GlobalFont=>get_font() );
$Axis->AddDataSet(X => \@X, Y => \@Y);

$Axis->{XgridShow} = 1;  # Xgrid enabled
$Axis->{YgridShow} = 0;  # Ygrid disabled

$Axis->{Border} = "lrb"; # left right and bottom edges

$Axis->{BackGround} = "#cccccc";

# Override the default function that chooses the x range
# of the graph

$Axis->{make_xrange} = sub {
    $self = shift;
    my $min = $self->{XDRANGE}->[0]-1;
    my $max = $self->{XDRANGE}->[1]+1;
    $self->{XRANGE} = [$min, $max];
};

$img = Imager->new(xsize=>300, ysize => 220);
$img->box(filled=>1, color=>"white");

$Axis->Render(Xoff=>50, Yoff=>200, Image=>$img);

$img->write(file=>"testout/test1.ppm") or die $img->errstr;

# Axis test done

print "ok 2\n";





$plot = Imager::Plot->new(Width  => 550,
			  Height => 350,
			  GlobalFont => get_font() );

my @X = 0..50;
my @Y = map { sin($_/10) } @X;


$plot->AddDataSet(X  => \@X, Y => \@Y, style=>{marker=>{size=>4,
							symbol=>'circle',
							color=>Imager::Color->new('blue'),
						    }});

$img = Imager->new(xsize=>600, ysize => 400);
$img->box(filled=>1, color=>'white');

$plot->{'Ylabel'} = 'angst';
$plot->{'Xlabel'} = 'time';
$plot->{'Title'} = 'Quality time';

$plot->Render(Image => $img, Xoff => 40, Yoff => 370);
$img->write(file => "testout/test2.ppm");

# Plot test done
print "ok 3\n";


sub get_font {
  my $font = Imager::Font->new(file=>"ImUgly.ttf")
    || Imager::Font->new(file=>"./dcr10.pfb", color=>Imager::Color->new('black'));
  die "Couldn't load any font!\n" unless $font;

  return $font;
}
