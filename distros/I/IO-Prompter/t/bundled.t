use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Line 1
Line 2
END_INPUT

my $result = prompt "Enter line 1", -lt0v;
is $result, "Line 1\n"  => '-l effective';
ok !ref($result)        => '-v effective';
