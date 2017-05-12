## our out-of-namespace mailer:
package OKMailerOO;
use Test::More;

sub new { return bless {} => shift; }

sub is_available { 1 }

sub send {
  my ($self, $message) = @_;

  ok(1, "mailer $self sent $message");

  return 0 + $self;
}

1;
