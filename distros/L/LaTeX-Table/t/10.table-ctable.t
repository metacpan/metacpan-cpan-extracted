use Test::More tests => 7;
use Test::NoWarnings;

use LaTeX::Table;

my $test_header =  [ ['Name','Beers:2c'], ['','before 4pm', 'after 4pm'] ];
my $test_data   =  [ 
						['Lisa\tmark','0','0'], 
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
                                type      => 'ctable',
                                theme             => 'Zurich',
                             });

$table->set_foottable('\tnote{footnotes are placed under the table}');

my $expected_output =<<'EOT'
{
\ctable[caption = {Beer Counter. Number of beers before and after 4pm.},
cap = {Beer Counter},
botcap,
label = {beercounter},
center,
]{lrr}{\tnote{footnotes are placed under the table}}{
\toprule
\textbf{Name} & \multicolumn{2}{c}{\textbf{Beers}}      \\
              & \multicolumn{1}{c}{\textbf{before 4pm}} & \multicolumn{1}{c}{\textbf{after 4pm}} \\
\midrule
Lisa\tmark & 0 & 0  \\
Marge      & 0 & 1  \\
Wiggum     & 0 & 5  \\
Otto       & 1 & 3  \\
Homer      & 2 & 6  \\
Barney     & 8 & 16 \\
\bottomrule
}
}
EOT
;

my $output = $table->generate_string();
#warn $output;
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 'without table environment');


$table->set_maincaption(0);
$table->set_shortcaption('Beer Counter');

$expected_output =<<'EOT'
{
\ctable[caption = {Number of beers before and after 4pm.},
cap = {Beer Counter},
botcap,
label = {beercounter},
center,
]{lrr}{\tnote{footnotes are placed under the table}}{
\toprule
\textbf{Name} & \multicolumn{2}{c}{\textbf{Beers}}      \\
              & \multicolumn{1}{c}{\textbf{before 4pm}} & \multicolumn{1}{c}{\textbf{after 4pm}} \\
\midrule
Lisa\tmark & 0 & 0  \\
Marge      & 0 & 1  \\
Wiggum     & 0 & 5  \\
Otto       & 1 & 3  \\
Homer      & 2 & 6  \\
Barney     & 8 & 16 \\
\bottomrule
}
}
EOT
;

$output = $table->generate_string();
#warn $output;
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 'without table environment');

$table->set_right(1);
$table->set_shortcaption(0);
$table->set_caption_top(1);

$expected_output =<<'EOT'
{
\ctable[caption = {Number of beers before and after 4pm.},
label = {beercounter},
right,
]{lrr}{\tnote{footnotes are placed under the table}}{
\toprule
\textbf{Name} & \multicolumn{2}{c}{\textbf{Beers}}      \\
              & \multicolumn{1}{c}{\textbf{before 4pm}} & \multicolumn{1}{c}{\textbf{after 4pm}} \\
\midrule
Lisa\tmark & 0 & 0  \\
Marge      & 0 & 1  \\
Wiggum     & 0 & 5  \\
Otto       & 1 & 3  \\
Homer      & 2 & 6  \\
Barney     & 8 & 16 \\
\bottomrule
}
}
EOT
;

$output = $table->generate_string();
#warn $output;
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 'without table environment');

$test_data   =  [ 
						['Lisa\tmark','0','0'], 
						[ 'Marge','0','1'], 
						[ 'Wiggum','0','5'],
						[ 'Otto','1','3'],
						[ 'Homer','This is a looooooooooooooooong longgg linee, my friedn','6'],
						[ 'Barney','8','16'],
				];

$table->set_data($test_data);
$table->set_maxwidth('0.9\textwidth');

$expected_output =<<'EOT'
{
\ctable[caption = {Number of beers before and after 4pm.},
label = {beercounter},
maxwidth = {0.9\textwidth},
right,
]{lXr}{\tnote{footnotes are placed under the table}}{
\toprule
\textbf{Name} & \multicolumn{2}{c}{\textbf{Beers}}      \\
              & \multicolumn{1}{c}{\textbf{before 4pm}} & \multicolumn{1}{c}{\textbf{after 4pm}} \\
\midrule
Lisa\tmark & 0                                                      & 0  \\
Marge      & 0                                                      & 1  \\
Wiggum     & 0                                                      & 5  \\
Otto       & 1                                                      & 3  \\
Homer      & This is a looooooooooooooooong longgg linee, my friedn & 6  \\
Barney     & 8                                                      & 16 \\
\bottomrule
}
}
EOT
;

$output = $table->generate_string();
#warn $output;
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'uses xtabular?');


$table = LaTeX::Table->new(
    {   
        type    => 'ctable',
        header  => [ [ 'Website', 'URL' ] ],
        data    => [
            [ 'Slashdot',  'http://www.slashdot.org' ],
            [ 'Perlmonks', '  http://www.perlmonks.org' ],
            [ 'Google',    'http://www.google.com' ],
        ],
        coldef_strategy => {
            URL     => qr{ \A \s* http }xms,
            URL_COL => '>{\ttfamily}l',
        },
        theme    => 'Zurich',
    }
);

$table->set_eor('\\\\%');

$expected_output =<<'EOT'
{
\ctable[center,
]{l>{\ttfamily}l}{}{
\toprule
\textbf{Website} & \multicolumn{1}{c}{\textbf{URL}} \\%
\midrule
Slashdot  & http://www.slashdot.org  \\%
Perlmonks & http://www.perlmonks.org \\%
Google    & http://www.google.com    \\%
\bottomrule
}
}
EOT
;

$output = $table->generate_string();
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'uses _COL_X not specified');

$table->set_continued(1);
$table->set_eor('\\\\');

$expected_output =<<'EOT'
{
\ctable[center,
continued = {(continued)},
]{l>{\ttfamily}l}{}{
\toprule
\textbf{Website} & \multicolumn{1}{c}{\textbf{URL}} \\
\midrule
Slashdot  & http://www.slashdot.org  \\
Perlmonks & http://www.perlmonks.org \\
Google    & http://www.google.com    \\
\bottomrule
}
}
EOT
;

$output = $table->generate_string();
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'continued');

