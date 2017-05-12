use Test::More tests => 2;
use Test::NoWarnings;

use LaTeX::Table;

my $cmd = "$^X bin/ltpretty < t/ltpretty.txt";
my $output = `$cmd`;
my $expected_output =<< 'EOT'

 % theme=Meyrin;label=test;position=htb
 % Item:2c & Price
 % Gnat& per gram& 13.65
 % & each& 0.01
 % 
 % Gnu& stuffed& 92.59
 % Emu& stuffed& 33.33
 % Armadillo& frozen& 8.99

\begin{table}[htb]
\centering
\begin{tabular}{llr}
\toprule
\multicolumn{2}{c}{Item} & Price \\
\midrule
Gnat      & per gram & 13.65 \\
          & each     & 0.01  \\
\midrule
Gnu       & stuffed  & 92.59 \\
Emu       & stuffed  & 33.33 \\
Armadillo & frozen   & 8.99  \\
\bottomrule
\end{tabular}
\label{test}
\end{table}

EOT
;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'ltpretty empty lines'
) || diag $output;

