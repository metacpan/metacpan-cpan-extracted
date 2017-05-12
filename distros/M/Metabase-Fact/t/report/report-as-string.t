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

plan tests => 13;

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

my ( $report, $err );

#--------------------------------------------------------------------------#
# report that takes 1 fact
#--------------------------------------------------------------------------#

is exception {
    $report = JustOneFact->open(%params);
}, undef,
": open() given no facts";

isa_ok( $report, 'JustOneFact' );

is exception {
    $report->add( 'FactOne' => 'This is FactOne' );
}, undef,
"lives: add( 'Class' => 'foo' )";

is exception {
    $report->close;
}, undef,
"lives: close()";

#--------------------------------------------------------------------------#
# round trip
#--------------------------------------------------------------------------#

my $class = ref $report;

my $report2;
is exception {
    $report2 = $class->from_struct( $report->as_struct );
}, undef,
"lives: as_struct->from_struct";

isa_ok( $report2, $class );

is_deeply( $report, $report2, "report2 is a clone of report" );

# set_creator
for my $fact ( $report, $report->facts ) {
    is( $fact->creator, undef, "no creator (round 1)" );
}

my $creator_uri = 'metabase:user:351e99ea-1d21-11de-ab9c-3268421c7a0a';

$report->set_creator($creator_uri);

for my $fact ( $report, $report->facts ) {
    is( $fact->creator, $creator_uri, "creator set properly (round 2)" );
}
