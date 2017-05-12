use strict;
use warnings;

use Test::More      0.88                            ;
use Test::Output    0.16                            ;

use Debuggit(DEBUG => 2);


my $output = 'expected output';
stderr_is { debuggit(2 => $output); } "$output\n", "established baseline";

{
    my $time = scalar(localtime);
    local $Debuggit::formatter = sub { return $time . ': ' . join(' ', @_) . "\n" };
    stderr_is { debuggit(2 => $output); } "$time: $output\n", "basic format override works";
}

stderr_is { debuggit(2 => $output); } "$output\n", "format returned to normal";

{
    my $prefix = "XX: ";
    local $Debuggit::formatter = sub { return $prefix . Debuggit::default_formatter(@_) };
    stderr_is { debuggit(2 => $output); } "$prefix$output\n", "format override using default works";
}

stderr_is { debuggit(2 => $output); } "$output\n", "format returned to normal";

foo();
stderr_is { debuggit(2 => $output); } "$output\n", "format returned to normal";


done_testing;


sub foo
{
    my $sub = (caller(0))[3];
    my $catcher = '';
    local $Debuggit::formatter = sub { return (caller(2))[3] . ': ' . Debuggit::default_formatter(@_) };
    local $Debuggit::output = sub { $catcher .= join('', @_) };
    debuggit(2 => $output);
    is($catcher, "$sub: $output\n", "format override using caller works");
}
