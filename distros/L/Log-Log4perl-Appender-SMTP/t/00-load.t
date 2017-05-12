#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

BEGIN {
    use_ok( 'Log::Log4perl::Appender::SMTP' ) || print "Bail out!\n";
}

diag( "Testing Log::Log4perl::Appender::SMTP $Log::Log4perl::Appender::SMTP::VERSION, Perl $], $^X" );

my $app = Log::Log4perl::Appender::SMTP->new(
	to => 'bugs@localhost',
	Host => 'smtp.perl.org',
);

ok (defined $app);
is $app->{to}, 'bugs@localhost';
is $app->{Host}, 'smtp.perl.org';
