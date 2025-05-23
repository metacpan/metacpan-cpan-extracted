use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Fey.pm',
    'lib/Fey/Column.pm',
    'lib/Fey/Column/Alias.pm',
    'lib/Fey/Exceptions.pm',
    'lib/Fey/FK.pm',
    'lib/Fey/FakeDBI.pm',
    'lib/Fey/Literal.pm',
    'lib/Fey/Literal/Function.pm',
    'lib/Fey/Literal/Null.pm',
    'lib/Fey/Literal/Number.pm',
    'lib/Fey/Literal/String.pm',
    'lib/Fey/Literal/Term.pm',
    'lib/Fey/NamedObjectSet.pm',
    'lib/Fey/Placeholder.pm',
    'lib/Fey/Role/ColumnLike.pm',
    'lib/Fey/Role/Comparable.pm',
    'lib/Fey/Role/Groupable.pm',
    'lib/Fey/Role/HasAliasName.pm',
    'lib/Fey/Role/IsLiteral.pm',
    'lib/Fey/Role/Joinable.pm',
    'lib/Fey/Role/MakesAliasObjects.pm',
    'lib/Fey/Role/Named.pm',
    'lib/Fey/Role/Orderable.pm',
    'lib/Fey/Role/SQL/Cloneable.pm',
    'lib/Fey/Role/SQL/HasBindParams.pm',
    'lib/Fey/Role/SQL/HasLimitClause.pm',
    'lib/Fey/Role/SQL/HasOrderByClause.pm',
    'lib/Fey/Role/SQL/HasWhereClause.pm',
    'lib/Fey/Role/SQL/ReturnsData.pm',
    'lib/Fey/Role/Selectable.pm',
    'lib/Fey/Role/SetOperation.pm',
    'lib/Fey/Role/TableLike.pm',
    'lib/Fey/SQL.pm',
    'lib/Fey/SQL/Delete.pm',
    'lib/Fey/SQL/Except.pm',
    'lib/Fey/SQL/Fragment/Join.pm',
    'lib/Fey/SQL/Fragment/Where/Boolean.pm',
    'lib/Fey/SQL/Fragment/Where/Comparison.pm',
    'lib/Fey/SQL/Fragment/Where/SubgroupEnd.pm',
    'lib/Fey/SQL/Fragment/Where/SubgroupStart.pm',
    'lib/Fey/SQL/Insert.pm',
    'lib/Fey/SQL/Intersect.pm',
    'lib/Fey/SQL/Select.pm',
    'lib/Fey/SQL/Union.pm',
    'lib/Fey/SQL/Update.pm',
    'lib/Fey/SQL/Where.pm',
    'lib/Fey/Schema.pm',
    'lib/Fey/Table.pm',
    'lib/Fey/Table/Alias.pm',
    'lib/Fey/Types.pm',
    'lib/Fey/Types/Internal.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Column-guess-type.t',
    't/Column.t',
    't/Column/Alias.t',
    't/Exceptions.t',
    't/FK.t',
    't/FakeDBI.t',
    't/Literal-as-sql.t',
    't/Literal.t',
    't/NamedObjectSet.t',
    't/SQL-limit-clause.t',
    't/SQL-order-by-clause.t',
    't/SQL-where-clause.t',
    't/SQL.t',
    't/SQL/Delete-bind-params.t',
    't/SQL/Delete.t',
    't/SQL/Insert-bind-params.t',
    't/SQL/Insert.t',
    't/SQL/Select-bind-params.t',
    't/SQL/Select-clone.t',
    't/SQL/Select-from-clause.t',
    't/SQL/Select-group-by-clause.t',
    't/SQL/Select-having-clause.t',
    't/SQL/Select-select-clause.t',
    't/SQL/Set.t',
    't/SQL/Update-bind-params.t',
    't/SQL/Update.t',
    't/SQL/Where.t',
    't/Schema-memory-cycle.t',
    't/Schema.t',
    't/Table.t',
    't/Table/Alias.t'
);

notabs_ok($_) foreach @files;
done_testing;
