use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

my @expected = (
    'arg1',
    'arg 2',
    'arg 3',
    4,
    5,
);

my $argv_source = q{ arg1 'arg 2'  "arg 3"  "4"  5  };
open my $fh, '<', \$argv_source;

$_ = 'UNDERBAR';
if (prompt -argv, -in=>$fh, 'ARGV: ') {
    is_deeply \@ARGV, \@expected => '@ARGV set'; 
    is $_, 'UNDERBAR'            => 'Left $_ alone'
}
else {
    fail '@ARGV set'; 
}

