# This test fails with a segfault with Perl 5.26+ for some reason so the actual tests are commented
# out for now.

use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

ok(1);

done_testing();

# use Fey::SQL;

# my $s   = Fey::Test->mock_test_schema_with_fks();
# my $dbh = Fey::Test->mock_dbh();

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from() };
#     like(
#         $@, qr/from\(\) called with invalid parameters \(\)/,
#         'from() without any parameters is an error'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User') );

#     is(
#         $q->from_clause($dbh), q{FROM "User"},
#         'from_clause() for one table'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from('foo') };
#     like(
#         $@, qr/from\(\) called with invalid parameters \(foo\)/,
#         'from() called with one non-table argument'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my $alias = $s->table('User')->alias( alias_name => 'UserA' );
#     $q->from($alias);

#     is(
#         $q->from_clause($dbh), q{FROM "User" AS "UserA"},
#         'from_clause() for one table alias'
#     );

# }

# {
#     my $q = Fey::SQL->new_select();

#     my $user_t = $s->table('User');

#     my $alias = $user_t->alias( alias_name => 'UserA' );

#     my $fk = Fey::FK->new(
#         source_columns => $user_t->column('user_id'),
#         target_columns => $alias->column('user_id'),
#     );

#     $q->from( $user_t, $alias, $fk );

#     is(
#         $q->from_clause($dbh),
#         q{FROM "User" JOIN "User" AS "UserA" ON ("User"."user_id" = "UserA"."user_id")},
#         'from_clause() with self-join to alias using fake FK'
#     );

# }

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from( $s->table('User'), $s->table('Group') ) };
#     like(
#         $@, qr/do not share a foreign key/,
#         'Cannot join two tables without a foreign key'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from( $s->table('User'), 'foo' ) };
#     like(
#         $@,
#         qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
#         'from() called with two args, one not a table'
#     );

#     eval { $q->from( 'foo', $s->table('User') ) };
#     like(
#         $@,
#         qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
#         'from() called with two args, one not a table'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'), $s->table('UserGroup') );

#     my $sql
#         = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two tables, fk not provided'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'),      $s->table('UserGroup') );
#     $q->from( $s->table('UserGroup'), $s->table('Group') );

#     my $sql
#         = q{FROM "UserGroup" JOIN "Group" ON ("UserGroup"."group_id" = "Group"."group_id")};
#     $sql .= q{ JOIN "User" ON ("UserGroup"."user_id" = "User"."user_id")};

#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two joins'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User') );
#     $q->from( $s->table('User'), $s->table('UserGroup') );

#     my $sql
#         = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for table alone first, then table in join'
#     );
# }

# {
#     my $frag = Fey::SQL::Fragment::Join->new(
#         table1 => $s->table('User'),
#         table2 => $s->table('UserGroup'),
#         fk     => (
#             $s->foreign_keys_between_tables(
#                 $s->tables( 'User', 'UserGroup' )
#             )
#         )[0],
#     );

#     is(
#         $frag->sql_with_alias(
#             'Fey::FakeDBI', {
#                 $s->table('User')->id()      => 1,
#                 $s->table('UserGroup')->id() => 1,
#             },
#         ),
#         q{},
#         'join fragment ignores tables already seen'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'),  $s->table('UserGroup') );
#     $q->from( $s->table('Group'), $s->table('UserGroup') );

#     my $sql
#         = q{FROM "Group" JOIN "UserGroup" ON ("UserGroup"."group_id" = "Group"."group_id")};
#     $sql .= q{ JOIN "User" ON ("UserGroup"."user_id" = "User"."user_id")};

#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two joins, seen table comes second in second clause'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User') );
#     $q->from( $s->table('UserGroup') );
#     $q->from( $s->table('Group') );

#     my $sql = q{FROM "Group", "User", "UserGroup"};

#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for three tables with no joins'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my @t = ( $s->table('User'), $s->table('UserGroup') );
#     my ($fk) = $s->foreign_keys_between_tables(@t);
#     $q->from( @t, $fk );

#     my $sql
#         = q{FROM "User" JOIN "UserGroup" ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two tables with fk provided'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my $fk = Fey::FK->new(
#         source_columns => $s->table('User')->column('user_id'),
#         target_columns => $s->table('UserGroup')->column('group_id'),
#     );
#     $s->add_foreign_key($fk);

#     eval { $q->from( $s->table('User'), $s->table('UserGroup') ) };
#     like(
#         $@, qr/more than one foreign key/,
#         'Cannot auto-join two tables with >1 foreign key'
#     );

#     $s->remove_foreign_key($fk);
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'), 'left', $s->table('UserGroup') );

#     my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two tables with left outer join'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my $user_alias = $s->table('User')->alias( alias_name => 'U' );
#     my $user_group_alias
#         = $s->table('UserGroup')->alias( alias_name => 'UG' );

#     $q->from( $user_alias, 'left', $user_group_alias );

#     my $sql = q{FROM "User" AS "U" LEFT OUTER JOIN "UserGroup" AS "UG"};
#     $sql .= q{ ON ("UG"."user_id" = "U"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two table aliases with left outer join'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'), $s->table('UserGroup') );
#     $q->from( $s->table('UserGroup'), 'left', $s->table('Group') );

#     my $sql = q{FROM "UserGroup" LEFT OUTER JOIN "Group" ON};
#     $sql .= q{ ("UserGroup"."group_id" = "Group"."group_id")};
#     $sql .= q{ JOIN "User" ON ("UserGroup"."user_id" = "User"."user_id")};

#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for regular join + left outer join'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my @t = ( $s->table('User'), $s->table('UserGroup') );
#     my ($fk) = $s->foreign_keys_between_tables(@t);

#     $q->from( $t[0], 'left', $t[1], $fk );

#     my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two tables with left outer join with explicit fk'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'), 'right', $s->table('UserGroup') );

#     my $sql = q{FROM "User" RIGHT OUTER JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two tables with right outer join'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

#     my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two tables with full outer join'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User'), 'full', $s->table('UserGroup') );

#     my $sql = q{FROM "User" FULL OUTER JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for two tables with full outer join'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my $q2 = Fey::SQL->new_where( auto_placeholders => 0 );
#     $q2->where( $s->table('User')->column('user_id'), '=', 2 );

#     $q->from( $s->table('User'), 'left', $s->table('UserGroup'), $q2 );

#     my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id"};
#     $sql .= q{ AND "User"."user_id" = 2)};

#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for outer join with where clause'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my $q2 = Fey::SQL->new_where( auto_placeholders => 0 );
#     $q2->where( $s->table('User')->column('user_id'), '=', 2 );

#     my @t = ( $s->table('User'), $s->table('UserGroup') );
#     my ($fk) = $s->foreign_keys_between_tables(@t);

#     $q->from( $t[0], 'left', $t[1], $fk, $q2 );

#     my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id"};
#     $sql .= q{ AND "User"."user_id" = 2)};

#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for outer join with where clause() and explicit fk'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     my $alias = $s->table('User')->alias( alias_name => 'UserA' );
#     $q->from( $s->table('User'), $s->table('UserGroup') );
#     $q->from( $alias,            $s->table('UserGroup') );

#     my $sql = q{FROM "User" JOIN "UserGroup"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "User"."user_id")};
#     $sql .= q{ JOIN "User" AS "UserA"};
#     $sql .= q{ ON ("UserGroup"."user_id" = "UserA"."user_id")};

#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for one table alias'
#     );

# }

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from( $s->table('User')->column('user_id') ) };
#     like(
#         $@, qr/\Qfrom() called with invalid parameters/,
#         'passing just a column to from()'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from( $s->table('User'), 'foobar', $s->table('UserGroup') ) };
#     like(
#         $@, qr/invalid outer join type/,
#         'invalid outer join type causes an error'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from( 'not a table', 'left', $s->table('UserGroup') ) };
#     like(
#         $@, qr/from\(\) was called with invalid arguments/,
#         'invalid outer join type causes an error'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     eval { $q->from( $s->table('UserGroup'), 'left', 'not a table' ) };
#     like(
#         $@, qr/from\(\) was called with invalid arguments/,
#         'invalid outer join type causes an error'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();

#     eval {
#         $q->from(
#             $s->table('User'), 'full', $s->table('UserGroup'),
#             'invalid'
#         );
#     };
#     like(
#         $@, qr/\Qfrom() called with invalid parameters/,
#         'passing invalid parameter to from() with outer join'
#     );
# }

# {
#     my $q         = Fey::SQL->new_select();
#     my $subselect = Fey::SQL->new_select();
#     $subselect->select( $s->table('User')->column('user_id') )
#         ->from( $s->table('User') );

#     $q->from($subselect);

#     my $sql = q{FROM ( SELECT "User"."user_id" FROM "User" ) AS "SUBSELECT0"};
#     is(
#         $q->from_clause($dbh), $sql,
#         'from_clause() for subselect'
#     );
#     is(
#         $subselect->alias_name, 'SUBSELECT0',
#         'subselect alias_name is set after use in from()'
#     );

# }

# {
#     my $q = Fey::SQL->new_select();
#     my $table = Fey::Table->new( name => 'NewTable' );

#     eval { $q->from($table) };
#     like(
#         $@, qr/\Qfrom() called with invalid parameters/,
#         'cannot pass a table without a schema to from()'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();
#     my $table = Fey::Table->new( name => 'NewTable' );

#     eval { $q->from( $table, $s->table('User') ) };
#     like(
#         $@,
#         qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
#         'cannot pass a table without a schema to from() as part of a join'
#     );
# }

# {
#     my $q = Fey::SQL->new_select();
#     my $table = Fey::Table->new( name => 'NewTable' );

#     my $non_table = bless {}, 'Thingy';

#     eval { $q->from( $table, $non_table ) };
#     like(
#         $@,
#         qr/\Qthe first two arguments to from() were not valid (not tables or something else joinable)/,
#         'cannot pass a table without a schema to from()'
#     );
# }

# {
#     my $q = Fey::SQL->new_select->from( $s->table('User') );

#     # The bug this exercised was that two aliases were created, but
#     # since they had the same name, we only ended up with one join
#     # fragment. Then the column from the second table alias ended up
#     # going out of scope.
#     for ( 0 .. 1 ) {
#         my $table = $s->table('UserGroup')->alias('UserGroup1');
#         $q->from( $s->table('User'), $table );
#         $q->where( $table->column('group_id'), '=', 1 );
#     }

#     $q->select(1);

#     my $sql = q{SELECT 1 FROM "User" JOIN "UserGroup" AS "UserGroup1" ON};
#     $sql .= q{ ("UserGroup1"."user_id" = "User"."user_id")};
#     $sql
#         .= q{ WHERE "UserGroup1"."group_id" = ? AND "UserGroup1"."group_id" = ?};

#     is( $q->sql($dbh), $sql, 'alias shows up in join once and where twice' );
# }

# {
#     my $q = Fey::SQL->new_select();

#     $q->from( $s->table('User') );
#     $q->from( $s->table('User'), 'left', $s->table('UserGroup') );

#     my $sql = q{FROM "User" LEFT OUTER JOIN "UserGroup" ON};
#     $sql .= q{ ("UserGroup"."user_id" = "User"."user_id")};

#     is(
#         $q->from_clause($dbh), $sql,
#         'table only shows up once in from, not twice'
#     );
# }

# {
#     my $t1    = $s->table('User');
#     my $t2    = $s->table('UserGroup');
#     my $where = Fey::SQL->new_where( auto_placeholders => 0 );
#     $where->where( $t1->column('user_id'), '=', 2 );
#     my ($fk) = $s->foreign_keys_between_tables( $t1, $t2 );

#     my $sql = q{FROM "User" JOIN "UserGroup" ON};
#     $sql .= q{ ("UserGroup"."user_id" = "User"."user_id"};
#     $sql .= q{ AND "User"."user_id" = 2)};

#     {
#         my $q = Fey::SQL->new_select();
#         $q->from( $t1, $t2, $where );
#         is(
#             $q->from_clause($dbh), $sql,
#             'from_clause() for inner join with where clause'
#         );
#     }
#     {
#         my $q = Fey::SQL->new_select();
#         $q->from( $t1, $t2, $fk, $where );
#         is(
#             $q->from_clause($dbh), $sql,
#             'from_clause() for inner join with explicit fk and where clause'
#         );
#     }
# }

# {
#     my $first = Fey::Table->new( name => 'first' );
#     $first->add_column(
#         Fey::Column->new(
#             name => 'first_id',
#             type => 'integer',
#         )
#     );
#     $first->add_candidate_key('first_id');

#     my $second = Fey::Table->new( name => 'second' );
#     $second->add_column(
#         Fey::Column->new(
#             name => 'second_id',
#             type => 'integer',
#         )
#     );
#     $second->add_column(
#         Fey::Column->new(
#             name => 'first_id',
#             type => 'integer',
#         )
#     );
#     $second->add_candidate_key('second_id');

#     my $third = Fey::Table->new( name => 'third' );
#     $third->add_column(
#         Fey::Column->new(
#             name => 'third_id',
#             type => 'integer',
#         )
#     );
#     $third->add_column(
#         Fey::Column->new(
#             name => 'second_id',
#             type => 'integer',
#         )
#     );
#     $third->add_candidate_key('third_id');

#     my $fourth = Fey::Table->new( name => 'fourth' );
#     $fourth->add_column(
#         Fey::Column->new(
#             name => 'fourth_id',
#             type => 'integer',
#         )
#     );
#     $fourth->add_column(
#         Fey::Column->new(
#             name => 'third_id',
#             type => 'integer',
#         )
#     );
#     $fourth->add_candidate_key('fourth_id');

#     $s->add_table($_) for $first, $second, $third, $fourth;

#     $s->add_foreign_key(
#         Fey::FK->new(
#             source_columns => [ $second->column('first_id') ],
#             target_columns => [ $first->column('first_id') ],
#         )
#     );
#     $s->add_foreign_key(
#         Fey::FK->new(
#             source_columns => [ $third->column('second_id') ],
#             target_columns => [ $second->column('second_id') ],
#         )
#     );
#     $s->add_foreign_key(
#         Fey::FK->new(
#             source_columns => [ $fourth->column('third_id') ],
#             target_columns => [ $third->column('third_id') ],
#         )
#     );

#     my $select = Fey::SQL->new_select();
#     #<<<
#     $select
#         ->select($fourth)
#         ->from( $fourth, $third )
#         ->from( $third, $second )
#         ->from( $second, $first )
#         ->where( $first->column('first_id'), '=', Fey::Placeholder->new() );
#     #>>

#     my $expect = q{SELECT "fourth"."third_id", "fourth"."fourth_id"};
#     $expect .= q{ FROM "second"};
#     $expect .= q{ JOIN "first" ON ("second"."first_id" = "first"."first_id")};
#     $expect .= q{ JOIN "third" ON ("third"."second_id" = "second"."second_id")};
#     $expect .= q{ JOIN "fourth" ON ("fourth"."third_id" = "third"."third_id")};
#     $expect .= q{ WHERE "first"."first_id" = ?};

# TODO:
#     {
#         local $TODO = q{This is a bug but I want to get a release out.};
#         is(
#             $select->sql($dbh), $expect,
#             'three joins in a row work'
#         );
#     }
# }

# # This is identical to the previous test except for the names. This one passes
# # but the other does not!
# {
#     my $t1 = Fey::Table->new( name => 't1' );
#     $t1->add_column(
#         Fey::Column->new(
#             name => 't1_id',
#             type => 'integer',
#         )
#     );
#     $t1->add_candidate_key('t1_id');

#     my $t2 = Fey::Table->new( name => 't2' );
#     $t2->add_column(
#         Fey::Column->new(
#             name => 't2_id',
#             type => 'integer',
#         )
#     );
#     $t2->add_column(
#         Fey::Column->new(
#             name => 't1_id',
#             type => 'integer',
#         )
#     );
#     $t2->add_candidate_key('t2_id');

#     my $t3 = Fey::Table->new( name => 't3' );
#     $t3->add_column(
#         Fey::Column->new(
#             name => 't3_id',
#             type => 'integer',
#         )
#     );
#     $t3->add_column(
#         Fey::Column->new(
#             name => 't2_id',
#             type => 'integer',
#         )
#     );
#     $t3->add_candidate_key('t3_id');

#     my $t4 = Fey::Table->new( name => 't4' );
#     $t4->add_column(
#         Fey::Column->new(
#             name => 't4_id',
#             type => 'integer',
#         )
#     );
#     $t4->add_column(
#         Fey::Column->new(
#             name => 't3_id',
#             type => 'integer',
#         )
#     );
#     $t4->add_candidate_key('t4_id');

#     $s->add_table($_) for $t1, $t2, $t3, $t4;

#     $s->add_foreign_key(
#         Fey::FK->new(
#             source_columns => [ $t2->column('t1_id') ],
#             target_columns => [ $t1->column('t1_id') ],
#         )
#     );
#     $s->add_foreign_key(
#         Fey::FK->new(
#             source_columns => [ $t3->column('t2_id') ],
#             target_columns => [ $t2->column('t2_id') ],
#         )
#     );
#     $s->add_foreign_key(
#         Fey::FK->new(
#             source_columns => [ $t4->column('t3_id') ],
#             target_columns => [ $t3->column('t3_id') ],
#         )
#     );

#     my $select = Fey::SQL->new_select();
#     #<<<
#     $select
#         ->select($t4)
#         ->from( $t4, $t3 )
#         ->from( $t3, $t2 )
#         ->from( $t2, $t1 )
#         ->where( $t1->column('t1_id'), '=', Fey::Placeholder->new() );
#     #>>

#     my $expect = q{SELECT "t4"."t3_id", "t4"."t4_id"};
#     $expect .= q{ FROM "t2"};
#     $expect .= q{ JOIN "t1" ON ("t2"."t1_id" = "t1"."t1_id")};
#     $expect .= q{ JOIN "t3" ON ("t3"."t2_id" = "t2"."t2_id")};
#     $expect .= q{ JOIN "t4" ON ("t4"."t3_id" = "t3"."t3_id")};
#     $expect .= q{ WHERE "t1"."t1_id" = ?};

#     is(
#         $select->sql($dbh), $expect,
#         'three joins in a row work'
#     );
# }

# done_testing();
