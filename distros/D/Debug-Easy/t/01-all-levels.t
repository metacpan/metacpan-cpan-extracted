#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Term::ANSIColor;
use Test::More tests => 115; # 115

BEGIN {
    use_ok('Debug::Easy') || print "Bail out! Can't load Debug::Easy!\n";
}

diag("\n" . colored(['cyan on_black'], q{ _______        _   _              }));
diag(colored(['cyan on_black'], q{|__   __|      | | (_)             }));
diag(colored(['cyan on_black'], q{   | | ___  ___| |_ _ _ __   __ _  }));
diag(colored(['cyan on_black'], q{   | |/ _ \/ __| __| | '_ \ / _` | }));
diag(colored(['cyan on_black'], q{   | |  __/\__ \ |_| | | | | (_| | }));
diag(colored(['cyan on_black'], q{   |_|\___||___/\__|_|_| |_|\__, | }));
diag(colored(['cyan on_black'], q{                             __/ | }));
diag(colored(['cyan on_black'], q{                            |___/  }));

my @LogLevel = qw( ERR WARN NOTICE INFO DEBUG DEBUGMAX );
my @CodeLevel = ('[ ERROR ]', '[WARNING]', '[NOTICE ]', '[ INFO  ]', '[ DEBUG ]', '[-DEBUG-]');

# Legacy "debug" code is used for testing only.  It is not recommended you use "debug" in your code.

SKIP: {

    skip 'Perl version < 5.10 skipping tests', 114 if ($] < 5.010000);

    my $stderr;

    open(OUTPUT, '>', \$stderr);
    foreach my $LEVEL (0 .. 5) {
        my $debug = Debug::Easy->new('LogLevel' => $LogLevel[$LEVEL], 'Color' => 1, 'FileHandle' => \*OUTPUT);
        isa_ok($debug, 'Debug::Easy');

        foreach my $count (0 .. 5) {
            $stderr = '';
            if ($count <= $LEVEL) {
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
    } ## end foreach my $LEVEL (0 .. 5)
} ## end SKIP:
