use Test::More tests => 21;
use Test::NoWarnings;

use LaTeX::Table;

my $test_header
    = [ [ 'Name', 'Beers:2c' ], [ '', 'before 4pm', 'after 4pm' ] ];
my $test_data = [
    [ 'Lisa',   '0', '0' ],
    [ 'Marge',  '0', '1' ],
    [ 'Wiggum', '0', '5' ],
    [ 'Otto',   '1', '3' ],
    [ 'Homer',  '2', '6' ],
    [ 'Barney', '8', '16' ],
];

my $table = LaTeX::Table->new(
    {   filename          => 't/tmp/out.tex',
        label             => 'beercounter',
        maincaption       => 'Beer Counter',
        caption           => 'Number of beers before and after 4pm.',
        environment       => 0,
        theme             => 'Dresden',
        header            => $test_header,
        data              => $test_data,
    }
);

my $expected_output = <<'EOT'
\begin{tabular}{|l||r|r|}
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{tabular}
EOT
    ;

my $output = $table->generate_string();
my @expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'without table environment'
);

mkdir 't/tmp';
$table->generate();

open my $FH, '<', 't/tmp/out.tex';
my @filecontent = <$FH>;
chomp @filecontent;
close $FH;

is_deeply( \@filecontent, [@expected_output],
    'without table environment, generate()' )
    or diag join("\n",@filecontent);

unlink 't/tmp/out.tex';
rmdir 't/tmp';
## with table environment
$table->set_environment(1);

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{|l||r|r|}
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{tabular}
\caption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}
\end{table}
EOT
    ;
$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment'
);

$table->set_continued(1);
$expected_output = <<'EOT'
\addtocounter{table}{-1}\begin{table}
\centering
\begin{tabular}{|l||r|r|}
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{tabular}
\caption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm. (continued)}
\label{beercounter}
\end{table}
EOT
    ;
$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment'
);

$table->set_continued(0);
# without label and maincaption
$table->set_environment(1);
$table->set_label('');
$table->set_maincaption('');

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{|l||r|r|}
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{tabular}
\caption{Number of beers before and after 4pm.}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment, without maincaption and label'
);

## without center

$table = LaTeX::Table->new(
    {   environment       => 1,
        center            => 0,
        theme             => 'Dresden',
        header            => $test_header,
        data              => $test_data,
    }
);
$expected_output = <<'EOT'
\begin{table}
\begin{tabular}{|l||r|r|}
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{tabular}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment, without maincaption, center and label'
);

$table = LaTeX::Table->new(
    {   environment       => 1,
        center            => 0,
        caption_top       => 1,
        caption           => 'test caption',
        header            => $test_header,
        data              => $test_data,
        theme             => 'Zurich',
    }
);

$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\caption{test caption}
\begin{tabular}{lrr}
\toprule
\textbf{Name} & \multicolumn{2}{c}{\textbf{Beers}}      \\
              & \multicolumn{1}{c}{\textbf{before 4pm}} & \multicolumn{1}{c}{\textbf{after 4pm}} \\
\midrule
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\bottomrule
\end{tabular}
\end{table}
EOT
  ;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment, without maincaption, center and label'
);

$table->set_caption_top('topcaption');
$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\topcaption{test caption}
\begin{tabular}{lrr}
\toprule
\textbf{Name} & \multicolumn{2}{c}{\textbf{Beers}}      \\
              & \multicolumn{1}{c}{\textbf{before 4pm}} & \multicolumn{1}{c}{\textbf{after 4pm}} \\
\midrule
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\bottomrule
\end{tabular}
\end{table}
EOT
  ;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment, without maincaption, center and label'
);

## with coldef
$table = LaTeX::Table->new(
    {   environment => 0,
        coldef          => "|l||l|l|",
        header            => $test_header,
        data              => $test_data,
        theme             => 'Dresden',
    }
);
$expected_output = <<'EOT'
\begin{tabular}{|l||l|l|}
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{tabular}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with coldef'
);

$test_data = [
    [ 'Lisa',   '0', '0' ],
    [ 'Marge',  '0', '1' ],
    [ 'Wiggum', '0', '' ],
    [ 'Otto',   '  ', '' ],
    [ 'Homer',  '2', '6' ],
    [ 'Barney', '8', '16' ],
];

$table = LaTeX::Table->new(
    {   environment => 0,
        header            => $test_header,
        data              => $test_data,
    }
);

$expected_output = <<'EOT'
\begin{tabular}{lrr}
\toprule
Name & \multicolumn{2}{c}{Beers} \\
     & before 4pm                & after 4pm \\
\midrule
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 &    \\
Otto   &   &    \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\bottomrule
\end{tabular}
EOT
;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'missing values'
) || diag $output;

my $header = [ [ 'Character', 'Fullname', 'Voice' ], ];
my $data = [
    [ 'Homer', 'Homer Jay Simpson',               'Dan Castellaneta', ],
    [],
    [ 'Marge', 'Marjorie Simpson (nee Bouvier)', 'Julie Kavner', ],
    [ 'Bart',  'Bartholomew Jojo Simpson',        'Nancy Cartwright', ],
    [ 'Lisa',  'Elizabeth Marie Simpson',         'Yeardley Smith', ],
    [   'Maggie',
        'Margaret Simpson',
        'Elizabeth Taylor, Nancy Cartwright, James Earl Jones,'
            . 'Yeardley Smith, Harry Shearer',
    ],
];

#no header test
$table = LaTeX::Table->new(
    {   data              => $data,
        width             => '0.9\textwidth',
        width_environment => 'tabularx',
        position          => 'ht',
        theme             => 'Zurich',
    }
);
$expected_output = <<'EOT'
\begin{table}[ht]
\centering
\begin{tabularx}{0.9\textwidth}{lXX}
\toprule
Homer  & Homer Jay Simpson              & Dan Castellaneta                                                                   \\
\midrule
Marge  & Marjorie Simpson (nee Bouvier) & Julie Kavner                                                                       \\
Bart   & Bartholomew Jojo Simpson       & Nancy Cartwright                                                                   \\
Lisa   & Elizabeth Marie Simpson        & Yeardley Smith                                                                     \\
Maggie & Margaret Simpson               & Elizabeth Taylor, Nancy Cartwright, James Earl Jones,Yeardley Smith, Harry Shearer \\
\bottomrule
\end{tabularx}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'no header'
);

$table->set_width_environment('tabulary');
$expected_output = <<'EOT'
\begin{table}[ht]
\centering
\begin{tabulary}{0.9\textwidth}{lLL}
\toprule
Homer  & Homer Jay Simpson              & Dan Castellaneta                                                                   \\
\midrule
Marge  & Marjorie Simpson (nee Bouvier) & Julie Kavner                                                                       \\
Bart   & Bartholomew Jojo Simpson       & Nancy Cartwright                                                                   \\
Lisa   & Elizabeth Marie Simpson        & Yeardley Smith                                                                     \\
Maggie & Margaret Simpson               & Elizabeth Taylor, Nancy Cartwright, James Earl Jones,Yeardley Smith, Harry Shearer \\
\bottomrule
\end{tabulary}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'tabulary'
);


## tabularx test
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        width             => '0.9\textwidth',
        width_environment => 'tabularx',
        position          => 'ht',
        theme             => 'Zurich',
    }
);

$expected_output = <<'EOT'
\begin{table}[ht]
\centering
\begin{tabularx}{0.9\textwidth}{lXX}
\toprule
\textbf{Character} & \multicolumn{1}{c}{\textbf{Fullname}} & \multicolumn{1}{c}{\textbf{Voice}} \\
\midrule
Homer  & Homer Jay Simpson              & Dan Castellaneta                                                                   \\
\midrule
Marge  & Marjorie Simpson (nee Bouvier) & Julie Kavner                                                                       \\
Bart   & Bartholomew Jojo Simpson       & Nancy Cartwright                                                                   \\
Lisa   & Elizabeth Marie Simpson        & Yeardley Smith                                                                     \\
Maggie & Margaret Simpson               & Elizabeth Taylor, Nancy Cartwright, James Earl Jones,Yeardley Smith, Harry Shearer \\
\bottomrule
\end{tabularx}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with coldef'
);

## fontsize test
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        fontsize          => 'Huge',
        fontfamily        => 'sf',
        position          => 'ht',
    }
);

$expected_output = <<'EOT'
\begin{table}[ht]
\Huge
\sffamily
\centering
\begin{tabular}{lp{5cm}p{5cm}}
\toprule
Character & Fullname & Voice \\
\midrule
Homer  & Homer Jay Simpson              & Dan Castellaneta                                                                   \\
\midrule
Marge  & Marjorie Simpson (nee Bouvier) & Julie Kavner                                                                       \\
Bart   & Bartholomew Jojo Simpson       & Nancy Cartwright                                                                   \\
Lisa   & Elizabeth Marie Simpson        & Yeardley Smith                                                                     \\
Maggie & Margaret Simpson               & Elizabeth Taylor, Nancy Cartwright, James Earl Jones,Yeardley Smith, Harry Shearer \\
\bottomrule
\end{tabular}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'fontsize'
) || diag $output;


## fontsize test
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        position          => 'ht',
        width             => '0.9\textwidth',
        width_environment => 'tabular*',
        theme             => 'Zurich',
    }
);

$expected_output = <<'EOT'
\begin{table}[ht]
\centering
\begin{tabular*}{0.9\textwidth}{l@{\extracolsep{\fill}}p{5cm}p{5cm}}
\toprule
\textbf{Character} & \multicolumn{1}{c}{\textbf{Fullname}} & \multicolumn{1}{c}{\textbf{Voice}} \\
\midrule
Homer  & Homer Jay Simpson              & Dan Castellaneta                                                                   \\
\midrule
Marge  & Marjorie Simpson (nee Bouvier) & Julie Kavner                                                                       \\
Bart   & Bartholomew Jojo Simpson       & Nancy Cartwright                                                                   \\
Lisa   & Elizabeth Marie Simpson        & Yeardley Smith                                                                     \\
Maggie & Margaret Simpson               & Elizabeth Taylor, Nancy Cartwright, James Earl Jones,Yeardley Smith, Harry Shearer \\
\bottomrule
\end{tabular*}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with coldef'
);

$test_header = [ [ 'A:3c' ] , [ 'A:2c', 'B' ], ['A', 'B', 'C' ], ];
$test_data = [ [ '1', 'w', 'x' ], [ '2', 'c:2c' ], ];

$table = LaTeX::Table->new(
    {   environment       => 0,
        header            => $test_header,
        data              => $test_data,
        theme             => 'Dresden',
    }
);

$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{tabular}{|r||l|l|}
\hline
\multicolumn{3}{|c|}{\textbf{A}}  \\
\multicolumn{2}{|c|}{\textbf{A}}  & \multicolumn{1}{c|}{\textbf{B}} \\
\multicolumn{1}{|c||}{\textbf{A}} & \multicolumn{1}{c|}{\textbf{B}} & \multicolumn{1}{c|}{\textbf{C}} \\
\hline
\hline
1 & w                      & x \\
2 & \multicolumn{2}{c|}{c} \\
\hline
\end{tabular}
EOT
    ;


$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with very complicated multicolum shortcuts'
);

$table->set_theme('NYC');

$expected_output = <<'EOT'
\definecolor{latextbl}{RGB}{78,130,190}
\setlength{\extrarowheight}{1pt}
\begin{tabular}{|rll|}
\hline
\rowcolor{latextbl}\multicolumn{3}{|>{\columncolor{latextbl}}c|}{\color{white}\textbf{A}} \\
\rowcolor{latextbl}\multicolumn{2}{|>{\columncolor{latextbl}}c}{\color{white}\textbf{A}}  & \multicolumn{1}{>{\columncolor{latextbl}}c|}{\color{white}\textbf{B}} \\
\rowcolor{latextbl}\multicolumn{1}{|>{\columncolor{latextbl}}c}{\color{white}\textbf{A}}  & \multicolumn{1}{>{\columncolor{latextbl}}c}{\color{white}\textbf{B}}  & \multicolumn{1}{>{\columncolor{latextbl}}c|}{\color{white}\textbf{C}} \\
\hline
\rowcolor{latextbl!25}1 & w                                                  & x \\
\rowcolor{latextbl!10}2 & \multicolumn{2}{>{\columncolor{latextbl!10}}c|}{c} \\
\hline
\end{tabular}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'theme with colordef'
);

$table->set_resizebox(['0.6\textwidth']);


$expected_output = <<'EOT'
\definecolor{latextbl}{RGB}{78,130,190}
\setlength{\extrarowheight}{1pt}
\resizebox{0.6\textwidth}{!}{
\begin{tabular}{|rll|}
\hline
\rowcolor{latextbl}\multicolumn{3}{|>{\columncolor{latextbl}}c|}{\color{white}\textbf{A}} \\
\rowcolor{latextbl}\multicolumn{2}{|>{\columncolor{latextbl}}c}{\color{white}\textbf{A}}  & \multicolumn{1}{>{\columncolor{latextbl}}c|}{\color{white}\textbf{B}} \\
\rowcolor{latextbl}\multicolumn{1}{|>{\columncolor{latextbl}}c}{\color{white}\textbf{A}}  & \multicolumn{1}{>{\columncolor{latextbl}}c}{\color{white}\textbf{B}}  & \multicolumn{1}{>{\columncolor{latextbl}}c|}{\color{white}\textbf{C}} \\
\hline
\rowcolor{latextbl!25}1 & w                                                  & x \\
\rowcolor{latextbl!10}2 & \multicolumn{2}{>{\columncolor{latextbl!10}}c|}{c} \\
\hline
\end{tabular}}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'theme with colordef and resizebox'
);

$table->set_resizebox(['300pt', '200pt']);
$expected_output = <<'EOT'
\definecolor{latextbl}{RGB}{78,130,190}
\setlength{\extrarowheight}{1pt}
\resizebox{300pt}{200pt}{
\begin{tabular}{|rll|}
\hline
\rowcolor{latextbl}\multicolumn{3}{|>{\columncolor{latextbl}}c|}{\color{white}\textbf{A}} \\
\rowcolor{latextbl}\multicolumn{2}{|>{\columncolor{latextbl}}c}{\color{white}\textbf{A}}  & \multicolumn{1}{>{\columncolor{latextbl}}c|}{\color{white}\textbf{B}} \\
\rowcolor{latextbl}\multicolumn{1}{|>{\columncolor{latextbl}}c}{\color{white}\textbf{A}}  & \multicolumn{1}{>{\columncolor{latextbl}}c}{\color{white}\textbf{B}}  & \multicolumn{1}{>{\columncolor{latextbl}}c|}{\color{white}\textbf{C}} \\
\hline
\rowcolor{latextbl!25}1 & w                                                  & x \\
\rowcolor{latextbl!10}2 & \multicolumn{2}{>{\columncolor{latextbl!10}}c|}{c} \\
\hline
\end{tabular}}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'theme with colordef and resizebox'
);

$test_data = [ [ '1', 'w', 'x' ],['\hline' ], [ '2', 'c:2c' ], ];

$table = LaTeX::Table->new(
    { 
        data                => $test_data,
        theme               => 'NYC',
        columns_like_header => [ 0 ],
    }
);

$expected_output = <<'EOT'
\definecolor{latextbl}{RGB}{78,130,190}
\begin{table}
\centering
\setlength{\extrarowheight}{1pt}
\begin{tabular}{|rll|}
\hline
\rowcolor{latextbl!25}\multicolumn{1}{|>{\columncolor{latextbl}}r}{\color{white}\textbf{1}} & w                                                  & x \\
\hline
\rowcolor{latextbl!10}\multicolumn{1}{|>{\columncolor{latextbl}}r}{\color{white}\textbf{2}} & \multicolumn{2}{>{\columncolor{latextbl!10}}c|}{c} \\
\hline
\end{tabular}
\end{table}
EOT
    ;


$output = $table->generate_string();

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'theme with colordef and resizebox'
) || diag $output;


