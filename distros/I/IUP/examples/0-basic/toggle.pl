# IUP::Toggle example
#
# Creates 9 toggles
#   the first one has an image and an associated callback
#   the second has an image and is deactivated
#   the third is regular
#   the fourth has its foreground color changed
#   the fifth has its background color changed
#   the sixth has its foreground and background colors changed
#   the seventh is deactivated
#   the eight has its font changed
#   the ninth has its size changed

use strict;
use warnings;

use IUP ':all';

my $img1 = IUP::Image->new( pixels=>
      [[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,2,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,2,2,2,2,2,2,2,2,2,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      ], colors=>["0 0 0", "255 255 255", "0 192 0"]
);

my $img2 = IUP::Image->new( pixels=>
      [[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,2,2,2,2,2,2,1,1,1,1,1,1],
       [1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,2,2,2,2,2,2,2,2,2,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
       [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      ], colors=>["0 0 0", "255 255 255", "0 192 0"]
);

my $toggle1 = IUP::Toggle->new( TITLE=>"", IMAGE=>$img1 );
my $toggle2 = IUP::Toggle->new( TITLE=>"deactivated toggle with image", IMAGE=>$img2, ACTIVE=>"NO" );
my $toggle3 = IUP::Toggle->new( TITLE=>"regular toggle" );
my $toggle4 = IUP::Toggle->new( TITLE=>"toggle with blue foreground color", FGCOLOR=>"0 0 222" );
my $toggle5 = IUP::Toggle->new( TITLE=>"toggle with red background color", BGCOLOR=>"222 0 0" );
my $toggle6 = IUP::Toggle->new( TITLE=>"toggle with black backgrounf color and green foreground color", FGCOLOR=>"0 222 0", BGCOLOR=>"0 0 0" );
my $toggle7 = IUP::Toggle->new( TITLE=>"deactivated toggle", ACTIVE=>"NO" );
my $toggle8 = IUP::Toggle->new( TITLE=>"toggle with Courier 14 Bold font", FONT=>"COURIER_BOLD_14" );
my $toggle9 = IUP::Toggle->new( TITLE=>"toggle with size EIGHTxEIGHT", SIZE=>"EIGHTHxEIGHTH" );

$toggle1->ACTION( sub {
  my ($self, $v) = @_;
  my $estado = ($v == 1) ? "pressed" : "released";
  print STDERR "Toggle 1: v=$v action=$estado\n";
  return IUP_DEFAULT;
} );

my $box = IUP::Vbox->new( child=>[
                 $toggle1,
                 $toggle2,
                 $toggle3,
                 $toggle4,
                 $toggle5,
                 $toggle6,
                 $toggle7,
                 $toggle8,
                 $toggle9,
               ] );

my $toggles = IUP::Radio->new( child=>$box, EXPAND=>"YES" );
my $dlg = IUP::Dialog->new( child=>$toggles, TITLE=>"IupToggle", MARGIN=>"5x5", GAP=>"5", RESIZE=>"NO" );
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);

IUP->MainLoop();
