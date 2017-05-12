#!/usr/bin/perl 

use strict;
use warnings;

use LaTeX::Table;
use LaTeX::Encode;
use Number::Format qw(:subs);
use Data::Dumper;
use Text::CSV;

use utf8;

system('rm *.tex');

my $test_data = [
    [ 'Gnat',      'per gram', '13.651' ],
    [ '',          'each',     '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59' ],
    [ 'Emu',       'stuffed',  '33.33' ],
    [ 'Armadillo', 'frozen',   '8.99' ],
];

my $test_data_large = [];

for my $i ( 1 .. 9 ) {
    $test_data_large = [ @$test_data_large, @$test_data ];
}

my $table = LaTeX::Table->new(
    {   maincaption => 'Price List',
        fontsize    => 'large',
        caption     => '',
        callback    => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $col == 2 && !$is_header ) {
                $value = format_price( $value, 2, '' );
            }
            return $value;
        },
    }
);

my $themes = {
    'Custom' => {
        'HEADER_FONT_STYLE'  => 'sc',
        'HEADER_CENTERED'    => 1,
        'CAPTION_FONT_STYLE' => 'sc',
        'VERTICAL_RULES'     => [ 1, 2, 1 ],
        'HORIZONTAL_RULES'   => [ 1, 2, 0 ],
    },
};

$table->set_custom_themes($themes);

foreach my $theme ( keys %{ $table->get_available_themes } ) {

    my $test_header
        = [ [ 'Item:2c', '' ], [ 'Animal', 'Description', 'Price' ] ];

    if ( $theme eq 'Zurich' || $theme eq 'Meyrin' || $theme eq 'Evanston' ) {
        $test_header = [
            [ 'Item:2c', '' ],
            ['\cmidrule(r){1-2}'],
            [ 'Animal', 'Description', 'Price' ]
        ];
    }

    $table->set_maincaption("\\texttt{theme=$theme, type=std}");

    if ($theme eq 'Muenchen') {
        $table->set_fontfamily('sf');
    }
    else {
        $table->set_fontfamily(0);
    }    
    $table->set_filename("$theme.tex");
    $table->set_position('!htb');
    $table->set_caption_top(0);
    $table->set_theme($theme);
    $table->set_type('std');
    $table->set_header($test_header);
    $table->set_data($test_data);
    #$table->set_width('0.9\textwidth');
    $table->generate();

    $table->set_type('ctable');
    $table->set_maincaption("\\texttt{theme=$theme, type=ctable}");

    $table->set_label("theme${theme}ctable");
    $table->set_filename("${theme}ctable.tex");
    $table->generate();
    $table->set_label(0);

    #    warn Dumper $test_data;
    $table->set_type('xtab');
    $table->set_maincaption("\\texttt{theme=$theme, type=xtab}");
    $table->set_position(0);

    #    $table->set_caption_top(1);
    $table->set_filename("${theme}multipage.tex");
    $table->set_xentrystretch(-0.1);
    $table->set_header($test_header);
    $table->set_data($test_data_large);
    $table->set_caption_top(
        '\setlength{\abovecaptionskip}{0pt}\setlength{\belowcaptionskip}{10pt}\topcaption'
    );
    $table->generate();
    $table->set_filename("${theme}multipage2.tex");
    $table->set_type('longtable');
    $table->set_left(1);
    $table->set_maincaption("\\texttt{theme=$theme, type=longtable, left=1}");
    $table->generate();
    $table->clear_left(0);
}

open my $OUT, '>', 'examples.tex';
foreach my $line (<DATA>) {
    print $OUT $line;
}

my $code = << 'EOC'
\subsection{Table width, tabular* environment}
\tref{tbl:width} demonstrates a fixed-width table in the \texttt{tabular*}
environment. Here, the space between the columns is filled with spaces.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header  => $header,
        data    => $data,
        width   => '0.7\textwidth',
        label   => 'tbl:width',
        caption => '\texttt{width}',
    }
);
\end{verbatim}
EOC
    ;
my $test_header = [ [ 'Animal', 'Description', 'Price' ] ];
$table = LaTeX::Table->new(
    {   header  => $test_header,
        data    => $test_data,
        label   => 'tbl:width',
        width   => '0.7\textwidth',
        caption => '\texttt{width}',
    }
);
print ${OUT} $code . $table->generate_string;

$code = << 'EOC'
\subsection{Large Columns}
The next example is a small table with two larger columns.
\cpanmodule{LaTeX::Table} automatically sets the column to \texttt{p\{5cm\}} when a
cell in a column has more than 30 characters. \LaTeX~generates 
\tref{tbl:paragraph}.

\begin{verbatim}
$table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
        label     => 'tbl:paragraph',
        caption   => 'LaTeX paragraph column attribute.',
    }
);
\end{verbatim}
EOC
    ;

my $header = [ [ 'Character', 'Fullname', 'Voice' ], ];
my $data = [
    [ 'Homer', 'Homer Jay Simpson',               'Dan Castellaneta', ],
    [ 'Marge', 'Marjorie Simpson (née Bouvier)', 'Julie Kavner', ],
    [ 'Bart',  'Bartholomew Jojo Simpson',        'Nancy Cartwright', ],
    [ 'Lisa',  'Elizabeth Marie Simpson',         'Yeardley Smith', ],
    [   'Maggie',
        'Margaret Simpson',
        'Elizabeth Taylor, Nancy Cartwright, James Earl Jones,'
            . 'Yeardley Smith, Harry Shearer',
    ],
];
$table = LaTeX::Table->new(
    {   header  => $header,
        data    => $data,
        label   => 'tbl:paragraph',
        caption => 'LaTeX paragraph column attribute.',
    }
);

print ${OUT} $code;

#$table->set_tabledef_strategy( { 'LONG_COL' => 'p{4cm}', 'IS_LONG' => 30 } );
print ${OUT} $table->generate_string;

$code = << 'EOC'
\subsubsection{\texttt{tabularx}}
We can use the \ctanpackage{tabularx} package to find better column widths than the
default 5cm. See \tref{tbl:tabularx} for the results.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        width             => '0.9\textwidth',
        width_environment => 'tabularx',
        label             => 'tbl:tabularx',
        caption           => '\texttt{width\_environment=tabularx}.',
    }
);
\end{verbatim}
EOC
    ;
$table->set_label('tbl:tabularx');
$table->set_caption('\texttt{width\_environment=tabularx}.');

$table->set_width('0.9\textwidth');
$table->set_width_environment('tabularx');
print ${OUT} $code . $table->generate_string;

$code = << 'EOC'
\subsubsection{\texttt{tabulary}}
A third option is to use the \ctanpackage{tabulary} package. See \tref{tbl:tabulary}.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        width             => '0.9\textwidth',
        width_environment => 'tabulary',
        label             => 'tbl:tabulary',
        caption           => '\texttt{width\_environment=tabulary}.',
    }
);
\end{verbatim}
EOC
    ;
$table->set_label('tbl:tabulary');
$table->set_caption('\texttt{width\_environment=tabulary}.');
$table->set_width_environment('tabulary');

print ${OUT} $code . $table->generate_string;

$code = << 'EOC'
\subsection{Rotate tables}
\tref{tbl:sideways} demonstrates the \ltoption{sideways} option. Requires the
\ctanpackage{rotating} package.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        width    => '0.9\textwidth',
        width_environment 
                 => 'tabularx',
        sideways => 1,
        label    => 'tbl:sideways',
        caption  => '\texttt{width\_environment=tabularx, sideways}.',
    }
);
\end{verbatim}
EOC
    ;

$table->set_sideways(1);
$table->set_caption('\texttt{width\_environment=tabularx, sideways}.');
$table->set_label('tbl:sideways');

print ${OUT} $code . $table->generate_string;

$code = << 'EOC'
\subsection{Resize tables}
In Tables \ref{tbl:resizebox1} and \ref{tbl:resizebox2}, the
\ltoption{resizebox} option was used to get the desired width (and height in
the second example). Requires the \ctanpackage{graphicx} package.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
        resizebox => [ '0.6\textwidth' ],
        label     => 'tbl:resizebox1',
        caption   => '\texttt{resizebox}, Example 1',
    }
);

$table->set_resizebox([ '300pt', '120pt' ]);
\end{verbatim}
EOC
    ;

$table->set_sideways(0);
$table->set_label('tbl:resizebox1');
$table->set_resizebox( ['0.6\textwidth'] );
$table->set_caption('\texttt{resizebox}, Example 1');

print ${OUT} $code . $table->generate_string;

$table->set_label('tbl:resizebox2');
$table->set_resizebox( [ '300pt', '120pt' ] );
$table->set_caption('scaled to a size of 300pt x 120pt');
$table->set_caption('\texttt{resizebox}, Example 2');

print ${OUT} $table->generate_string;

$code = << 'EOC'
\subsection{Callback functions}
Callback functions are an easy way of formatting the cells. Note that the
prices for Gnat are rounded in the following tables.
\begin{verbatim}
my $table = LaTeX::Table->new(
      {
      filename    => 'prices.tex',
      maincaption => 'Price List',
      caption     => 'Try our special offer today!',
      label       => 'tbl:prices',
      header      => $header,
      data        => $data,
      callback    => sub {
           my ($row, $col, $value, $is_header ) = @_;
           if ($col == 2 && $!is_header) {
               $value = format_price($value, 2, '');
           }
           return $value;
     },
});
\end{verbatim}
EOC
    ;

print $OUT $code;

$header = [
    [ 'Item:2c', '' ],
    ['\cmidrule(r){1-2}'],
    [ 'Animal', 'Description', 'Price' ]
];

$data = [
    [ 'Gnat',      'per gram', '13.651' ],
    [ '',          'each',     '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59' ],
    [ 'Emu',       'stuffed',  '33.33' ],
    [ 'Armadillo', 'frozen',   '8.99' ],
];

$table = LaTeX::Table->new(
    {   filename    => 'prices.tex',
        caption     => '\texttt{caption\_top}, Example 1',
        caption_top => 1,
        label       => 'table:pricestop',
        header      => $header,
        data        => $data,
        callback    => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ($is_header) {
                $value = uc $value;
            }
            elsif ( $col == 2 && !$is_header ) {
                $value = format_price( $value, 2, '' );
            }
            return $value;
        },
    }
);

$code = << 'EOT';
\subsection{Captions}
\subsubsection{Placement}
Tables can be placed on top of the tables with \ltoption{caption\_top => 1}. See
\tref{table:pricestop}. Note that the standard \LaTeX~macros are optimized for
bottom captions. Use something like 
\begin{verbatim}
\usepackage[tableposition=top]{caption} 
\end{verbatim}
to fix the spacing. Alternatively, you could fix the spacing by yourself by
providing your own command(s) (\tref{table:pricestop2}):
\begin{verbatim}
$table->set_caption_top(
  '\setlength{\abovecaptionskip}{0pt}' .
  '\setlength{\belowcaptionskip}{10pt}' . 
  \caption'
);
\end{verbatim}
EOT

print $OUT $code . $table->generate_string();
$table->set_caption_top(
    '\setlength{\abovecaptionskip}{0pt}\setlength{\belowcaptionskip}{10pt}\caption'
);
$table->set_label('table:pricestop2');
$table->set_caption('\texttt{caption\_top}, Example 2');

print $OUT $table->generate_string();

$code = << 'EOT';
\subsection{Multicolumns}
If you want tables with vertical lines (are you sure?) you should use our
shortcut to generate multicolumns. These shortcuts are not only much less
typing work, but they also automatically add the vertical lines, see
\tref{tbl:mc}.
\begin{verbatim}
$header = [ [ 'A:3c'        ], 
            [ 'A:2c',  'B'  ], 
            ['A', 'B', 'C'  ], ];

$data   = [ [ '1', 'w', 'x' ], 
            [ '2', 'c:2c'   ], ];

$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        theme    => 'Dresden',
        label    => 'tbl:mc',
        caption  => 'Multicolumns.',
    }
);
\end{verbatim}
EOT

$header = [ ['A:3c'], [ 'A:2c', 'B' ], [ 'A', 'B', 'C' ], ];
$data = [ [ '1', 'w', 'x' ], [ '2', 'c:2c' ], ];

$table = LaTeX::Table->new(
    {   environment => 1,
        header      => $header,
        data        => $data,
        label       => 'tbl:mc',
        caption     => 'Multicolumns.',
        theme       => 'Dresden',
    }
);

print $OUT $code . $table->generate_string();


$code = << 'EOT';
\subsection{Headers}
If you don't need headers, just leave them undefined (see
\tref{tbl:noheader}). If you want that the first column looks like a header,
you can define this with the \ltoption{columns\_like\_header} option
(\tref{table:collikeheader} and \tref{table:collikeheader2}).  If you want
to rotate some header columns by 90 degrees, you can easily do that with a
callback function (\tref{table:headersideways2}).
\begin{verbatim}
$table = LaTeX::Table->new(
    {
    data        => $data,
    label       => 'tbl:noheader',
    caption     => 'Table without header.',
});

$table = LaTeX::Table->new(
    {   header          => $header,
        data            => $data,
        callback        => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $col != 0 && $is_header ) {
                $value = '\begin{sideways}' . $value . '\end{sideways}';
            }
            return $value;
        },
        ...
    }
);
\end{verbatim}
EOT

$data = [
    [ 'Gnat',      'per gram', '13.651' ],
    [ '',          'each',     '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59' ],
    [ 'Emu',       'stuffed',  '33.33' ],
    [ 'Armadillo', 'frozen',   '8.99' ],
];

$table = LaTeX::Table->new(
    {   caption => 'Table without header.',
        label   => 'tbl:noheader',
        data    => $data,
    }
);


print $OUT $code . $table->generate_string();

$table->set_theme('NYC2');
$table->set_columns_like_header( [0] );
$table->set_label('table:collikeheader');
$table->set_caption('\texttt{columns\_like\_header}, Example 1: A transposed table.');

print $OUT $table->generate_string();

$table->set_label('table:collikeheader2');
$table->set_caption('\texttt{columns\_like\_header}, Example 2.');
$table->set_header($header);

print $OUT $table->generate_string();

$table->set_theme('NYC');
$header
    = [ [ 'Time', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday' ] ];

$data = [
    [ '9.00',  '', '', '', '', '', ],
    [ '10.00', '', '', '', '', '', ],
    [ '11.00', '', '', '', '', '', ],
    [ '12.00', '', '', '', '', '', ],
];


$table = LaTeX::Table->new(
    {   header          => $header,
        data            => $data,
        label           => 'table:headersideways2',
        caption         => '\texttt{callback, right}',
        right           => 1,
        callback        => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $col != 0 && $is_header ) {
                $value = '\begin{sideways}' . $value . '\end{sideways}';
            }
            return $value;
        },
        theme => 'NYC',
    }
);

print $OUT $table->generate_string();

$code = << 'EOT';
\subsection{CSV Files}
For importing CSV files, we can use the CPAN module \cpanmodule{Text::CSV}:
\begin{verbatim}
my $csv = Text::CSV->new(
    {   binary           => 1,
        sep_char         => q{,},
        allow_whitespace => 1
    }
);

open my $IN, '<', 'imdbtop40.dat';

my $line_number = 0;
while ( my $line = <$IN> ) {
    chomp $line;
    my $status = $csv->parse($line);
    if ( $line_number == 0 ) {
       $header = [ [ $csv->fields() ] ];
    }
    else {
        push @{$data}, [ $csv->fields() ];
    }
    $line_number++;
}
close $IN;

$table = LaTeX::Table->new(
    {   header        => $header,
        data          => $data,
        type          => 'xtab',
        sideways      => 1,
        tabletail     => q{},
        label         => 'tbl:xtab',
        caption       => '\texttt{type=xtab}',
        tablelasttail => '\tiny{www.imdb.com}',
        caption_top   => 1,
    }
);
\end{verbatim}
See \tref{tbl:xtab}, which uses the \ctanpackage{xtab} package for spanning across
multiple pages. You can also use the \ctanpackage{longtable} package here.
This package can be used together with the \ctanpackage{ltxtable} package to
define a table width. Here, you have to generate a \textit{file} and then load the
file with the \texttt{LTXtable} command. See \tref{tbl:longtable}.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header        => $header,
        data          => $data,
        type          => 'longtable',
        tabletail     => q{},
        label         => 'tbl:longtable',
        caption       => '\texttt{type=longtable}',
        tablelasttail => '\tiny{www.imdb.com}',
        caption_top   => 1,
        # we don't define a width here!
        width_environment => 'tabularx', 
        filename       => 'longtable.tex'
    }
);

%now in LaTeX:
\LTXtable{0.8\textwidth}{longtable}

\end{verbatim}
EOT
my $line_number = 0;

my $csv = Text::CSV->new(
    {   binary           => 1,
        sep_char         => q{,},
        allow_whitespace => 1
    }
);

@{$data} = ();

open my $IN, '<', 'imdbtop40.dat';
while ( my $line = <$IN> ) {
    chomp $line;
    my $status = $csv->parse($line);
    if ( $line_number == 0 ) {
       $header = [ [ $csv->fields() ] ];
    }
    else {
        push @{$data}, [ $csv->fields() ];
    }
    $line_number++;
}
close $IN;

$table = LaTeX::Table->new(
    {   header      => $header,
        data        => $data,
        type        => 'xtab',
        sideways    => 1,
        tabletail   => q{ },
        label       => 'tbl:xtab',
        caption     => '\texttt{type=xtab}',
        tablelasttail => '\tiny{www.imdb.com}',
        caption_top => 
        '\setlength{\abovecaptionskip}{0pt}\setlength{\belowcaptionskip}{10pt}\topcaption',
    }
);
print $OUT $code . $table->generate_string();

$table = LaTeX::Table->new(
    {   header      => $header,
        data        => $data,
        type        => 'longtable',
        tabletail   => q{},
        label       => 'tbl:longtable',
        caption     => '\texttt{type=longtable}',
        tablelasttail => '\tiny{www.imdb.com}',
        caption_top => 1,
        # we don't define a width here!
        width_environment => 'tabularx', 
        filename    => 'longtable.tex',
    });

print $table->generate();

$code = << 'EOT';
\LTXtable{0.8\textwidth}{longtable}

\subsection{Automatic column definitions}
We can easily provide regular expressions that define the alignment of
columns. See \tref{tbl:coldef_strategy}.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header  => [ [ 'Website', 'URL' ] ],
        data    => [
            [ 'Slashdot',  'http://www.slashdot.org'  ],
            [ 'Perlmonks', 'http://www.perlmonks.org' ],
            [ 'Google',    'http://www.google.com'    ],
        ],
        coldef_strategy => {
            URL     => qr{ \A \s* http }xms,
            URL_COL => '>{\ttfamily}l',
        },
        label   => 'tbl:coldef_strategy',
        caption => '\texttt{coldef\_strategy}',
    }
);
\end{verbatim}
EOT

$table = LaTeX::Table->new(
    {   header  => [ [ 'Website', 'URL' ] ],
        data    => [
            [ 'Slashdot',  'http://www.slashdot.org' ],
            [ 'Perlmonks', ' http://www.perlmonks.org' ],
            [ 'Google',    'http://www.google.com' ],
        ],
        coldef_strategy => {
            URL     => qr{ \A \s* http }xms,
            URL_COL => '>{\ttfamily}l',
        },
        label   => 'tbl:coldef_strategy',
        caption => '\texttt{coldef\_strategy}',
    }
);

print $OUT $code . $table->generate_string();

$code = << 'EOT';
\subsection{Continued Tables}
As alternative to multi-page tables, we can also split tables. The
\ltoption{continued} option then decrements the table counter and adds the
\ltoption{continuedmsg} (default is `(continued)') to the caption. See
\tref{tbl:coldef_strategy}. That even works with \ltoption{xtab} tables.
\begin{verbatim}
$table = LaTeX::Table->new(
    {   header  => [ [ 'Website', 'URL' ] ],
        data    => [
            [ 'CPAN',  'http://www.cpan.org'  ],
            [ 'Amazon', 'http://www.amazon.com' ],
        ],
        coldef_strategy => {
            URL     => qr{ \A \s* http }xms,
            URL_COL => '>{\ttfamily}l',
        },
        continued => 1,
        label     => 'tbl:continued',
        caption   => '\texttt{continued}',
    }
);
\end{verbatim}
EOT
$table = LaTeX::Table->new(
    {   header  => [ [ 'Website', 'URL' ] ],
        data    => [
            [ 'CPAN',  'http://www.cpan.org'  ],
            [ 'Amazon', 'http://www.amazon.com' ],
        ],
        coldef_strategy => {
            URL     => qr{ \A \s* http }xms,
            URL_COL => '>{\ttfamily}l',
        },
        continued => 1,
        label     => 'tbl:continued',
        caption   => '\texttt{continued}',
    }
);

print $OUT $code . $table->generate_string();


$code = << 'EOT';
\subsection{Ctable Package}
The \ctanpackage{ctable} package makes it easy to add footnotes. See
\tref{tbl:websitectable}. 
\begin{verbatim}
$table->set_type('ctable');
$table->set_foottable('\tnote{footnotes are placed under the table}');
\end{verbatim}
EOT

$table->set_label('tbl:websitectable');
$table->set_caption('\texttt{coldef\_strategy, type=ctable, foottable, continued}.');
$table->set_type('ctable');
$table->set_foottable('\tnote{footnotes are placed under the table}');
$table->set_data(
         [
            [ 'Slashdot\tmark',  'http://www.slashdot.org' ],
            [ 'Perlmonks', 'http://www.perlmonks.org' ],
            [ 'Google',    'http://www.google.com' ],
        ]);

print $OUT $code . $table->generate_string();


$code = << 'EOT';
\subsection{Multicols}
In a twocolumn or multicols document, we use this starred version for
\tref{table:websitectablestar}:

\begin{multicols}{2}
\begin{verbatim}
$table->set_star(1);
\end{verbatim}
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla
EOT

$table->set_star(1);
$table->set_continued(0);
$table->set_position('htbp');
$table->set_label('table:websitectablestar');
$table->set_caption('\texttt{coldef\_strategy, type=ctable, foottable, star}.');
print $OUT $code . $table->generate_string();

$code = << 'EOT';
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla

bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla bla
bla bla bla bla bla bla
EOT

print $OUT $code .  "\n\\end{multicols}\n";

$code = << 'EOT';
\section{Customize \cpanmodule{LaTeX::Table}}

This module tries hard to produce perfect results with as less provided
options as possible. However, typesetting tables is a complex topic and
therefore almost everything in \cpanmodule{LaTeX::Table} is configurable.

\subsection{Custom Themes}\label{sec:customthemes}

\tref{table:customtheme1} displays our example table with the \textit{NYC}
theme, which is meant for presentations (with LaTeX Beamer for example). You
can change the theme by copying it, changing it and then storing it in
\ltoption{custom\_themes} (\tref{table:customtheme2}).  You can also add the
theme to the predfined themes by creating a themes module.  See
\cpanmodule{LaTeX::Table::Themes::ThemeI} how to do that.
\begin{verbatim}
my $nyc_theme = $table->get_available_themes->{'NYC'};
$nyc_theme->{'DEFINE_COLORS'}       = 
          '\definecolor{latextablegreen}{RGB}{93,127,114}';
$nyc_theme->{'HEADER_BG_COLOR'}     = 'latextablegreen';
$nyc_theme->{'DATA_BG_COLOR_ODD'}   = 'latextablegreen!25';
$nyc_theme->{'DATA_BG_COLOR_EVEN'}  = 'latextablegreen!10';

$table->set_custom_themes({ CENTRALPARK => $nyc_theme });
$table->set_theme('CENTRALPARK');
\end{verbatim}
EOT

$header = [ [ 'Item:2c', '' ], [ 'Animal', 'Description', 'Price' ] ];

$data = [
    [ 'Gnat',      'per gram', '13.651' ],
    [ '',          'each',     '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59' ],
    [ 'Emu',       'stuffed',  '33.33' ],
    [ 'Armadillo', 'frozen',   '8.99' ],
];

$table = LaTeX::Table->new(
    {   filename    => 'prices.tex',
        caption     => '\texttt{custom\_themes}, Example 1',
        label       => 'table:customtheme1',
        header      => $header,
        data        => $data,
        theme       => 'NYC',
        callback    => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $col == 2 && !$is_header ) {
                $value = format_price( $value, 2, '' );
            }
            return $value;
        },
    }
);

print $OUT $code . $table->generate_string();

my $nyc_theme = $table->get_available_themes->{'NYC'};
$nyc_theme->{'DEFINE_COLORS'}
    = '\definecolor{latextablegreen}{RGB}{93,127,114}';
$nyc_theme->{'HEADER_BG_COLOR'}    = 'latextablegreen';
$nyc_theme->{'DATA_BG_COLOR_ODD'}  = 'latextablegreen!25';
$nyc_theme->{'DATA_BG_COLOR_EVEN'} = 'latextablegreen!10';
$nyc_theme->{'EXTRA_ROW_HEIGHT'}   = '1pt';

$table->set_custom_themes( { CENTRALPARK => $nyc_theme } );
$table->set_theme('CENTRALPARK');
$table->set_label('table:customtheme2');
$table->set_caption('\texttt{custom\_themes}, Example 2');

print $OUT $table->generate_string();

$code = << 'EOT';
\subsection{Custom Templates}\label{sec:customtemplates}

\cpanmodule{LaTeX::Table} ships with some very flexible and powerful
templates. Templates are a convenient way of generating the LaTeX code out of
the user options and data. Internally, the \cpanmodule{Template} Toolkit
available from CPAN is used. It is possible to change the standard templates
(each table \ltoption{type} has its own template) with the
\ltoption{custom\_template} option. For example, the \LaTeX~styles of some
scientific journals provide their own table commands, here the one from the
Bioinformatics journal:

\begin{verbatim}
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
\end{verbatim}
A very basic template for this would be:
{\footnotesize
\begin{verbatim}
[% IF ENVIRONMENT %]
\begin{[% ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF POSITION %][[% POSITION %]]
[% END %][% END %]
\processtable{[% IF CAPTION %][% CAPTION %][% END %][% IF LABEL %]\label{[% LABEL %]}[% END %]}
{\begin{[% TABULAR_ENVIRONMENT %]}{[% COLDEF %]}
[% HEADER_CODE %][% DATA_CODE %]\end{[% TABULAR_ENVIRONMENT %]}}{[% FOOTTABLE %]}
[% IF ENVIRONMENT %]\end{table}[% END %]
\end{verbatim}}
\noindent Now we have to define a the theme that is responsible for the rules (see
\ref{sec:customthemes}):
\begin{verbatim}
  'Oxford' => {
      'STUB_ALIGN'        => q{l},
      'VERTICAL_RULES'    => [ 0, 0, 0 ],
      'HORIZONTAL_RULES'  => [ 1, 1, 0 ],
      'RULES_CMD' => [ '\toprule', '\midrule', '\midrule', '\botrule' ],
  }
\end{verbatim}
Finally we can typeset tables for the Bioinformatics journal:
\begin{verbatim}
$table = LaTeX::Table->new(
    {   
        caption           => 'This is table caption',
        label             => 'Tab:01',
        foottable         => 'This is a footnote',
        position          => '!t',
        header            => $test_header,
        data              => $test_data,
        theme             => 'Oxford',
        custom_template   => $custom_template,
    }
);
\end{verbatim}
If you think your custom template might be useful for others, please
contribute it!
EOT
;

print ${OUT}
    "$code\\section{Version}\\small{Generated with LaTeX::Table Version
    \$$LaTeX::Table::VERSION\$}\n";

$code = << 'EOT';
\clearpage\begin{appendix}
\section{Header/Data}
\subsection{Simpsons Table}
\begin{verbatim}
my $header = [ [ 'Character', 'Fullname', 'Voice' ], ];
my $data = [
    [ 'Homer',  'Homer Jay Simpson',        'Dan Castellaneta'   ],
    [ 'Marge',  'Marjorie Simpson',         'Julie Kavner'       ],
    [ 'Bart',   'Bartholomew Jojo Simpson', 'Nancy Cartwright'   ],
    [ 'Lisa',   'Elizabeth Marie Simpson',  'Yeardley Smith'     ],
    [ 'Maggie', 'Margaret Simpson',
        'Elizabeth Taylor, Nancy Cartwright, James Earl Jones,'
     .  'Yeardley Smith, Harry Shearer'                          ],
];
\end{verbatim}

\subsection{Animal Table}

\begin{verbatim}
my $header = [
    [ 'Item:2c', '' ],
    [ '\cmidrule(r){1-2}'],
    [ 'Animal', 'Description',  'Price' ]
];

my $data = [
    [ 'Gnat',      'per gram', '13.651' ],
    [ '',          'each',      '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59'  ],
    [ 'Emu',       'stuffed',  '33.33'  ],
    [ 'Armadillo', 'frozen',    '8.99'  ],
];
\end{verbatim}

\section{Themes}
EOT
;
print $OUT $code;

$table = LaTeX::Table->new();

my %section = ( std => '', 
                ctable => 'ctable', 
                longtable => 'multipage2', 
                xtab => 'multipage',);

for my $sect (qw(std ctable xtab longtable)) {

    print $OUT "\\subsection{Type $sect}\n";
for my $theme ( sort keys %{ $table->get_available_themes } ) {
    print $OUT "\\input{$theme$section{$sect}.tex}\n";
    if ($sect eq "xtab") {
        print $OUT "\\clearpage \n";
    }
}
    print $OUT "\\clearpage \n";
}
print $OUT '\end{appendix}\end{document}' . "\n";
close $OUT;

__DATA__
\documentclass[11pt]{article}
\usepackage{layouts}

\setlength{\textheight}{8.0in}
\setlength{\textwidth}{6.0in}
\setlength{\oddsidemargin}{0.25in}
\setlength{\evensidemargin}{0.25in}
\setlength{\marginparwidth}{0.6in}
\setlength{\parskip}{5pt}
\setcounter{secnumdepth}{4}
\setcounter{tocdepth}{4}

\setlength{\columnsep}{30pt}

\setcounter{topnumber}{2}
\setcounter{bottomnumber}{2}
\setcounter{totalnumber}{4}
\renewcommand{\topfraction}{0.9}
\renewcommand{\bottomfraction}{0.6}
\renewcommand{\textfraction}{0.1}


%\newlength{\figrulesep}
%\setlength{\figrulesep}{0.5\textfloatsep}
%
%\newcommand{\topfigrule}{\vspace*{-1pt}%
%  \noindent\rule[-\figrulesep]{\columnwidth}{1pt}}
%
%\newcommand{\botfigrule}{\vspace*{-2pt}%
%  \noindent\rule[\figrulesep]{\columnwidth}{2pt}}

\makeatletter

\renewcommand{\subsubsection}{\@startsection%
  {subsubsection}%
  {3}%
  {0mm}%
  {-\baselineskip}%
  {0.5\baselineskip}%
  {\large\itshape}}


\newcommand{\fref}[1]{Figure~\ref{#1}}
\newcommand{\tref}[1]{Table~\ref{#1}}
\newcommand{\T}{\texttt{true}}
\newcommand{\F}{\texttt{false}}
\newcommand{\TF}{\textit{true/false}}


%%%% the \meta command
\begingroup
\obeyspaces%
\catcode`\^^M\active%
\gdef\meta{\begingroup\obeyspaces\catcode`\^^M\active%
\let^^M\do@space\let \do@space%
\def\-{\egroup\discretionary{-}{}{}\hbox\bgroup\it}%
\m@ta}%
\endgroup
\def\m@ta#1{\leavevmode\hbox\bgroup$\langle$\it#1\/$\rangle$\egroup
  \endgroup}
\def\do@space{\egroup\space
    \hbox\bgroup\it\futurelet\next\sp@ce}
\def\sp@ce{\ifx\next\do@space\expandafter\sp@@ce\fi}
\def\sp@@ce#1{\futurelet\next\sp@ce}

\newcommand{\marg}[1]{\texttt{\{}\meta{#1}\texttt{\}}}

\newcommand{\file}[1]{\textsf{#1}}
\newcommand{\ltoption}[1]{\texttt{#1}}
\newcommand{\ctanpackage}[1]{\file{#1}}
\newcommand{\cpanmodule}[1]{\file{#1}}

\providecommand{\indexfill}{}
\providecommand{\sindexfill}{}
\providecommand{\ssindexfill}{}
\providecommand{\otherindexspace}[1]{}
\providecommand{\alphaindexspace}[1]{\indexspace{\bfseries #1}}

%%% \setlength{\parindent}{-4em}
\makeatother
\usepackage{url}
\usepackage{ctable}
\usepackage{graphics, graphicx}
\usepackage{xtab}
\usepackage{lscape}
\usepackage{booktabs}
\usepackage{rotating}
\usepackage{tabularx}
\usepackage{tabulary}
\usepackage{listings}
\usepackage{longtable}
%\usepackage{color}
\usepackage{colortbl}
\usepackage{xcolor}
\usepackage{graphicx}
\usepackage{ltxtable}
\usepackage{multicol}
\usepackage{array}% in the preamble
%\usepackage[tableposition=top]{caption}
\title{LaTeX::Table}
\date{\today}
 \makeindex
\begin{document}
\bibliographystyle{alpha}
\pagenumbering{roman}
\maketitle
\begin{abstract}

\file{LaTeX::Table} is a Perl module that provides functionality for an
intuitive and easy generation of LaTeX tables. It ships with some predefined
good looking table styles. This module supports multipage tables via the
\texttt{xtab} and the \texttt{longtable} package and publication quality
tables with the \texttt{booktabs} package. It also supports the
\texttt{tabularx} and \texttt{tabulary} packages for nicer fixed-width tables.
Furthermore, it supports the \texttt{colortbl} package for colored tables
optimized for presentations.

\end{abstract}
\tableofcontents
\listoftables
\clearpage
\pagenumbering{arabic}

\section{Installation}
You can install this software with the \texttt{cpan} command.
    
\begin{verbatim}
  $ cpan LaTeX::Table
\end{verbatim}
Alternatively, download \cpanmodule{LaTeX::Table} directly from
\url{http://search.cpan.org/dist/LaTeX-Table/} and install in manually:
\begin{verbatim}
  $ tar xvfz LaTeX-Table-VERSION.tar.gz
  $ perl Build.PL
  $ ./Build test
  $ ./Build install
\end{verbatim}

\section{Examples}

