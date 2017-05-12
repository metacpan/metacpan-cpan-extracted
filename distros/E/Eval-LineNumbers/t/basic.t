use strict;
use warnings;
use Test::More tests => 4;

use Eval::LineNumbers 'eval_line_numbers';


my $line_expected = __LINE__ + 3;
my ($line, $file) = eval eval_line_numbers <<'EOF';

(__LINE__, __FILE__)

EOF

is($file, __FILE__, 'file matches');
is($line, $line_expected, 'line number matches');


sub evaluator
{
    eval eval_line_numbers(@_)
}

$line_expected = __LINE__ + 3;
($line, $file) = evaluator(1, <<'EOF');

(__LINE__, __FILE__)

EOF

is($file, __FILE__, 'file matches with call level 1');
is($line, $line_expected, 'line number matches with call level 1');
