#!/usr/bin/perl
# $Id: 08-import-specs.t 19 2012-08-29 06:19:44Z andrew $

use strict;
use warnings;

use Test::More tests => 9;

use blib;
use LaTeX::Encode
    ':all',
    add    => { "\$"       => 'DOLLAR',
                "\x{00A3}" => 'POUND' },
    remove => [ qw( % ) ];

diag('add/remove specified on \'use LaTeX::Encode\'');
is(latex_encode('$'),        'DOLLAR', '\'$\' => \'DOLLAR\' - mapping added on import');
is(latex_encode("\x{00A3}"), 'POUND',  '\'£\' => \'POUND\'  - mapping added on import');
is(latex_encode('%'),        '%',      '\'%\' => \'%\')     - mapping removed on import');

diag('resetting and forgetting mappings specified on import');
LaTeX::Encode->reset_latex_encodings(1);

is(latex_encode('$'),        '\\$',              '\'$\' => \'\\$\'              - standard mapping restored on reset');
is(latex_encode("\x{00A3}"), '{\\textsterling}', '\'£\' => \'{\\textsterling}\' - standard mapping restored on reset');
is(latex_encode('%'),        '\\%',              '\'%\' => \'\\%\'              - standard mapping restored on reset');

diag('resetting and remembering mappings specified on import');
LaTeX::Encode->reset_latex_encodings();

is(latex_encode('$'),        'DOLLAR',           '\'$\' => \'DOLLAR\' - our mapping restored on reset');
is(latex_encode("\x{00A3}"), 'POUND',            '\'£\' => \'POUND\'  - our mapping restored on reset');
is(latex_encode('%'),        '%',                '\'%\' => \'%\')     - our mapping restored on reset');
