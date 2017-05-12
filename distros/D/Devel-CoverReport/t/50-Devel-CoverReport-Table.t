#!/usr/bin/perl
# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/
use strict; use warnings;

# DEBUG on
use FindBin qw( $Bin );
use lib $Bin .'/../lib';
# DEBUG off

use Test::More;

plan tests => 11;

use_ok('Devel::CoverReport::Table');

my $table_1 = Devel::CoverReport::Table->new(
    label   => 'first test table',
    headers => {
        foo => { caption => "Foo-o", f => q{%d}, fs => q{%d avg.} },
        bar => { caption => "Bar-r" },
        baz => { caption => "Baz-z" },
    },
    headers_order => [ qw( foo baz bar ) ],
);

isa_ok($table_1, 'Devel::CoverReport::Table');

is ($table_1->add_row( { foo=>1, bar=>'one',   baz=>'jeden' } ), 1, "Add first row");
is ($table_1->add_row( { foo=>2, bar=>'two',   baz=>'dwa' } ),   2, "Add second row");
is ($table_1->add_row( { foo=>3, bar=>'three', baz=>'trzy' } ),  3, "Add third row");

is ($table_1->add_summary( { foo=>'21', bar=>'one time',  baz=>'jeden raz' } ), 1, "Add first summary");
is ($table_1->add_summary( { foo=>'22', bar=>'two times', baz=>'dwa razy' } ),  2, "Add second summary");

is_deeply(
    $table_1->get_headers(),
    {
        foo => { caption => "Foo-o", f=>q{%d}, fs=>q{%d avg.} },
        bar => { caption => "Bar-r", f=>q{%s}, fs=>q{%s} },
        baz => { caption => "Baz-z", f=>q{%s}, fs=>q{%s} },
    },
    'headers returned'
);
is_deeply($table_1->get_headers_order(), [qw( foo baz bar )], 'headers order returned');
is_deeply(
    $table_1->get_rows(),
    [
        { foo=>1, bar=>'one',   baz=>'jeden' },
        { foo=>2, bar=>'two',   baz=>'dwa' },
        { foo=>3, bar=>'three', baz=>'trzy' },
    ],
    'rows returned'
);
is_deeply(
    $table_1->get_summary(),
    [
        { foo=>'21', bar=>'one time',  baz=>'jeden raz' },
        { foo=>'22', bar=>'two times', baz=>'dwa razy' },
    ],
    'summaries returned'
);

# vim: fdm=marker
