package JiftyTest;
our $VERSION = '0.07';


use File::Basename;
use Cwd 'abs_path';

$ENV{'JIFTY_APP_ROOT'} = abs_path( dirname( abs_path(__FILE__) ) . "/../" );

sub start {
  Jifty->web->add_javascript("main.js");
}

1;
