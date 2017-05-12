use strict;
use warnings;

use Test::More tests => 4;

use IO::Buffered;

my $buffer = new IO::Buffered(FixedSize => 6);

$buffer->write("Data10Data1"); # $str is now "Data10\nData1"

if(my @records = $buffer->read()) { # $str is now "Data1"
    is_deeply(\@records, ['Data10'], "Got first record Data1");
} else {
    fail "Did not get back any records from read()";
}

$buffer->write("1Data12Data1"); # $str is now "Data11\nData12\nData1"
if(my @records = $buffer->read_last()) { # $str is now ""
    is_deeply(\@records, ['Data11', 'Data12', 'Data1'], 
        "Got all records with read_last()");
} else {
    fail "Did not get back any records";
}

is($buffer->read_last(), 0, "Empty result as we have nothing in the queue");
is($buffer->read(), 0, "Empty result as we have nothing in the queue");

