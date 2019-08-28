use DBI;
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Test::Exception;

require_ok('Geoffrey::Converter::Pg');
use_ok 'Geoffrey::Converter::Pg';

my $o_converter = Geoffrey::Converter::Pg->new();
dies_ok { $o_converter->check_version('3.0') } 'underneath min version expecting to die';
is($o_converter->check_version('9.1'), 1, 'min version check');
is($o_converter->check_version('9.6'), 1, 'min version check');

require_ok('Geoffrey::Action::Constraint::Default');
my $o_pg = new_ok('Geoffrey::Action::Constraint::Default', ['converter', $o_converter]);


is(
    Data::Dumper->new([$o_converter->defaults])->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new([{current_timestamp => 'CURRENT_TIMESTAMP', autoincrement => 'SERIAL',}])->Indent(0)->Terse(1)
        ->Deparse(1)->Sortkeys(1)->Dump,
    'plain defaults call test'
);

throws_ok { $o_converter->type(); } 'Geoffrey::Exception::RequiredValue::ColumnType',
    'plain type call test without param';

is($o_converter->type({type => 'bigint'}), 'bigint', 'plain type call test without param');
is(scalar keys %{$o_converter->types}, 70, 'plain types call test');
is(
    $o_converter->select_get_table,
    q~SELECT t.table_name AS table_name FROM information_schema.tables t WHERE t.table_type = 'BASE TABLE' AND t.table_schema = ? AND t.table_name = ?~,
    'plain select_get_table call test'
);
is($o_converter->convert_defaults({type => 'bit'}), undef, 'plain convert_defaults call test');
is($o_converter->convert_defaults({default => 1, type => 'bit'}), '1::bit', 'plain convert_defaults call test');
is($o_converter->parse_default('test::bit'), 'test::bit', 'plain parse_default call test');
is($o_converter->can_create_empty_table,     1,           'plain can_create_empty_table call test');

is(
    Data::Dumper->new(
        $o_converter->colums_information([{
                    sql => q~CREATE TABLE zbpa_menu_script (
                menu_id numeric(11,0) NOT NULL,
                script_id numeric(11,0) NOT NULL,
                del_flag character varying(14) NOT NULL,
                last_change_user character varying(8) NOT NULL,
                last_change_date character varying(14) NOT NULL
            )~
                }])
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new([])->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'plain colums_information call test'
);

is(
    Data::Dumper->new($o_converter->index_information([]))->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new([])->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'plain index_information call test'
);


is(
    Data::Dumper->new($o_converter->view_information([]))->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new([])->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'plain view_information call test'
);


ok($o_converter->constraints->isa('Geoffrey::Converter::Pg::Constraints'), 'plain constraints call test');
ok($o_converter->index->isa('Geoffrey::Converter::Pg::Index'),             'plain index call test');
ok($o_converter->table->isa('Geoffrey::Converter::Pg::Tables'),            'plain table call test');
ok($o_converter->view->isa('Geoffrey::Converter::Pg::View'),               'plain view call test');
ok($o_converter->foreign_key->isa('Geoffrey::Converter::Pg::ForeignKey'),  'plain foreign_key call test');
ok($o_converter->trigger->isa('Geoffrey::Converter::Pg::Trigger'),         'plain trigger call test');
ok($o_converter->primary_key->isa('Geoffrey::Converter::Pg::PrimaryKey'),  'plain primary_key call test');
ok($o_converter->unique->isa('Geoffrey::Converter::Pg::UniqueIndex'),      'plain unique call test');
ok($o_converter->sequence->isa('Geoffrey::Converter::Pg::Sequence'),       'plain sequence call test');

done_testing;