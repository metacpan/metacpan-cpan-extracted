#!perl -T

use Test::More tests => 6;

use Ed2k_link;

my $fr_l1 = Ed2k_link -> from_link('ed2k://|file|eMule0.49c.zip|2868871|0F88EEFA9D8AD3F43DABAC9982D2450C|/');
ok(defined $fr_l1, 'object was created');
ok($fr_l1 -> isa('Ed2k_link'), "and it's a right class");
ok($fr_l1 -> ok, "object thinks it's ok");
is($fr_l1 -> filename, "eMule0.49c.zip", "filename");
is($fr_l1 -> escaped_filename, "eMule0.49c.zip", "escaped filename");
is($fr_l1 -> filesize, 2868871, 'filesize');
