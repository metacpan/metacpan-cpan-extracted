use strict;
use warnings;

use Test::More tests => 6;

use IO::Buffered;

my $buffer = new IO::Buffered(Last => 1);

$buffer->write("Data1\nData2");
is($buffer->buffer(), "Data1\nData2", "Buffer is set correctly");

my @records = $buffer->read();
is_deeply(\@records, [], "Got nothing as we only return on last");

$buffer->write("\nData3\nData4");
if(@records = $buffer->read_last()) {
    is_deeply(\@records, ["Data1\nData2\nData3\nData4"], 
        "Got all records with read_last()");
} else {
    fail "Did not get back any records";
}

is($buffer->buffer(), "", "Buffer is empty");
is($buffer->read_last(), 0, "Empty result from read_last");
is($buffer->read(), 0, "Empty result from read");
