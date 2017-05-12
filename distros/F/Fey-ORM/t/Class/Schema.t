use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Fey::ORM::Test qw( schema );
use Test::Fatal;

my $Schema = schema();

## no critic (Modules::ProhibitMultiplePackages)
{
    package Schema;

    use Fey::ORM::Schema;

    has_schema $Schema;
}

ok( Schema->meta()->_has_schema(), 'meta()->_has_schema() is true' );
is(
    Schema->Schema()->name(), $Schema->name(),
    'Schema() returns expected schema'
);
isa_ok( Schema->DBIManager(), 'Fey::DBIManager' );
is(
    Schema->SQLFactoryClass(), 'Fey::SQL',
    'SQLFactoryClass() is Fey::SQL'
);
ok(
    Schema->isa('Fey::Object::Schema'),
    q{Schema->isa('Fey::Object::Schema')}
);

is(
    Fey::Meta::Class::Schema->ClassForSchema($Schema),
    'Schema',
    'ClassForSchema() return Schema as class name'
);

{
    package Schema2;

    use Fey::ORM::Schema;

    ::like(
        ::exception { has_schema $Schema },
        qr/associate the same schema with multiple classes/,
        'cannot associate the same schema with multiple classes'
    );
}

done_testing();
