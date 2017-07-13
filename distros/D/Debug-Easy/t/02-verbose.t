#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 20;

BEGIN {
    use_ok('Debug::Easy') || print "Bail out! Can't load Debug::Easy!\n";
}

$| = 1;

my @LogLevel = qw( ERR WARN NOTICE INFO DEBUG DEBUGMAX );
my @CodeLevel = ('[ ERROR ]', '[WARNING]', '[NOTICE ]', 'Message Test', '[ DEBUG ]', '[-DEBUG-]');

SKIP: {

    skip 'Perl version < 5.10 skipping tests', 19 if ($] < 5.010000);

    my $stderr;

    open(OUTPUT, '>', \$stderr);

    my $debug = Debug::Easy->new('LogLevel' => 'VERBOSE', 'Color' => 1, 'FileHandle' => \*OUTPUT);
    isa_ok($debug, 'Debug::Easy');

    foreach my $count (0 .. 5) {
        $stderr = '';
        if ($count < 4) {
            $debug->debug( $LogLevel[$count], $LogLevel[$count] . ' Single Line Message Test');
            like($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Single Line Scalar Message Test');
            $stderr = '';
            $debug->debug( $LogLevel[$count], $LogLevel[$count] . "Multi-Line Scalar\nMessage Test");
            like($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Scalar Message Test');
            $stderr = '';
            $debug->debug( $LogLevel[$count], [$LogLevel[$count] . ' Multi-Line', 'Array', 'Message Test']);
            like($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Array Message Test');
        } else {
            $debug->debug( $LogLevel[$count], $LogLevel[$count] . ' Single Line Message Test');
            unlike($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Single Line Scalar Message Test');
            $stderr = '';
            $debug->debug( $LogLevel[$count], $LogLevel[$count] . "Multi-Line Scalar\nMessage Test");
            unlike($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Scalar Message Test');
            $stderr = '';
            $debug->debug( $LogLevel[$count], [$LogLevel[$count] . ' Multi-Line', 'Array', 'Message Test']);
            unlike($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Array Message Test');
        }
    } ## end foreach my $count (0 .. 5)
} ## end SKIP:

