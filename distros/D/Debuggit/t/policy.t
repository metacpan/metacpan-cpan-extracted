use strict;
use warnings;

use lib 't/lib';

use Test::More      0.88                            ;
use Test::Output    0.16                            ;
use Test::Exception 0.31                            ;

use MyDebuggit(DEBUG => 2);


lives_ok { debuggit(4) } "debuggit() exported";

my $output = 'expected output';
stderr_is { debuggit(2 => $output); } "XX: $output\n", "policy file carries DEBUG; sets debuggit()";


{
    package foo;

    use strict;
    use warnings;

    use Test::Output;

    # don't have to specify DEBUG here because it will fallthrough from above
    use MyDebuggit;


    stderr_is { debuggit(2 => $output); } "XX: $output\n", "still right after second import";
}


done_testing;
