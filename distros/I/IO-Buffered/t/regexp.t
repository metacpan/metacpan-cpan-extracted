use strict;
use warnings;

use Test::More tests => 4;

use IO::Buffered;

my $buffer = new IO::Buffered(Regexp => qr/(.*?)\n/, MaxSize => 100);

$buffer->write("Data1\nData2"); # $str is now "Data1\nData2"

if(my @records = $buffer->read()) { # $str is now "Data2"
    is_deeply(\@records, ['Data1'], "Got first record Data1");
} else {
    fail "Did not get back any records from read()";
}

$buffer->write("\nData3\nData4"); # $str is now "Data2\nData3\nData4"
if(my @records = $buffer->read_last()) { # $str is now ""
    is_deeply(\@records, ['Data2', 'Data3', 'Data4'], 
        "Got all records with read_last()");
} else {
    fail "Did not get back any records";
}

is($buffer->read_last(), 0, "Empty result as we have nothing in the queue");
is($buffer->read(), 0, "Empty result as we have nothing in the queue");

