#!/usr/bin/perl
# $Id: 05-add-encodings.t 19 2012-08-29 06:19:44Z andrew $

use strict;
use warnings;

use Test::More tests => 6;

use blib;
use LaTeX::Encode qw(:all);

is(latex_encode('A'), 'A',   'pre add_latex_encoding (\'A\' => \'A\')');
is(latex_encode('$'), '\\$', 'pre add_latex_encoding (\'$\' => \'\\$\')');
is(latex_encode("\x{00A3}"), '{\\textsterling}',  'post add_latex_encoding (\'£\' => \'{\\textsterling}\')');
add_latex_encodings( 'A' => 'B');
add_latex_encodings( '$' => 'DOLLAR', "\x{00A3}" => 'POUND');
is(latex_encode('A'), 'B',      'post add_latex_encoding (\'A\' => \'B\')');
is(latex_encode('$'), 'DOLLAR', 'post add_latex_encoding (\'$\' => \'DOLLAR\')');
is(latex_encode("\x{00A3}"), 'POUND',  'post add_latex_encoding (\'£\' => \'POUND\')');
