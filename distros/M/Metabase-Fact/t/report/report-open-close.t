# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://dev.perl.org/licenses/

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';

plan tests => 15;

require_ok('Metabase::Report');
require_ok('Test::Metabase::StringFact');

#--------------------------------------------------------------------------#
# fixtures
#--------------------------------------------------------------------------#

require ReportSubclasses;
require FactSubclasses;

my %params = ( resource => "cpan:///distfile/JOHNDOE/Foo-Bar-1.23.tar.gz", );

my %facts = (
    FactOne => FactOne->new( %params, content => "FactOne" ),
    FactTwo => FactTwo->new( %params, content => "FactTwo" ),
);

my ( $obj, $err );

#--------------------------------------------------------------------------#
# report that takes 1 fact
#--------------------------------------------------------------------------#

is exception {
    $obj = JustOneFact->open(%params);
}, undef,
"lives: open() given no facts";

isa_ok( $obj, 'JustOneFact' );

is exception {
    $obj->add( 'FactOne' => 'This is FactOne' );
}, undef,
"lives: add( 'Class' => 'foo' )";

is exception {
    $obj->close;
}, undef,
"lives: close()";

#--------------------------------------------------------------------------#
# add takes a fact directly
#--------------------------------------------------------------------------#

is exception {
    $obj = JustOneFact->open(%params);
}, undef,
"lives: open() given no facts";

isa_ok( $obj, 'JustOneFact' );

is exception {
    $obj->add( $facts{FactOne} );
}, undef,
"lives: add( \$fact )";

is exception {
    $obj->close;
}, undef,
"lives: close()";

#--------------------------------------------------------------------------#
# errors
#--------------------------------------------------------------------------#

is exception {
    $obj = JustOneFact->open(%params);
}, undef,
"lives: open() given no facts";

isa_ok( $obj, 'JustOneFact' );

is exception {
    $obj->add( 'FactOne' => 'This is FactOne' );
}, undef,
"lives: add( 'Class' => 'foo' )";

is exception {
    $obj->add( 'FactTwo' => 'This is FactTwo' );
}, undef,
"lives: add( 'Class2' => 'foo' )";

$err = exception { $obj->close };
like $err, qr/content invalid/, "dies: close() with two facts";

