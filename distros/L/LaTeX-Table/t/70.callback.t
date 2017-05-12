use Test::More tests => 5;
use Test::NoWarnings;

use LaTeX::Table;

my $header = [ [ 'A', 'B', 'C' ], [ 'a', 'b', 'c' ] ];
my $data = [
    [ 'Marge', 'Homer', 'Bart' ],
    [ 'Marge', 'Homer', 'Bart' ],
    [ 'Marge', 'Homer', 'Bart' ],
];

my $table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        theme    => 'Dresden',
        callback => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $row == 1 && !$is_header ) {
                return lc $value;
            }
            if ( $row == 0 && $is_header ) {
                return lc $value;
            }
            if ( ( $row + $col ) % 2 == 0 ) {
                return uc $value;
            }
            return 'foo';
        },
    }
);
my $expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{|l||l|l|}
\hline
\multicolumn{1}{|c||}{\textbf{a}}   & \multicolumn{1}{c|}{\textbf{b}} & \multicolumn{1}{c|}{\textbf{c}}   \\
\multicolumn{1}{|c||}{\textbf{foo}} & \multicolumn{1}{c|}{\textbf{B}} & \multicolumn{1}{c|}{\textbf{foo}} \\
\hline
\hline
MARGE & foo   & BART \\
marge & homer & bart \\
MARGE & foo   & BART \\
\hline
\end{tabular}
\end{table}
EOT
    ;
my $output = $table->generate_string;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'callback seems to work with words',
) || diag $output;

$header = [ [ 'A:2c', 'C' ], [ 'a', 'b', 'c' ] ];
$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        callback => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ($is_header) {
                return uc $value;
            }
        },
        theme => 'Zurich',
    }
);

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{lll}
\toprule
\multicolumn{2}{c}{\textbf{A}} & \multicolumn{1}{c}{\textbf{C}} \\
\textbf{A}                     & \multicolumn{1}{c}{\textbf{B}} & \multicolumn{1}{c}{\textbf{C}} \\
\midrule
0 & 0 & 0 \\
0 & 0 & 0 \\
0 & 0 & 0 \\
\bottomrule
\end{tabular}
\end{table}

EOT
    ;
$output = $table->generate_string;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'callback seems to work with uc headers and shortcuts',
);

$header = [ ['A:3c'], [ 'A:2c', 'B' ], [ 'A', 'B', 'C' ], ];
$data   = [ ['D:3c'], [ 'D:2c', 'E' ], [ 'D', 'E', 'F' ], ];

$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        callback => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $col == 0 ) {
                return 'X' . $value;
            }
            elsif ( $col == 1 ) {
                return 'Y' . $value;
            }
            else {
                return 'Z' . $value;
            }
        },
        theme => 'Zurich',
    }
);

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{lll}
\toprule
\multicolumn{3}{c}{\textbf{XA}} \\
\multicolumn{2}{c}{\textbf{XA}} & \multicolumn{1}{c}{\textbf{ZB}} \\
\textbf{XA}                     & \multicolumn{1}{c}{\textbf{YB}} & \multicolumn{1}{c}{\textbf{ZC}} \\
\midrule
\multicolumn{3}{c}{XD} \\
\multicolumn{2}{c}{XD} & ZE \\
XD                     & YE & ZF \\
\bottomrule
\end{tabular}
\end{table}

EOT
    ;

$output = $table->generate_string;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'callback works with complicated shortcutted headers and data',
);

$header = [ [ 'A', 'B:2c' ], [], [ 'a:2c', 'b' ] ];
$data = [
    [ 'Marge', 'Homer', 'Bart' ],
    [ 'Marge', 'Homer:2c' ],
    [],
    [ 'Marge:2c', 'Homer' ],
];

$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        callback => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            return "$is_header $row $col";
        },
    }
);

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{lll}
\toprule
1 0 0                     & \multicolumn{2}{c}{1 0 1} \\
\midrule
\multicolumn{2}{c}{1 1 0} & 1 1 2                     \\
\midrule
0 0 0                     & 0 0 1                     & 0 0 2 \\
0 1 0                     & \multicolumn{2}{c}{0 1 1} \\
\midrule
\multicolumn{2}{c}{0 2 0} & 0 2 2                     \\
\bottomrule
\end{tabular}
\end{table}
EOT
    ;

$output = $table->generate_string;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'callback works with complicated shortcutted headers and data',
) || diag $output;
