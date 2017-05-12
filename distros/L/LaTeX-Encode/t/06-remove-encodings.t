#!/usr/bin/perl
# $Id: 06-remove-encodings.t 19 2012-08-29 06:19:44Z andrew $

use strict;
use warnings;

use Test::More tests => 4;

use blib;
use LaTeX::Encode qw(:all);

is(latex_encode('$'), '\\$',       'pre remove_latex_encoding (\'$\' => \'\\$\')');
my %removed_encodings = remove_latex_encodings( qw($) );
ok(exists $removed_encodings{'$'}, 'remove_latex_encodings returns hash with key \'$\'');
is($removed_encodings{'$'}, '\\$', 'removed encoding hash element \'$\' has value \'\\$\'');
is(latex_encode('$'), '$',         'post remove_latex_encoding (\'$\' => \'$\')');
