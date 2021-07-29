use strict;
use warnings;
use Test::More tests => 4;

use Eval::LineNumbers qw( eval_line_numbers eval_line_numbers_offset );


eval_line_numbers_offset 0;

my $line_expected = __LINE__ + 3;
my ($line, $file) = eval eval_line_numbers q{

  (__LINE__, __FILE__)

};

is($file, __FILE__, 'file matches');
is($line, $line_expected, 'line number matches');


sub evaluator
{
    eval eval_line_numbers(@_)
}

$line_expected = __LINE__ + 3;
($line, $file) = evaluator(1, q{

(__LINE__, __FILE__)

});

is($file, __FILE__, 'file matches with call level 1');
is($line, $line_expected, 'line number matches with call level 1');
