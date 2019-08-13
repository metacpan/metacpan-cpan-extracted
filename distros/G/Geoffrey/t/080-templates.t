use Test::More tests => 6;

use utf8;
use 5.010;
use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;

require_ok('Geoffrey::Template');
use_ok 'Geoffrey::Template';

my $object = new_ok('Geoffrey::Template');

$object->load_templates(
    [
        {
            name    => 'tpl_minimal',
            columns => [
                {
                    name       => 'id',
                    type       => 'integer',
                    notnull    => 1,
                    primarykey => 1,
                    default    => 'autoincrement',
                },
                { name => 'active', type => 'bool', default => 1, }
            ]
        },
        {
            name     => 'tpl_std',
            template => 'tpl_minimal',
            columns  => [
                {
                    name    => 'name',
                    type    => 'varchar',
                    notnull => 1,
                    default => 'current',
                },
                {
                    name    => 'flag',
                    type    => 'timestamp',
                    default => 'current',
                    notnull => 1,
                }
            ]
        }
    ]
);
is(
    Data::Dumper->new( [ $object->template('tpl_std') ] )->Indent(0)->Terse(1)
      ->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [
            [
                {
                    default    => 'autoincrement',
                    name       => 'id',
                    notnull    => 1,
                    primarykey => 1,
                    type       => 'integer'
                },
                { default => 1, name => 'active', type => 'bool' },
                {
                    default => 'current',
                    name    => 'name',
                    notnull => 1,
                    type    => 'varchar'
                },
                {
                    default => 'current',
                    name    => 'flag',
                    notnull => 1,
                    type    => 'timestamp'
                }
            ]
        ]
      )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List sequence test'
);
is(
    Data::Dumper->new( [ $object->template('tpl_minimal') ] )->Indent(0)->Terse(1)
      ->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new(
        [
            [
                {
                    default    => 'autoincrement',
                    name       => 'id',
                    notnull    => 1,
                    primarykey => 1,
                    type       => 'integer'
                },
                { 'default' => 1, 'name' => 'active', 'type' => 'bool' }
            ]
        ]
      )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'List sequence test'
);

throws_ok {
    $object->load_templates(
        [
            {
                name    => 'tpl_minimal',
                columns => [
                    {
                        name       => 'id',
                        type       => 'integer',
                        notnull    => 1,
                        primarykey => 1,
                        default    => 'autoincrement',
                    },
                    { name => 'active', type => 'bool', default => 1, }
                ]
            },
            { name => 'tpl_std', template => 'tpl_minimal_wrong', }
        ]
    );
}
'Geoffrey::Exception::Template::NotFound', 'Wrong template thrown';
