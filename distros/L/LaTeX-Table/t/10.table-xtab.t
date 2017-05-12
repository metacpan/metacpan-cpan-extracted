use Test::More tests => 6;
use Test::NoWarnings;

use LaTeX::Table;

my $test_header =  [ ['Name','Beers:2c'], ['','before 4pm', 'after 4pm'] ];
my $test_data   =  [ 
						['Lisa','0','0'], 
						[ 'Marge','0','1'], 
						[ 'Wiggum','0','5'],
						[ 'Otto','1','3'],
						[ 'Homer','2','6'],
						[ 'Barney','8','16'],
				];

my $table = LaTeX::Table->new({ filename => 'out.tex',
							    label    => 'beercounter',
								maincaption => 'Beer Counter',
								caption   => 'Number of beers before and after 4pm.',
                                header    => $test_header,
                                data      => $test_data,
                                type      => 'xtab',
                                theme             => 'Dresden',
                             });

my $expected_output =<<'EOT'
{
\bottomcaption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}

\tablehead{\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
}
\tabletail{\hline
\hline
\multicolumn{3}{|r|}{{Continued on next page}} \\
\hline
}
\tablelasttail{}
\begin{center}
\begin{xtabular}{|l||r|r|}
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{xtabular}
\end{center}
} 
EOT
;

my $output = $table->generate_string();
#warn $output;
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 'without table environment');

$table->set_tabletail(q{ });

$expected_output =<<'EOT'
{
\bottomcaption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}

\tablehead{\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
}
\tabletail{ \hline
}
\tablelasttail{}
\begin{center}
\begin{xtabular}{|l||r|r|}
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{xtabular}
\end{center}
} 
EOT
;

$output = $table->generate_string();

is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'without table environment, custom tabletail') || diag $output;

$table->set_caption_top(1);
$table->set_center(0);

$expected_output =<<'EOT'
{
\topcaption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}

\tablefirsthead{\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
}
\tablehead{\multicolumn{3}{c}{{ \normalsize \tablename\ \thetable: Continued from previous page}}\\[\abovecaptionskip]
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
}
\tabletail{ \hline
}
\tablelasttail{}
\begin{xtabular}{|l||r|r|}
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{xtabular}

} 
EOT
;

$output = $table->generate_string();

is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'without table environment, topcaption custom tabletail') || diag $output;

$table->set_caption_top('topcaption');

$expected_output =<<'EOT'
{
\topcaption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}

\tablefirsthead{\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
}
\tablehead{\multicolumn{3}{c}{{ \normalsize \tablename\ \thetable: Continued from previous page}}\\[\abovecaptionskip]
\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
}
\tabletail{ \hline
}
\tablelasttail{}
\begin{xtabular}{|l||r|r|}
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{xtabular}

} 
EOT
;

$output = $table->generate_string();

is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'without table environment, topcaption custom tabletail');


$table->set_tableheadmsg(0);
$table->set_custom_tabular_environment('mpxtabular');

$expected_output =<<'EOT'
{
\topcaption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}

\tablehead{\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{c|}{\textbf{Beers}}      \\
\multicolumn{1}{|c||}{\textbf{}}     & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}} \\
\hline
\hline
}
\tabletail{ \hline
}
\tablelasttail{}
\begin{mpxtabular}{|l||r|r|}
Lisa   & 0 & 0  \\
Marge  & 0 & 1  \\
Wiggum & 0 & 5  \\
Otto   & 1 & 3  \\
Homer  & 2 & 6  \\
Barney & 8 & 16 \\
\hline
\end{mpxtabular}

} 
EOT
;

$output = $table->generate_string();

is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'without table environment, topcaption custom tabletail');

