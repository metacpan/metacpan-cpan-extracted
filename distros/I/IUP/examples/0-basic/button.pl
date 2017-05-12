# IUP::Button example
#
# Creates four buttons. The first uses images, the second turns the first
# on and off, the third exits the application and the last does nothing

use strict;
use warnings;

use IUP ':all';

# defines released button image;
my $img_release = IUP::Image->new( pixels=>
     [[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
      [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
     ], colors=>["0 0 0", "215 215 215", "40 40 40", "30 50 210", "240 0 0"]
);

# defines pressed button image;
my $img_press = IUP::Image->new( pixels=>
     [[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,4,4,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,4,4,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
      [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
     ], colors=>["0 0 0", "40 40 40", "215 215 215", "0 20 180", "210 0 0"]
);

# defines deactivated button image;
my $img_inactive = IUP::Image->new( pixels=>
     [[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2],
      [1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2],
      [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
      [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
     ], colors=>["0 0 0", "215 215 215", "40 40 40", "100 100 100", "200 200 200"]
);

# creates a text box
my $text = IUP::Text->new( READONLY=>"YES", SIZE=>"EIGHTH" );

# creates a button with image
my $btn_image = IUP::Button->new( TITLE=>"Button with image", PADDING=>"3x3", IMAGE=>$img_release, IMPRESS=>$img_press, IMINACTIVE=>$img_inactive );

# creates a button
my $btn_big = IUP::Button->new( TITLE=>"Big useless button", PADDING=>"3x3", SIZE=>"EIGHTHxEIGHTH" );

# creates a button entitled Exit
my $btn_exit = IUP::Button->new( TITLE=>"Exit", PADDING=>"3x3" );

# creates a button entitled on/off
my $btn_on_off = IUP::Button->new( TITLE=>"on/off", PADDING=>"3x3" );

# creates a dialog and sets dialog's title and turns off resize, menubox, maximize and minimize
my $dlg = IUP::Dialog->new( child=>IUP::Vbox->new( MARGIN=>"3x3", child=>[
                                IUP::Hbox->new( child=>[ IUP::Fill->new(), $btn_image, $btn_on_off, $btn_exit, IUP::Fill->new() ]),
                                $text, 
                                $btn_big
                              ] ), TITLE=>"IupButton", RESIZE=>"NO", MENUBOX=>"NO", MAXBOX=>"NO", MINBOX=>"NO");

# callback called when activate button is activated;
$btn_on_off->ACTION( sub {
  if ( $btn_image->ACTIVE eq "YES" ) {
    $btn_image->ACTIVE("NO");
  }
  else {
    $btn_image->ACTIVE("YES");
  }
  return IUP_DEFAULT;
} );

# callback called when the button is pressed or released
sub cb_btn_image {
  my ($self, $b, $e) = @_;
  if ( $b == IUP_BUTTON1 ) {
    if ( $e == 1 ) {
      $text->VALUE("Red button pressed");
    }
    else {
      $text->VALUE("Red button released");
    }
  }
  return IUP_DEFAULT;
}
$btn_image->BUTTON_CB(\&cb_btn_image);

# callback called when the exit button is activated
$btn_exit->ACTION( sub { $dlg->Hide() } );

# shows dialog
$dlg->ShowXY( IUP_CENTER, IUP_CENTER );

IUP->MainLoop;
