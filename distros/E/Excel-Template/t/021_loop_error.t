BEGIN{ $^W = 0 }
use strict;

use Test::More tests => 4;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

my $object = $CLASS->new(
    file => \*DATA,
);
isa_ok( $object, $CLASS );

ok(
    $object->param( 
        test => [
            { value => 1 },
            { value => 2 },
            [ value => 3 ],
        ],
    ),
    'Parameters set',
);

ok( !$object->write_file( 'filename' ), 'Failed to write file' );

__DATA__
<workbook>
  <worksheet>
    <loop name="test">
      <cell text="$value" />
    </loop>
  </worksheet>
</workbook>
