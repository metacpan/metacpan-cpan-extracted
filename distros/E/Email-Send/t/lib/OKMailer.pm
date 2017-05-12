## our out-of-namespace mailer:
package OKMailer;
use Test::More;

sub is_available { 1 }

sub send {
  my ($mailer, $message) = @_;

  ok(1, "send $message");
}

1;
