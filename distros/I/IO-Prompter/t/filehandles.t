use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

open my $in_fh, '<', \<<END_INPUT or die $!;
Line 1
Line 2
END_INPUT

my $output = q{};
open my $out_fh, '>', \$output or die $!;

if (prompt "Enter line 1", -in=>$in_fh, -out=>$out_fh) {
    is $_, 'Line 1'  => 'First line retrieved';
    is $output, q{}  => 'No prompt';
}
else {
    fail 'First line retrieved'; 
}

$output = q{};
$out_fh = undef;
open $out_fh, '>', \$output or die $!;

$_ = 'UNDERBAR';
if (my $input = prompt "Enter line 2", -in=>$in_fh, -out=>$out_fh) {
    is $input, 'Line 2'   => 'Second line retrieved';
    is $output, q{}  => 'No prompt';
    is $_,     'UNDERBAR' => 'Second line left $_ alone'
}
else {
    fail 'Second line retrieved'; 
}

