#!perl 
use Test::More tests => 2;

BEGIN {
    use_ok('Env::Modify');
}

ok($Shell::GetEnv::VERSION ge '0.08_03', 'approved version of Shell::GetEnv');

diag( "Testing Env::Modify $Env::Modify::VERSION, Perl $], $^X" );

