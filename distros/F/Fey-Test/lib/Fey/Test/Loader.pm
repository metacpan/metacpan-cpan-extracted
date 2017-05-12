package Fey::Test::Loader;
{
  $Fey::Test::Loader::VERSION = '0.10';
}

use strict;
use warnings;

use Test::More;

sub compare_schemas {
    my $class    = shift;
    my $schema1  = shift;
    my $schema2  = shift;
    my $override = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is(
        $schema1->name(), $schema2->name(),
        'schemas have the same name'
    );

    for my $table1 ( grep { $_->name() ne 'TestView' } $schema1->tables() ) {
        my $name   = $table1->name();
        my $table2 = $schema2->table($name);

        ok(
            $table2,
            "$name table found by loader exists in test schema"
        );

        my $expect
            = exists $override->{ $table1->name() }{is_view}
            ? $override->{ $table1->name() }{is_view}
            : $table2->is_view();
        is(
            $table1->is_view(), $expect,
            "schemas agree on is_view() for $name table"
        );

        $class->compare_pk( $table1, $table2, $override );
        $class->compare_ck( $table1, $table2, $override );
        $class->compare_columns( $table1, $table2, $override );
        $class->compare_fks( $table1, $table2, $override );
    }

    my $test_view_t = $schema1->table('TestView');
    ok( $test_view_t, 'TestView table exists in loader-made schema' );
    ok( $test_view_t->is_view(), 'TestView table is_view() is true' );

    for my $table2 ( $schema2->tables() ) {
        my $name = $table2->name();

        ok(
            $schema1->table($name),
            "$name table in test schema was found by loader"
        );
    }
}

sub compare_pk {
    my $class    = shift;
    my $table1   = shift;
    my $table2   = shift;
    my $override = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @pk1 = map { $_->name() } @{ $table1->primary_key() };
    my @pk2 = map { $_->name() } @{ $table2->primary_key() };

    my $expect
        = exists $override->{ $table1->name() }{primary_key}
        ? $override->{ $table1->name() }{primary_key}
        : \@pk2;

    is_deeply(
        \@pk1, $expect,
        "schemas agree on primary key for " . $table1->name()
    );
}

sub compare_ck {
    my $class    = shift;
    my $table1   = shift;
    my $table2   = shift;
    my $override = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @ck1;
    for my $ck1 ( @{ $table1->candidate_keys() } ) {
        push @ck1, [ map { $_->name() } @{$ck1} ];
    }

    my @ck2;
    for my $ck2 ( @{ $table2->candidate_keys() } ) {
        push @ck2, [ map { $_->name() } @{$ck2} ];
    }

    my $expect
        = exists $override->{ $table1->name() }{candidate_keys}
        ? $override->{ $table1->name() }{candidate_keys}
        : \@ck2;

    is_deeply(
        \@ck1, $expect,
        "schemas agree on candidate keys for " . $table1->name()
    );
}

sub compare_columns {
    my $class    = shift;
    my $table1   = shift;
    my $table2   = shift;
    my $override = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    for my $col1 ( $table1->columns() ) {
        my $name = $col1->name();
        my $fq_name = join '.', $table1->name(), $name;

        my $col2 = $table2->column($name);
        ok(
            $col2,
            "$fq_name column found by loader exists in test schema"
        );

        for my $meth (
            qw( type generic_type length precision
            is_nullable is_auto_increment )
            ) {

            my $got = $col1->$meth();
            my $expect
                = exists $override->{$fq_name}{$meth}
                ? $override->{$fq_name}{$meth}
                : $col2->$meth();

            is(
                ( defined $got    ? lc $got    : undef ),
                ( defined $expect ? lc $expect : undef ),
                "schemas agree on $meth for $fq_name"
            );
        }

        my $def1 = $col1->default();
        my $def2
            = exists $override->{$fq_name}{default}
            ? $override->{$fq_name}{default}
            : $col2->default();

        $def1 = $def1->id()
            if $def1;
        $def2 = $def2->id()
            if $def2;

        is( $def1, $def2, "schemas agree on default for $fq_name" );
    }

    for my $col2 ( $table2->columns() ) {
        my $name = $col2->name();

        ok(
            $table1->column($name),
            "$name column in test schema was found by loader"
        );
    }
}

sub compare_fks {
    my $class    = shift;
    my $table1   = shift;
    my $table2   = shift;
    my $override = shift;

    return if $override->{skip_foreign_keys};

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $schema1 = $table1->schema();
    my $schema2 = $table2->schema();

    # We're not using $fk->id() because the ids we generate this way print out much nicer
    my %fk1 = map { $class->_fk_id($_) => 1 }
        $schema1->foreign_keys_for_table($table1);
    my %fk2 = map { $class->_fk_id($_) => 1 }
        $schema2->foreign_keys_for_table($table2);

    my $name = $table1->name();

    for my $id ( keys %fk1 ) {
        ok(
            $fk2{$id},
            "fk for $name from loader is present in test schema"
        ) or diag($id);
    }

    for my $id ( keys %fk2 ) {
        ok(
            $fk1{$id},
            "fk for $name in test schema is present in loader"
        ) or diag($id);
    }
}

sub _fk_id {
    my $class = shift;
    my $fk    = shift;

    my @id = '  source_table = ' . $fk->source_table()->name();
    push @id, '  source_columns = ' . join ', ',
        map { $_->name() } @{ $fk->source_columns() };
    push @id, '  target_table = ' . $fk->target_table()->name();
    push @id, '  target_columns = ' . join ', ',
        map { $_->name() } @{ $fk->target_columns() };

    return join '', map { $_ . "\n" } @id;
}

1;
