use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
a Line 1
b Line 2
c Line 3
END_INPUT

if (prompt -single, "Enter line 1") {
    is $_, 'a'  => 'First character retrieved';
}
else {
    fail 'First line retrieved'; 
}

$_ = 'UNDERBAR';
if (my $input = prompt -1, "Enter character 2") {
    is $input, 'b'        => 'Second character retrieved';
    is $_,     'UNDERBAR' => 'Second line left $_ alone'
}
else {
    fail 'Second line retrieved'; 
}

if (prompt -s_, "Enter line 1") {
    is $_, 'c'  => 'First character retrieved';
}
else {
    fail 'First line retrieved'; 
}

