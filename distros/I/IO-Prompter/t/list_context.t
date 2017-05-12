use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Line 1
Line 2
END_INPUT

if (my ($input) = prompt "Enter line 1") {
    is $input, 'Line 1'  => 'First line retrieved';
}
else {
    fail 'First line retrieved'; 
}

$_ = 'UNDERBAR';
if (my ($input) = prompt "Enter line 2") {
    is $input, 'Line 2'   => 'Second line retrieved';
    is $_,     'UNDERBAR' => 'Second line left $_ alone'
}
else {
    fail 'Second line retrieved'; 
}

if (my @input = prompt "Enter line 3") {
    fail "empty list on failure (unexpectedly got qw<@input>)"; 
}
else {
    ok !@input  => 'empty list on failure';
}

{
    open my $fh, '<', \q{} or die $!;
    my @inputs = (
        prompt('test', -in=>$fh),
        prompt('test', -in=>$fh),
        prompt('test', -in=>$fh),
    );
    ok @inputs == 0, 'Correct number of inputs on failure';
}

{
    open my $fh, '<', \q{} or die $!;
    my @inputs = (
        scalar prompt('test', -in=>$fh),
        scalar prompt('test', -in=>$fh),
        scalar prompt('test', -in=>$fh),
    );
    ok @inputs == 3, 'Correct number of scalar inputs on failure';
}
