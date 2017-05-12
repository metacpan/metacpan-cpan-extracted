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

plan tests => 9;

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
    $obj = JustOneFact->new( %params, content => [ $facts{FactOne} ] );
}, undef,
"lives: new() takes 1 fact, and given 1 fact";

isnt exception {
    $obj = JustOneFact->new( %params, content => [] );
}, undef,
"dies: new() takes 1 fact, but given none";

isnt exception {
    $obj = JustOneFact->new( %params, content => [ @facts{qw/FactOne FactTwo/} ] );
}, undef,
"dies: new() takes 1 fact, but given 2 facts";

#--------------------------------------------------------------------------#
# report that takes 1+ facts
#--------------------------------------------------------------------------#

is exception {
    $obj = OneOrMoreFacts->new( %params, content => [ @facts{qw/FactOne FactTwo/} ] );
}, undef,
"lives: new() takes 1+ fact, and given 2 facts";

#--------------------------------------------------------------------------#
# report that takes 1 of each
#--------------------------------------------------------------------------#

is exception {
    $obj = OneOfEach->new( %params, content => [ @facts{qw/FactOne FactTwo/} ] );
}, undef,
"lives: new() takes 1 of each, given 1 of each";

isnt exception {
    $obj = OneOfEach->new( %params, content => [ @facts{qw/FactOne FactOne/} ] );
}, undef,
"dies: new() takes 1 of each, given 2 of one kind";

#--------------------------------------------------------------------------#
# report that takes 1 of each
#--------------------------------------------------------------------------#

is exception {
    $obj =
      OneSpecificAtLeastThreeTotal->new( %params,
        content => [ @facts{qw/FactOne FactTwo FactTwo/} ] );
}, undef,
"lives: new() takes 1 specific 3 total, given correctly";

