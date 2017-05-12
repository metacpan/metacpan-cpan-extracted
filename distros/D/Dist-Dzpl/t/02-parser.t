#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Dist::Dzpl::Parser;

my ( $zilla, $prerequisite );

Dist::Dzpl::Parser->_parse_license( $zilla = {}, 'Perl-5' );
cmp_deeply( $zilla, { license => 'Perl_5' } );

Dist::Dzpl::Parser->_parse_license( $zilla = {}, 'Perl5' );
cmp_deeply( $zilla, { license => 'Perl_5' } );

Dist::Dzpl::Parser->_parse_license( $zilla = {}, 'Perl_5' );
cmp_deeply( $zilla, { license => 'Perl_5' } );

Dist::Dzpl::Parser->_parse_author( $zilla = {}, <<_END_ );
    
Alice
        \t
   Bob <bob\@example.org>

_END_
cmp_deeply( $zilla, { authors => [ 'Alice', 'Bob <bob@example.org>' ] } );

Dist::Dzpl::Parser->_parse_copyright( $zilla = {}, 'Bob' );
cmp_deeply( $zilla, { copyright_holder => 'Bob' } );

Dist::Dzpl::Parser->_parse_copyright( $zilla = {}, '2009 Bob' );
cmp_deeply( $zilla, { copyright_holder => 'Bob', copyright_year => '2009' } );

Dist::Dzpl::Parser->_parse_copyright( $zilla = {}, '  2010      Bob   ' );
cmp_deeply( $zilla, { copyright_holder => 'Bob', copyright_year => '2010' } );

Dist::Dzpl::Parser->_parse_prerequisite( $prerequisite = [], 'require' => <<'_END_' );
Moose
_END_

cmp_deeply( $prerequisite, [ { manifest => [qw/ Moose 0 /], qw/ phase runtime type require / } ] );

Dist::Dzpl::Parser->_parse_prerequisite( $prerequisite = [], 'require' => <<'_END_' );
[Runtime]
Moose
_END_

cmp_deeply( $prerequisite, [ { manifest => [qw/ Moose 0 /], qw/ phase runtime type require / } ] );

Dist::Dzpl::Parser->_parse_prerequisite( $prerequisite = [], 'require' => <<'_END_' );
[Test]
[Runtime]
Moose
_END_

cmp_deeply( $prerequisite, [ { manifest => [qw/ Moose 0 /], qw/ phase runtime type require / } ] );

Dist::Dzpl::Parser->_parse_prerequisite( $prerequisite = [], 'recommend' => <<'_END_' );
[Runtime]
Moose

[Test]
Test::More 1.22
_END_

cmp_deeply( $prerequisite, [
    { manifest => [qw/ Moose 0 /], qw/ phase runtime type recommend / },
    { manifest => [qw/ Test::More 1.22 /], qw/ phase test type recommend / },
] );

Dist::Dzpl::Parser->_parse_prerequisite( $prerequisite = [], 'recommend' => <<'_END_' );
[tEsT]
Test::More 1.22

[Runtime]
Moose 0.0
_END_

cmp_deeply( $prerequisite, [
    { manifest => [qw/ Test::More 1.22 /], qw/ phase test type recommend / },
    { manifest => [qw/ Moose 0.0 /], qw/ phase runtime type recommend / },
] );

Dist::Dzpl::Parser->_parse_prerequisite( $prerequisite = [], 'recommend' => <<'_END_' );
[tEsT]
Test::More 1.22

[Runtime]
Moose 0.0
_END_
