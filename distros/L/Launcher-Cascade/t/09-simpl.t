#!perl -T

use Test::More;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($FATAL);

use Launcher::Cascade::Simple;

my %value = qw( a 0 b 0 c 0 );
my $L = new Launcher::Cascade::Simple
    -name        => 'Test Launcher',
    -launch_hook => sub { 1 },
    -test_hook   => [
        sub { ++$value{a} == 2 || undef },
        sub { ++$value{b} == 3 || undef },
        sub { ++$value{c} == 4 || undef },
    ],
    -max_retries => 10,
;

my @test = (
    { qw( a 1 b 0 c 0 ) },
    { qw( a 2 b 1 c 0 ) },
    { qw( a 2 b 2 c 0 ) },
    { qw( a 2 b 3 c 1 ) },
    { qw( a 2 b 3 c 2 ) },
    { qw( a 2 b 3 c 3 ) },
    { qw( a 2 b 3 c 4 ) },
);

my @test2 = (
    { qw( a 1 b 0 c 4 ) },
    { qw( a 2 b 1 c 4 ) },
    { qw( a 2 b 2 c 4 ) },
    { qw( a 2 b 3 c 5 ) },
);

plan tests => 3 * (@test + @test2) + 2;

while ( !$L->has_run() ) {
    $L->run(); $L->check_status();
    if ( my $test_href = shift @test ) {
        foreach ( sort keys %$test_href ) {
            is($value{$_}, $test_href->{$_}, "value $_ is " . $test_href->{$_});
        }
    }
}
ok($L->is_success(), 'success');

$L->reset();
$value{a} = $value{b} = 0;

while ( !$L->has_run() ) {
    $L->run(); $L->check_status();
    if ( my $test_href = shift @test2 ) {
        foreach ( sort keys %$test_href ) {
            is($value{$_}, $test_href->{$_}, "value $_ is " . $test_href->{$_});
        }
    }
}
ok($L->is_failure(), 'failed');

