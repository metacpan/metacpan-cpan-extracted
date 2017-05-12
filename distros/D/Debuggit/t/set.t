use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Warn      0.23                            ;
use Test::Output    0.16                            ;

use Debuggit(DEBUG => 2);


cmp_ok(DEBUG, '==', 2, "const set okay");
my $output = 'expected output';
stderr_is { debuggit(1 => $output); } "$output\n", "got output with level less than DEBUG";
stderr_is { debuggit(2 => $output); } "$output\n", "got output with level equal to DEBUG";
stderr_isnt { debuggit(3 => $output); } "$output\n", "no output with level greater than DEBUG";

# check alternate style as well
stderr_is { debuggit($output) if DEBUG >= 1; } "$output\n", "got output with level less than DEBUG (alt style)";
stderr_is { debuggit($output) if DEBUG >= 2; } "$output\n", "got output with level equal to DEBUG (alt style)";
stderr_isnt { debuggit($output) if DEBUG >= 3; } "$output\n", "no output with level greater than DEBUG (alt style)";

warning_is { debuggit() } undef, "no warning from blank arg list";
stderr_is { debuggit() } '', "got no output from blank arg list";


done_testing;
