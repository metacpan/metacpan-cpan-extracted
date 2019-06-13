use Test::More;

use Linux::Capabilities;

my $str = "cap_kill+ep";

my $cap = Linux::Capabilities->new($str);
is ($cap->get_text, "= ".$str, "check gest for caps: $str");

done_testing;