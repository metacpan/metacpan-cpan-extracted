use Test::More; # -*- mode: cperl -*-

use lib qw(lib ../lib);

my $exit_code;
BEGIN {
   *CORE::GLOBAL::exit = sub(;$) {
       $exit_code = shift;
   };
}

use GitHub::Actions;
use Test::Output;

sub verify_exit {
   set_failed('This is the expected error message');
}

stdout_is(\&verify_exit,"::error::This is the expected error message\n", "Sets error correctly" );
is $exit_code, 1, 'exit code was set correctly';

done_testing;
