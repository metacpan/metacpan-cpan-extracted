use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Output    0.16                            ;

use Debuggit(DEBUG => 2);


eval {
    package Fallthrough;

    use strict;
    use warnings;

    use Debuggit;

    sub test
    {
        debuggit(2 => $_[0]);
    }

    1;
};


my $output = 'expected output';
stderr_is { Fallthrough::test($output); } "$output\n", "got fallthrough output";


done_testing;
