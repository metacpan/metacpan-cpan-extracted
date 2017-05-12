#!perl -T

use Test::More tests => 6;

BEGIN { use_ok( 'Moose' ) }
BEGIN { use_ok( 'HTML::TreeBuilderX::ASP_NET::Types' ) }
BEGIN { use_ok( 'HTML::TreeBuilderX::ASP_NET' ); }
BEGIN { use_ok( 'HTML::Element' ) }
BEGIN { use_ok( 'HTML::TreeBuilder' ) }
BEGIN { use_ok( 'MooseX::Traits' ) }

diag( "Testing HTML::TreeBuilderX::ASP_NET $HTML::TreeBuilderX::ASP_NET::VERSION, Perl $], $^X" );
