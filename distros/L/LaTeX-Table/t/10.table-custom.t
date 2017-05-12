use Test::More tests => 3;
use Test::NoWarnings;

use strict;
use warnings;

use LaTeX::Table;


my $header = [
    [ 'Item:2c', '' ],
    ['\cmidrule(r){1-2}'],
    [ 'Animal', 'Description', 'Price' ]
];

my $data = [
    [ 'Gnat',      'per gram', '13.65' ],
    [ '',          'each',      '0.01' ],
    [ 'Gnu',       'stuffed',  '92.59' ],
    [ 'Emu',       'stuffed',  '33.33' ],
    [ 'Armadillo', 'frozen',    '8.99' ],
];


my $table = LaTeX::Table->new(
{   
    filename    => 'prices.tex',
    maincaption => 'Price List',
    caption     => 'Try our special offer today!',
    label       => 'table:prices',
    position    => 'htb',
    header      => $header,
    data        => $data,
    theme       => 'Meyrin',
    custom_template => '[% DATA_CODE %]',
}
);

my $expected_output =<<'EOT'
Gnat      & per gram & 13.65 \\
          & each     & 0.01  \\
Gnu       & stuffed  & 92.59 \\
Emu       & stuffed  & 33.33 \\
Armadillo & frozen   & 8.99  \\
\bottomrule
EOT
;

my $output = $table->generate_string();
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'BODY_CODE');

$table->set_custom_template('[% HEADER_CODE %]');

$expected_output =<<'EOT'
\toprule
\multicolumn{2}{c}{Item} &             \\
\cmidrule(r){1-2}
Animal                   & Description & Price \\
\midrule
EOT
;

$output = $table->generate_string();
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 
    'HEADER_CODE');
