#/usr/bin/env perl
use Test::More;
use Test::Warn;
use Test::Fatal;
use Data::Dumper;
use Test::Exception;
use Test::NoWarnings;
use Test::Output;
use Path::Tiny;
use Test::File::ShareDir::Dist { 'Log-Log4perl-Shortcuts' => 'config/' };
use Test::File::ShareDir::Module { 'Log::Log4perl::Shortcuts' => 'config/' };
use lib '/Users/stevedondley/perl/modules/Log-Log4perl-Shortcuts/lib';
use Log::Log4perl::Shortcuts qw(:all);
diag( "Running my tests" );





my $tests = 2; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;
lives_ok { get_log_config(); } 'can get log level';
