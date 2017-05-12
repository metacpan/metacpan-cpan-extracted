use strict;
use warnings;

use Test::More tests => 4;

use IO::Buffered;

# TODO: Add ->write_format() sub to all buffer types, write in buffer format

my $buffer = new IO::Buffered(Size => ["n", 0]);

$buffer->write(pack("n", 6)."Data10".pack("n", 6)."Data1");
if(my @records = $buffer->read()) {
    is_deeply(\@records, ['Data10'], "Got first record Data1");
} else {
    fail "Did not get back any records from read()";
}

$buffer->write("1".pack("n", 6)."Data12".pack("n", 6)."Data1");
if(my @records = $buffer->read_last()) {
    is_deeply(\@records, ['Data11', 'Data12', 'Data1'], 
        "Got all records with read_last()");
} else {
    fail "Did not get back any records";
}

is($buffer->read_last(), 0, "Empty result from read_last");
is($buffer->read(), 0, "Empty result from read");

