use v5.36;
use lib '../lib';
use LibUI qw[:all];

sub onClosing ( $window, $data ) {
    uiQuit();
    return 1;
}
my $err = uiInit( { Size => 0 } );
if ( defined $err ) {
    printf "Error initializing libui-ng: %s\n", $err;
    uiFreeInitError($err);
    return 1;
}

# Create a new window
my $w = uiNewWindow( 'Hello, World!', 320, 120, 0 );
uiWindowOnClosing( $w, \&onClosing, undef );
uiWindowSetMargined( $w, 1 );
#
my $l = uiNewLabel('Hello, World!');
uiWindowSetChild( $w, $l );
#
uiControlShow($w);
uiMain();
uiUninit()
