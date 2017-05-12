use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Output    0.16                            ;

use Debuggit(DEBUG => 2);


my $output = 'expected output';
stderr_is { debuggit(2 => $output); } "$output\n", "established baseline";
stderr_is { debuggit(2 => $output, undef, $output); } "$output <<undef>> $output\n", "output containing undef";


my $leading_spaces = '  expected';
my $trailing_spaces = 'ouput ';
my $with_newline = "expected output\n";
stderr_is { debuggit(2 => $leading_spaces); } "<<$leading_spaces>>\n", "output containing leading spaces";
stderr_is { debuggit(2 => $trailing_spaces); } "<<$trailing_spaces>>\n", "output containing trailing spaces";
stderr_is { debuggit(2 => $with_newline); } "$with_newline\n", "output containing newline";


done_testing;
