#!perl
use strict;
use warnings;

use Test::More tests => 5;

{
    package TestPackage1;
    use Log::Log4perl::Lazy;
    our @called;

    sub test_sub {
        my $level = shift;
        push @called, $level;
        return 'called';
    }

    sub test_log1 {
        TRACE 'Trace: '.test_sub('trace');
        DEBUG 'Debug: '.test_sub('debug');
        INFO  'Info : '.test_sub('info' );
        WARN  'Warn : '.test_sub('warn' );
        ERROR 'Error: '.test_sub('error');
        FATAL 'Fatal: '.test_sub('fatal');
    };
}

{
    package TestPackage2;
    use Log::Log4perl qw(:easy); # DEBUG etc. are defined here
    use Log::Log4perl::Lazy;     # DEBUG etc. are redefined, which is ok
    our @called;

    sub test_sub {
        my $level = shift;
        push @called, $level;
        return 'called';
    }

    sub test_log2 {
        TRACE 'Trace: '.test_sub('trace');
        DEBUG 'Debug: '.test_sub('debug');
        INFO  'Info : '.test_sub('info' );
        WARN  'Warn : '.test_sub('warn' );
        ERROR 'Error: '.test_sub('error');
        FATAL 'Fatal: '.test_sub('fatal');
    };
}

package main;
use Log::Log4perl;
use Test::Output;

Log::Log4perl->easy_init({
    category => 'TestPackage1',
    level => $Log::Log4perl::INFO,
    layout => '%F{1} %M - %m%n',
}, {
    category => 'TestPackage2',
    level => $Log::Log4perl::ERROR,
    layout => '%F{1} %M - %m%n',
});

(my $file = __FILE__) =~ s{^.*/}{};

stderr_is \&TestPackage1::test_log1, <<END;
$file TestPackage1::test_log1 - Info : called
$file TestPackage1::test_log1 - Warn : called
$file TestPackage1::test_log1 - Error: called
$file TestPackage1::test_log1 - Fatal: called
END

is_deeply \@TestPackage1::called, [
    'info',
    'warn',
    'error',
    'fatal',
];

stderr_is \&TestPackage2::test_log2, <<END;
$file TestPackage2::test_log2 - Error: called
$file TestPackage2::test_log2 - Fatal: called
END

is_deeply \@TestPackage2::called, [
    'error',
    'fatal',
];

{
    package TestPackage3;
    use Test::More;
    eval "use Log::Log4perl::Lazy qw(invalid);";
    cmp_ok $@, '=~', qr/"invalid" is not exported/;
}
