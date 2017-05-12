use strict;
use warnings;

use Test::More tests => 6;
use EntityModel::Web::Header;

my $hdr = new_ok('EntityModel::Web::Header');
$hdr = new_ok('EntityModel::Web::Header' => [
	name	=> 'Host',
	value	=> 'example.com',
]);
is($hdr->name, 'Host', 'name is correct');
is($hdr->value, 'example.com', 'value is correct');
is($hdr->value('example2.com'), $hdr, 'changing value works');
is($hdr->value, 'example2.com', 'new value has been set');

