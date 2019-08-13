use Test::More tests => 13;

use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;
use Geoffrey::Converter::SQLite;

require_ok('DBI');
use_ok 'DBI';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

require_ok('Geoffrey::Action::View');
use_ok 'Geoffrey::Action::View';

{

    package Test::Mock::Geoffrey::Converter::SQLite;
    use parent 'Geoffrey::Role::Converter';

    sub new {
        my $class = shift;
        my $self  = $class->SUPER::new(@_);
        return bless $self, $class;
    }
    sub view { Geoffrey::Converter::SQLite::View->new; }
}

my $dbh = DBI->connect("dbi:SQLite:database=.tmp.sqlite")
    or plan skip_all => $DBI::errstr;
my $converter = Geoffrey::Converter::SQLite->new();
my $object = Geoffrey::Action::View->new( converter => $converter, dbh => $dbh );

can_ok( 'Geoffrey::Action::View', @{ [ 'add', 'alter', 'drop' ] } );
isa_ok( $object, 'Geoffrey::Action::View' );

is( $object->add(
        {   name => 'view_test',
            as =>
                'SELECT "user".pass, "user".salt, "user".locale, "user".last_login FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
        }
    ),
    'CREATE VIEW view_test AS SELECT "user".pass, "user".salt, "user".locale, "user".last_login FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id',
    'Creating view failed'
);
is( Data::Dumper->new(
        $object->alter(
            {   name => 'view_test',
                as =>
                    'SELECT "user".active, "user".name, company.name AS company, client.id FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
            }
        )
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [   'DROP VIEW view_test',
            'CREATE VIEW view_test AS SELECT "user".active, "user".name, company.name AS company, client.id FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
        ]
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'Creating view failed'
);

is( Data::Dumper->new( $object->list_from_schema('main') )->Indent(0)->Terse(1)->Deparse(1)
        ->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [   {   name => 'view_client',
                sql =>
                    'CREATE VIEW view_client AS SELECT "user".guest, "user".pass, "user".salt, "user".locale, "user".last_login, "user".mail, "user".client, "user".flag, "user".active, "user".name, company.name AS company, client.id FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
            },
            {   name => 'view_test',
                sql =>
                    'CREATE VIEW view_test AS SELECT "user".active, "user".name, company.name AS company, client.id FROM client, company, "user" WHERE client.id = company.id AND company.id = "user".id AND "user".id = client.id'
            }
        ]
        )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List indexes from schema'
);

is( $object->drop('view_test'), 'DROP VIEW view_test', 'Drop view failed' );

$dbh->disconnect();

throws_ok {
    Geoffrey::Action::View->new( converter => Test::Mock::Geoffrey::Converter::SQLite->new, )
        ->dryrun(1)->list_from_schema('main');
}
'Geoffrey::Exception::NotSupportedException::ListInformation', 'Add column thrown';
