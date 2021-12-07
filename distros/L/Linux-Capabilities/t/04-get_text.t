use Test::More;

use Linux::Capabilities;

my $str = "cap_kill+ep";

my $cap = Linux::Capabilities->new($str);
like $cap->get_text, qr/cap_kill[+=]ep/, "check gest for caps: $str";

done_testing;
