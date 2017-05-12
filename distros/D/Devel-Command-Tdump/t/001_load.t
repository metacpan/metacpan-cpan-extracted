# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 6;

BEGIN { use_ok('Devel::Command::Tdump'); }

# See if the functions we expect are defined.
can_ok("Devel::Command::Tdump", "afterinit");
can_ok("Devel::Command::Tdump", "command");
can_ok("Devel::Command::Tdump", "is_a_test");
can_ok("Devel::Command::Tdump", "is_a_sub");
can_ok("Devel::Command::Tdump", "get_test_names");
