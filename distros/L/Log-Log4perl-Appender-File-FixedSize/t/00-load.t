#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Log4perl::Appender::File::FixedSize' ) || print "Bail out!\n";
}

diag( "Testing Log::Log4perl::Appender::File::FixedSize $Log::Log4perl::Appender::File::FixedSize::VERSION, Perl $], $^X" );
