use strict;
use warnings;
use Test::More tests => 6;
use GD;

our $PKG = 'GD::Sparkline';
use_ok($PKG);
can_ok($PKG, qw(new fields draw type_b));

{
  my $sl = $PKG->new();
  isa_ok($sl, $PKG);
}

{
  my $sl = GD::Sparkline->new({
			       s   => q[10,0,10],
			       l   => '000000',
			       a   => '003366',
			       b   => 'CCCCCC',
			       w   => 100,
			       h   => 20,
			      });
  my $image = $sl->draw();
  like($image, qr/PNG/smix, q[generate something which looks like a PNG]);
}

{
  my $sl = GD::Sparkline->new({
			       s   => q[4,4,4,4,4,4],
			       l   => '000000',
			       a   => '003366',
			       b   => 'CCCCCC',
			      });
  ok($sl->draw(), q[handle divide-by-zero]);
}

{
  my $sl = GD::Sparkline->new({
			       s   => q[10,0,10],
			       l   => '000000',
			       a   => '003366',
			       b   => 'transparent',
			       w   => 100,
			       h   => 20,
			      });
  my $image = $sl->draw();
  my $gd = GD::Image->newFromPngData($image);
  my $transparent = $gd->transparent();
  isnt($transparent, -1, 'image has transparency index set');
}
