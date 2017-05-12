use strict;
use warnings;

use Test::More;
use Gtk2::TestHelper tests => 2;

use Gtk2 -init;
use Keybinder;

my $cb = sub { };
my $key = "<Ctrl>A";

ok bind_key($key, $cb), "$key binded successfully to coderef";
unbind_key($key);
ok bind_key($key, $cb), "$key binded successfully to coderef";

done_testing;
