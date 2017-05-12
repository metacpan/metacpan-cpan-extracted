use strict;
use warnings;
use Test::More tests => 3;
use MARC::Record;

my $record = MARC::Record->new();
$record->append_fields(MARC::Field->new('035', '', '', 'a' => 'Foo'));
$record->append_fields(MARC::Field->new('035', '', '', 'a' => 'Bar'));
$record->append_fields(MARC::Field->new('035', '', '', 'a' => 'Baz'));


my @original_035s = $record->field('035');
is scalar(@original_035s), 3, 'found 3 035 fields';

$original_035s[0]->set_tag('100');

my @new_100 = $record->field('100');
is scalar(@new_100), 1, 'found 1 new 100 field';

@original_035s = $record->field('035');
is scalar(@original_035s), 2, 'found 2 035 fields';

