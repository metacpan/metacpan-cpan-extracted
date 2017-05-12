use strict;
use JCONF::Writer;
use Test::More;

my $writer = JCONF::Writer->new;
ok(!$writer->from_hashref([]), "from_hashref([])");
isa_ok($writer->last_error, 'JCONF::Writer::Error');

$writer = JCONF::Writer->new(autodie => 1);
ok(!eval { $writer->from_hashref("HASH") }, "from_hashref('HASH') with autodie enabled");
isa_ok($@, 'JCONF::Writer::Error');

done_testing;
