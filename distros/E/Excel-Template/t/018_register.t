use strict;

use Test::More tests => 15;

use lib 't';
use mock;
mock::reset;

my $CLASS = 'Excel::Template';
use_ok( $CLASS );

{
    local $^W=0;
    ok( !$CLASS->register(), "Must pass in class, name, and isa" );
    ok( !$CLASS->register( class => 'Register_018' ), "Must pass in class, name, and isa" );
    ok( !$CLASS->register( name => 'header' ), "Must pass in class, name, and isa" );
    ok( !$CLASS->register( isa => 'cell' ), "Must pass in class, name, and isa" );
    ok( !$CLASS->register( class => 'Register_018', isa => 'cell' ), "Must pass in class, name, and isa" );
    ok( !$CLASS->register( class => 'Register_018', name => 'header' ), "Must pass in class, name, and isa" );
    ok( !$CLASS->register( name => 'header', isa => 'cell' ), "Must pass in class, name, and isa" );

    eval {
        $CLASS->register(
            class => 'NOT::A::CLASS',
            name => 'not_a_node',
            isa => 'cell',
        );
    };
    like( $@, qr/Cannot find or compile/, "Verify registering a non-existent class fails" );

    ok(
        !$CLASS->register(
            class => 'NOT::A::CLASS',
            name => 'cell',
            isa => 'row',
        ), "Cannot add a nodename we already have",
    );

    ok(
        !$CLASS->register(
            class => 'NOT::A::CLASS',
            name => 'new_node',
            isa => 'not_a_node',
        ), "Cannot inherit from a nodename we don't have",
    );
}

ok(
    $CLASS->register(
        class => 'Register_018',
        name => 'header',
        isa => 'cell',
    ), "Register Register_018 class",
);

my $object = $CLASS->new(
    file => \*DATA,
);
isa_ok( $object, $CLASS );

ok( $object->write_file( 'filename' ), 'Something returned' );

my @calls = mock::get_calls;
is( join( $/, @calls, '' ), <<__END_EXPECTED__, 'Calls match up' );
Spreadsheet::WriteExcel::new( 'filename' )
Spreadsheet::WriteExcel::add_format( '' )
Spreadsheet::WriteExcel::add_worksheet( '' )
Spreadsheet::WriteExcel::Worksheet::new( '' )
Spreadsheet::WriteExcel::add_format( 'align', 'center', 'bold', '1' )
Spreadsheet::WriteExcel::Worksheet::write( '0', '0', 'test', '2' )
Spreadsheet::WriteExcel::close( '' )
__END_EXPECTED__

__DATA__
<workbook>
  <worksheet>
    <header text="test" />
  </worksheet>
</workbook>
