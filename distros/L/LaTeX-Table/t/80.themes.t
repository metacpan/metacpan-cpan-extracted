use Test::More tests => 9;
use Test::NoWarnings;

use lib 't/lib';
use LaTeX::Table;

my $themes = {
    'Leipzig' => {
        'HEADER_FONT_STYLE' => 'sc',
        'HEADER_CENTERED'   => 1,
        'VERTICAL_RULES'    => [ 1, 2, 1 ],
        'HORIZONTAL_RULES'  => [ 1, 2, 0 ],
    },
    'Leipzig2' => {
        'HEADER_CENTERED'   => 1,
        'VERTICAL_RULES'    => [ 1, 2, 1 ],
        'HORIZONTAL_RULES'  => [ 1, 2, 0 ],
    },
    'Leipzig3' => {
        'VERTICAL_RULES'    => [ 1, 2, 1 ],
        'HORIZONTAL_RULES'  => [ 1, 2, 0 ],
    },
    'Leipzig3b' => {
        'HEADER_CENTERED'   => 0,
        'VERTICAL_RULES'    => [ 1, 2, 1 ],
        'HORIZONTAL_RULES'  => [ 1, 2, 0 ],
        'BOOKTABS'          => 0,
    },
};

my $test_header = [ [ 'A', 'B', 'C' ], ];
my $test_data = [ [ '1', 'w', 'x' ], [], [ '2', 'y', 'z' ], ];

my $table = LaTeX::Table->new(
    {   environment       => 'sidewaystable',
        caption           => 'Test Caption',
        maincaption       => 'Test',
        header            => $test_header,
        data              => $test_data,
        custom_themes     => $themes,
        theme             => 'Leipzig',
    }
);

my $expected_output = <<'EOT'
\begin{sidewaystable}
\centering
\begin{tabular}{|r||l|l|}
\hline
\multicolumn{1}{|c||}{\textsc{A}} & \multicolumn{1}{c|}{\textsc{B}} & \multicolumn{1}{c|}{\textsc{C}} \\
\hline
\hline
1 & w & x \\
\hline
2 & y & z \\
\hline
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{sidewaystable}
EOT
    ;

my $output = $table->generate_string();
my @expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'without table environment'
);

$table->set_theme('Leipzig2');
$table->set_environment('table');
$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{|r||l|l|}
\hline
\multicolumn{1}{|c||}{A} & \multicolumn{1}{c|}{B} & \multicolumn{1}{c|}{C} \\
\hline
\hline
1 & w & x \\
\hline
2 & y & z \\
\hline
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{table}
EOT
    ;

@expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'without header font'
);

$table->set_theme('Leipzig3');
$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{|r||l|l|}
\hline
A & B & C \\
\hline
\hline
1 & w & x \\
\hline
2 & y & z \\
\hline
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{table}
EOT
    ;
@expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'theme, without header centered'
);

$table->set_theme('Leipzig3b');
$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'theme, without header centered'
);

$table->set_theme('Zurich');
$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{lll}
\toprule
\textbf{A} & \multicolumn{1}{c}{\textbf{B}} & \multicolumn{1}{c}{\textbf{C}} \\
\midrule
1 & w & x \\
\midrule
2 & y & z \\
\bottomrule
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{table}
EOT
    ;
@expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'standard theme'
);

$table->search_path( add => 'MyThemes' );
$table->set_theme('Erfurt');

$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{lll}
\toprule
\textsc{A} & \multicolumn{1}{c}{\textsc{B}} & \multicolumn{1}{c}{\textsc{C}} \\
\midrule
1 & w & x \\
\midrule
2 & y & z \\
\bottomrule
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{table}
EOT
    ;
@expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'custom search path'
);

is_deeply($table->get_available_themes->{Erfurt}->{RULES_CMD},[ '\toprule',
    '\midrule', '\midrule', '\bottomrule' ], 'BOOKTABS shortcut' );


$test_header = [ [ 'head1', 'head2', 'head3', 'head4' ], ];
$test_data = [ 
    [ 'row1', 'row1', 'row1', 'row1' ],  
    [ 'row2', 'row2', 'row2', 'row2' ],  
    [ 'row3', 'row3', 'row3', 'row3' ],  
    [ 'row4', 'row4', 'row4', 'row4' ],  
];

my $custom_template = << 'EOT'
[%IF CONTINUED %]\addtocounter{table}{-1}[% END %][% COLORDEF_CODE %][% IF
ENVIRONMENT %]\begin{[% ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF POSITION %][[% POSITION %]][% END %][% END %]
\processtable{[% IF CAPTION %][% CAPTION %][% END %][% IF CONTINUED %] [% CONTINUEDMSG %][% END %][% IF LABEL %]\label{[% LABEL %]}[% END %]}
{\begin{[% TABULAR_ENVIRONMENT %]}{[% COLDEF %]}
[% HEADER_CODE %][% DATA_CODE %]\end{[% TABULAR_ENVIRONMENT %]}}{[% FOOTTABLE %]}
[% IF ENVIRONMENT %]\end{table}[% END %]
EOT
;

$table = LaTeX::Table->new(
    {   
        caption           => 'This is table caption',
        label             => 'Tab:01',
        foottable         => 'This is a footnote',
        position          => '!t',
        header            => $test_header,
        data              => $test_data,
        custom_themes     => $themes,
        theme             => 'Oxford',
        custom_template   => $custom_template,
    }
);

$expected_output = <<'EOT'
\begin{table}[!t]
\processtable{This is table caption\label{Tab:01}}
{\begin{tabular}{llll}
\toprule
head1 & head2 & head3 & head4 \\
\midrule
row1 & row1 & row1 & row1 \\
row2 & row2 & row2 & row2 \\
row3 & row3 & row3 & row3 \\
row4 & row4 & row4 & row4 \\
\botrule
\end{tabular}}{This is a footnote}
\end{table}
EOT
;

@expected_output = split "\n", $expected_output;
$output = $table->generate_string();

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'custom search path'
);
