#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

ok( $] > 5.006, 'Perl version is 5.006 or newer' );
use_ok( 'Math::Symbolic' );
ok( $Math::Symbolic::VERSION > 0.200 );
use_ok( 'Math::Symbolic::Custom::LaTeXDumper' );

my $ms = Math::Symbolic::Constant->one();
isa_ok( $ms, 'Math::Symbolic::Constant' );
isa_ok( $ms, 'Math::Symbolic::Base' );
ok( $ms->can('to_latex'), 'Math::Symbolic tree provides to_latex()' );

ok( defined $ms->to_latex(), 'to_latex() runs.' );


