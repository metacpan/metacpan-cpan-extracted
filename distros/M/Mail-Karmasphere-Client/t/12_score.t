use strict;
use warnings;
use blib;

use Test::More tests => 21;

use_ok('Mail::Karmasphere::Parser::Score::IP4');

use IO::File;
my $io = bless \*DATA, 'IO::File';
 
my $parser = new Mail::Karmasphere::Parser::Score::IP4(
	fh => $io,
		);
my $record;

for (0..2) {
	$record = $parser->parse;
	ok(defined $record, 'Got a record');
	is($record->identity, '123.45.6.7');
	is($record->value, 1000);
	is($record->data, undef);
}

for (0..0) {
	$record = $parser->parse;
	ok(defined $record, 'Got a record');
	is($record->identity, '123.45.6.7');
	is($record->value, -1000);
	is($record->data, undef);
}

for (0..0) {
	$record = $parser->parse;
	ok(defined $record, 'Got a record');
	is($record->identity, '43.2.1.7');
	is($record->value, 1000);
	is($record->data, "arse foo");
}

__DATA__
# comment 0
123.45.6.7
# comment 1
123.45.6.7,1000
# comment 2
123.45.6.7,1000
# comment 3
123.45.6.7, -1000
# comment 4
43.2.1.7,,"arse foo"
