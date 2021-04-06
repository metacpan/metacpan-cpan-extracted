#!/usr/bin/perl

# DO NOT USE THIS AS A TEMPLATE FOR CODING!  This uses an older and now
# defunct method of calling the debug methods.  I chose to do it this way
# Simply because it makes it easier programmatically.
#
# This script is intended to demonstrate how the OUTPUT differs depending
# on the logging level.

use strict;

use Debug::Easy qw(@Levels);

my @LogLevel  = @Levels;
my @CodeLevel = ('[ ERROR ]', '[WARNING]', '[NOTICE ]', '[ INFO  ]', '[ DEBUG ]', '[DEBUGMX]');
my %SomeHash  = (
    'Thiskey' => 'ThisValue',
    'ThatKey' => 'ThatValue',
    'SomeKey' => 'SomeValue'
);

my $size = scalar(@Levels) - 1;

foreach my $LEVEL (0 .. $size) {
    print STDERR "\n---- Showing When Log Level is Set To $LogLevel[$LEVEL] ----\n\n";
    my $debug = Debug::Easy->new('LogLevel' => $LogLevel[$LEVEL], 'Color' => 1, 'Padding' => -5);

    foreach my $count (0 .. $size) {
        my $method = ($LogLevel[$count] eq 'VERBOSE') ? 'INFO' : $LogLevel[$count];
        $debug->debug($method, $LogLevel[$count]  . ' Single Line Message Test');
        $debug->debug($method, $LogLevel[$count]  . " Multi-Line Scalar\nMessage Test");
        $debug->debug($method, [$LogLevel[$count] . ' Multi-Line', 'Array', 'Message Test']);
        $debug->DEBUGMAX(['DEBUGMAX - Data Dumper -',\@LogLevel,\@CodeLevel,\%SomeHash]);
        print STDERR "\n";
    }
}

exit(0);

sub subroutine {
    my $variable = shift;
    
    my $another_variable = 'Wow, this is a nifty string!';
    return(1);
}
