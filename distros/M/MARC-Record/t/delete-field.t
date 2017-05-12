use strict;
use warnings;
use Test::More tests => 4;
use MARC::Record;

my $record = MARC::Record->new();
$record->append_fields(MARC::Field->new('035', '', '', 'a' => 'Foo'));
$record->append_fields(MARC::Field->new('035', '', '', 'a' => 'Bar'));
$record->append_fields(MARC::Field->new('035', '', '', 'a' => 'Baz'));


my @original_035s = $record->field('035');
is scalar(@original_035s), 3, 'found 3 035 fields';

my @delete_035s = @original_035s[1..2];
is scalar(@delete_035s), 2, 'going to delete last 2 035 fields';
$record->delete_fields(@delete_035s);

# now should have just one 035
my @new_035s = $record->field('035');
is scalar(@new_035s), 1, 'found 1 035 field';
is $new_035s[0]->subfield('a'), 'Foo', 'got the right 035';

