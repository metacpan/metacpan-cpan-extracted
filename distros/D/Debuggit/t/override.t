use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Output    0.16                            ;

use Debuggit DEBUG => 1;


eval {
    package Override;

    use strict;
    use warnings;

    use Debuggit DEBUG => 2;

    sub print_it
    {
        print "DEBUG is ", DEBUG;
    }

    sub test
    {
        debuggit(2 => $_[0]);
    }

    1;
};


stdout_is { Override::print_it() } 'DEBUG is 2', "DEBUG overrides successfully";

my $output = 'expected output';
stderr_is { Override::test($output) } "$output\n", "got override output";


done_testing;
