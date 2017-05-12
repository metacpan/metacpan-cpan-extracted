#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
   use_ok( 'Log::Log4perl::Appender::DBIx::Class' );
}

diag( "Testing Log::Log4perl::Appender::DBIx::Class $Log::Log4perl::Appender::DBIx::Class::VERSION, Perl $], $^X" );
