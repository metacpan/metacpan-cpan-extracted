use Test::More tests => 10;
use Test::NoWarnings;

use LaTeX::Table;

my $table = LaTeX::Table->new({ filename => 'out.tex',
							    label    => 'beercounter',
								maincaption => 'Beer Counter',
								caption   => 'Number of beers before and after 4pm.',
                                theme             => 'Zurich',
                             });

my $test_def = 'test:1c';

is($table->_add_mc_def({ value => $test_def, align => 'r', cols => 2}), $test_def, 'no adding if already has a def');							 
is($table->_add_mc_def({ value => 'test', align => 'r', cols => 2}), 'test:2r', 'no adding if already has a def');							 
is_deeply($table->_get_mc_def('test'), { value => 'test' }, 'get without def');
is_deeply($table->_get_mc_def('test:2c'), { value => 'test', align => 'c', cols => 2 }, 'get with def');
is_deeply($table->_get_mc_def('test:12l'), { value => 'test', align => 'l', cols => 12 }, 'get with def');

is_deeply($table->_add_font_family('test:2r', 'bf'), '\\textbf{test}:2r', 'add bold fonts');							 
is($table->_extract_number_columns('test:2c'), 2, 'columwidth correct');
is($table->_extract_number_columns('test:2'), 1, 'columwidth correct');


my $header = [ [ 'A:3c'], ['A:2c', 'B'], ['A', 'B', 'C'], ];
my $data   = [ [ 'D:3c'], ['D:2c', '1.2'], ['D', 'E', '1.3'], ];

$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        theme    => 'Zurich',
    }
);

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{llr}
\toprule
\multicolumn{3}{c}{\textbf{A}} \\
\multicolumn{2}{c}{\textbf{A}} & \multicolumn{1}{c}{\textbf{B}} \\
\textbf{A}                     & \multicolumn{1}{c}{\textbf{B}} & \multicolumn{1}{c}{\textbf{C}} \\
\midrule
\multicolumn{3}{c}{D} \\
\multicolumn{2}{c}{D} & 1.2 \\
D                     & E   & 1.3 \\
\bottomrule
\end{tabular}
\end{table}

EOT
    ;

my $output = $table->generate_string;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'is_number works with complicated shortcutted headers and data',
);
