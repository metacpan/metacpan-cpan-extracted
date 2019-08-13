use strict;
use warnings;
use Data::Dumper;
use Test::Exception;
use Test::More tests => 5;

require_ok('Geoffrey::Changelog::None');
use_ok 'Geoffrey::Changelog::None';

my $o_none = Geoffrey::Changelog::None->new();

is(
    Data::Dumper->new([$o_none->tpl_main])->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new([{
                changelogs => ['01'],
                postfix    => 'end',
                prefix     => 'smpl',
                templates  => [{
                        columns => [{
                                default    => 'inc',
                                name       => 'id',
                                notnull    => 1,
                                primarykey => 1,
                                type       => 'integer',
                            }
                        ],
                        name => 'tpl_std',
                    }]}]
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'changelog_table sub test'
);

is(
    Data::Dumper->new($o_none->tpl_sub)->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    Data::Dumper->new([{
                author => 'Mario Zieschang',
                entries =>
                    [{columns => [], name => 'client', template => 'tpl_std', action => 'table.add',}],
                id => '001.01-maz',
            }]
    )->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'changelog_type sub test'
);

my $hr_changeset = {templates => {test => {columns => []}}};
is(
    Data::Dumper->new([$o_none->from_hash(1)->load($hr_changeset)])->Indent(0)->Terse(1)->Deparse(1)
        ->Sortkeys(1)->Dump,
    Data::Dumper->new([$hr_changeset])->Indent(0)->Terse(1)->Deparse(1)->Sortkeys(1)->Dump,
    'changelog_type sub test'
);
