package POSIX;

use constant ECHO => 0x1;
use constant ECHOK => 0x2;
use constant ICANON => 0x4;
use constant CS8 => 0x1;
use constant CREAD => 0x2;
use constant CLOCAL => 0x4;
use constant HUPCL => 0x8;
use constant IGNBRK => 0x1;
use constant IGNPAR => 0x2;
use constant B4800 => 0x1;
use constant B9600 => 0x2;
use constant TCSANOW => 0x1;

package POSIX::Termios;

my @calls = ();

sub new {
  my ($pkg, $dev) = @_;
  bless [ @_ ], 'POSIX::Termios';
}
sub calls { @calls }
sub reset_calls { @calls = () }
sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  push @calls, "$AUTOLOAD @_";
}
sub DESTROY {}
1;
