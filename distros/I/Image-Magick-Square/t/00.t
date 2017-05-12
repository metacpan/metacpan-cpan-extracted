use Test::Simple 'no_plan';
use lib './lib';
use Image::Magick;
use Image::Magick::Square;

my $abs = './t/Hillary1.jpg';

my $abs1 = $abs.'.sq.jpg';



# 1
my $i = new Image::Magick;
$i->Read($abs);
ok( ! is_square($i),'is not square yet' );

ok( $i->Trim2Square, 'Trim2Square' );
ok( is_square($i),'is square now' );
$i->Write($abs1);

my $s = new Image::Magick;
$s->read($abs1);
ok( is_square($s),'saved is square');




# 2
my $i2 = new Image::Magick;
$i2->Read($abs);
ok( ! is_square($i2),'is not square yet' );

Image::Magick::Square::create($i2);
ok( is_square($i2) ,'is square now');





sub is_square {
   my $o = shift;
   my($w,$h) = $o->Get('Width','Height');
   $h and $w or die;
   return ( $w == $h ? 1 : 0 );
}



