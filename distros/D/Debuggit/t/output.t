use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Output    0.16                            ;

use Debuggit(DEBUG => 2);


my $output = 'expected output';
stderr_is { debuggit(2 => $output); } "$output\n", "established baseline";

{
    local $Debuggit::output = sub { print @_ };
    stdout_is { debuggit(2 => $output); } "$output\n", "redirect to stdout works";
    stderr_isnt { debuggit(2 => $output); } "$output\n", "not printing to stderr";
}

stderr_is { debuggit(2 => $output); } "$output\n", "output returned to normal";

my $catcher;
$Debuggit::output = sub { $catcher .= join('', @_) };
debuggit(2 => $output);
is($catcher, "$output\n", "can output to a string");


done_testing;
