use Test::More tests => 7;
use Test::NoWarnings;

use strict;
use warnings;

use LaTeX::Table;
use English qw( -no_match_vars );

my $header = [ [ 'A', 'B', 'C', ], ];
my $data = [
    [ '123.45678', '   12345678901234567890', '12345', ],
    [ '123.45',    ' A ',           '12345', ],
];

my $table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
    }
);

my $output = $table->generate_string();

my $expected_output = <<'EOT';
\begin{table}
\centering
\begin{tabular}{llr}
\toprule
A & B & C \\
\midrule
123.45678 & 12345678901234567890 & 12345 \\
123.45    & A                    & 12345 \\
\bottomrule
\end{tabular}
\end{table}
EOT

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'three number columns'
);

  $table->set_coldef_strategy({
    NUMBER   => qr{\A \s* \d+ \s* \z}xms, # integers only
    LONG_COL => '>{\raggedright\arraybackslash}p{7cm}', # non-justified
  });

$output = $table->generate_string();

$expected_output = <<'EOT';
\begin{table}
\centering
\begin{tabular}{llr}
\toprule
A & B & C \\
\midrule
123.45678 & 12345678901234567890 & 12345 \\
123.45    & A                    & 12345 \\
\bottomrule
\end{tabular}
\end{table}
EOT

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'three number columns'
);

  $table->set_coldef_strategy({
    NUMBER   => qr{\A \s* \d+ \s* \z}xms, # integers only
    NUMBER_MUST_MATCH_ALL => 0,
    LONG_COL => '>{\raggedright\arraybackslash}p{7cm}', # non-justified
  });


$output = $table->generate_string();

$expected_output = <<'EOT';
\begin{table}
\centering
\begin{tabular}{lrr}
\toprule
A & B & C \\
\midrule
123.45678 & 12345678901234567890 & 12345 \\
123.45    & A                    & 12345 \\
\bottomrule
\end{tabular}
\end{table}
EOT

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'three number columns'
);

$data = [
    [ '123.45678', '   12345678901123456789011234567890  ', '12345', ],
    [ '123.45',    ' 1234567898 ',           '12345', ],
];
$table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
    }
);

$table->set_coldef_strategy({
NUMBER   => qr{\A \s* \d+ \s* \z}xms, # integers only
LONG_COL => '>{\raggedright\arraybackslash}p{7cm}', # non-justified
});


$output = $table->generate_string();

$expected_output = <<'EOT';
\begin{table}
\centering
\begin{tabular}{lrr}
\toprule
A & B & C \\
\midrule
123.45678 & 12345678901123456789011234567890 & 12345 \\
123.45    & 1234567898                       & 12345 \\
\bottomrule
\end{tabular}
\end{table}
EOT

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'LONG NUMBER Is NUMBER'
);

# not a number anymore
$table->set_data([
    [ '123.45678', '   1234567890 1234567890 1234567890', '12345', ],
    [ '123.45',    ' 1234567898.122 ',           '12345', ],
]);

$output = $table->generate_string();

$expected_output = <<'EOT';
\begin{table}
\centering
\begin{tabular}{l>{\raggedright\arraybackslash}p{7cm}r}
\toprule
A & B & C \\
\midrule
123.45678 & 1234567890 1234567890 1234567890 & 12345 \\
123.45    & 1234567898.122                   & 12345 \\
\bottomrule
\end{tabular}
\end{table}
EOT

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'LONG Is LONG'
);

$table->set_coldef_strategy({
URL   => qr{\A \s* http }xms,
URL_COL => 'U', # centered
});

$table->set_data([
    [ '123.45678', '   http://www.google.com', '12345', ],
    [ '123.45',    ' http://www.slashdot.org ',           '12345', ],
]);

$output = $table->generate_string();

$expected_output = <<'EOT';
\begin{table}
\centering
\begin{tabular}{lUr}
\toprule
A & B & C \\
\midrule
123.45678 & http://www.google.com   & 12345 \\
123.45    & http://www.slashdot.org & 12345 \\
\bottomrule
\end{tabular}
\end{table}
EOT

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'new column type'
);

