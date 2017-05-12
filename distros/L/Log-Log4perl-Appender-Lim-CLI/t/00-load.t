#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Log::Log4perl' ) || print "Bail out!\n";
    use_ok( 'Log::Log4perl::Appender::Lim::CLI' ) || print "Bail out!\n";
}

diag( "Testing Log::Log4perl::Appender::Lim::CLI $Log::Log4perl::Appender::Lim::CLI::VERSION, Perl $], $^X" );
