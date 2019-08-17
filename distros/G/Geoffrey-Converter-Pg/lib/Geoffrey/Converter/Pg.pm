package Geoffrey::Converter::Pg;

use utf8;
use 5.016;
use strict;
use Readonly;
use warnings;

$Geoffrey::Converter::Pg::VERSION = '0.000200';

use parent 'Geoffrey::Role::Converter';

Readonly::Scalar my $I_CONST_LENGTH_VALUE      => 2;
Readonly::Scalar my $I_CONST_NOT_NULL_VALUE    => 3;
Readonly::Scalar my $I_CONST_PRIMARY_KEY_VALUE => 4;
Readonly::Scalar my $I_CONST_DEFAULT_VALUE     => 5;

{

    package Geoffrey::Converter::Pg::Constraints;

    use parent 'Geoffrey::Role::ConverterType';

    sub new {
        my $class = shift;
        return bless $class->SUPER::new(
            not_null    => 'NOT NULL',
            unique      => 'UNIQUE',
            primary_key => 'PRIMARY KEY',
            foreign_key => 'FOREIGN KEY',
            check       => 'CHECK',
            default     => 'DEFAULT',
        ), $class;
    }
}
{

    package Geoffrey::Converter::Pg::View;

    use parent 'Geoffrey::Role::ConverterType';

    sub add { return 'CREATE VIEW {0} AS {1}'; }

    sub drop { return 'DROP VIEW {0}'; }

    sub list {
        my ($self, $schema) = @_;
        return q~SELECT * FROM pg_views WHERE schemaname NOT IN('information_schema', 'pg_catalog')~;
    }
}
{

    package Geoffrey::Converter::Pg::ForeignKey;
    use parent 'Geoffrey::Role::ConverterType';
    sub add { return 'FOREIGN KEY ({0}) REFERENCES {1}({2})' }

    sub list {
        return q~SELECT
                source_table::regclass,
                source_attr.attname AS source_column,
                target_table::regclass,
                target_attr.attname AS target_column
            FROM
                pg_attribute target_attr,
                pg_attribute source_attr,
                (
                    SELECT
                        source_table,
                        target_table,
                        source_constraints[i] AS source_constraints,
                        target_constraints[i] AS target_constraints
                    FROM (   
                        SELECT
                            conrelid as source_table,
                            confrelid AS target_table,
                            conkey AS source_constraints,
                            confkey AS target_constraints,
                            generate_series(1, array_upper(conkey, 1)) AS i
                        FROM
                            pg_constraint
                        WHERE
                            contype = 'f'
                    ) query1
                ) query2
            WHERE
                    target_attr.attnum = target_constraints 
                AND target_attr.attrelid = target_table
                AND source_attr.attnum = source_constraints
                AND source_attr.attrelid = source_table~;
    }
}
{

    package Geoffrey::Converter::Pg::Sequence;
    use parent 'Geoffrey::Role::ConverterType';
    sub add     { return 'CREATE SEQUENCE {0} INCREMENT {1} MINVALUE {2} MAXVALUE {3} START {4} CACHE {5}' }
    sub nextval { return q~DEFAULT nextval('{0}'::regclass~ }
}

{

    package Geoffrey::Converter::Pg::PrimaryKey;
    use parent 'Geoffrey::Role::ConverterType';
    sub add { return 'CONSTRAINT {0} PRIMARY KEY ( {1} )'; }

    sub list {
        return q~SELECT
            tc.table_schema,
            tc.table_name,
            kc.column_name,
            kc.constraint_name 
        FROM  
            information_schema.table_constraints tc,  
            information_schema.key_column_usage kc  
        WHERE 
            tc.constraint_type = 'PRIMARY KEY' 
        AND kc.table_name = tc.table_name 
        AND kc.table_schema = tc.table_schema
        AND kc.constraint_name = tc.constraint_name~;
    }
}
{

    package Geoffrey::Converter::Pg::UniqueIndex;
    use parent 'Geoffrey::Role::ConverterType';
    sub append { return 'CREATE UNIQUE INDEX IF NOT EXISTS {0} ON {1} ( {2} )'; }
    sub add    { return 'CONSTRAINT {0} UNIQUE ( {1} )'; }
    sub drop   { return 'DROP INDEX IF EXISTS {1}'; }

    sub list {
        list => q~SELECT
                    U.usename                AS user_name,
                    ns.nspname               AS schema_name,
                    idx.indrelid :: REGCLASS AS table_name,
                    i.relname                AS index_name,
                    am.amname                AS index_type,
                    idx.indkey,
                    ARRAY(
                    SELECT
                        pg_get_indexdef(idx.indexrelid, k + 1, TRUE)
                    FROM
                        generate_subscripts(idx.indkey, 1) AS k
                    ORDER BY k
                    ) AS index_keys,
                    (idx.indexprs IS NOT NULL) OR (idx.indkey::int[] @> array[0]) AS is_functional,
                    idx.indpred IS NOT NULL AS is_partial
                FROM 
                    pg_index AS idx
                    JOIN pg_class AS i ON i.oid = idx.indexrelid
                    JOIN pg_am AS am ON i.relam = am.oid
                    JOIN pg_namespace AS NS ON i.relnamespace = NS.OID
                    JOIN pg_user AS U ON i.relowner = U.usesysid
                WHERE
                        NOT nspname LIKE 'pg%'
                    AND NOT idx.indisprimary
                    AND idx.indisunique;~;
    }
}
{

    package Geoffrey::Converter::Pg::Function;
    use parent 'Geoffrey::Role::ConverterType';
    sub add  { return q~CREATE FUNCTION {0}({1}) RETURNS {2} AS ' {3} ' LANGUAGE {4} VOLATILE COST {5}~; }
    sub drop { return 'DROP FUNCTION {0} ({1})'; }

    sub list {
        list => q~SELECT n.nspname as "Schema",
                    p.proname as "Name",
                    p.prosrc,
                    p.procost,
                    pg_catalog.pg_get_function_result(p.oid) as result_data_type,
                    pg_catalog.pg_get_function_arguments(p.oid) as argument_data_types,
                    CASE
                        WHEN p.proisagg THEN 'agg'
                        WHEN p.proiswindow THEN 'window'
                        WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger'
                    ELSE
                        'normal'
                    END as
                        function_type
                FROM
                    pg_catalog.pg_proc p
                    LEFT JOIN pg_catalog.pg_namespace n
                        ON ( n.oid = p.pronamespace )
                WHERE
                        pg_catalog.pg_function_is_visible( p.oid )
                    AND n.nspname <> 'pg_catalog'
                    AND n.nspname <> 'information_schema'~;
    }
}
{

    package Geoffrey::Converter::Pg::Trigger;
    use parent 'Geoffrey::Role::ConverterType';

    sub add {
        my ($self, $options) = @_;
        my $s_sql_standard = <<'EOF';
CREATE TRIGGER {0} UPDATE OF {1} ON {2}
BEGIN
    {4}
END
EOF
        my $s_sql_view = <<'EOF';
CREATE TRIGGER {0} INSTEAD OF UPDATE OF {1} ON {2}
BEGIN
    {4}
END
EOF
        return $options->{for_view} ? $s_sql_view : $s_sql_standard;
    }

    sub drop { return 'DROP TRIGGER IF EXISTS {1}'; }
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{min_version} = '9.1';
    return bless $self, $class;
}

sub defaults {
    return {current_timestamp => 'CURRENT_TIMESTAMP', autoincrement => 'SERIAL',};
}

sub type {
    my ($self, $hr_column_params) = @_;
    if ($hr_column_params->{default} eq 'autoincrement') {
        $hr_column_params->{type}
            = lc $hr_column_params->{type} eq 'bigint'   ? 'bigserial'
            : lc $hr_column_params->{type} eq 'smallint' ? 'smallserial'
            :                                              'serial';
        delete $hr_column_params->{default};
    }
    return $self->SUPER::type($hr_column_params);
}

sub types {
    return {
        abstime          => 'abstime',
        aclitem          => 'aclitem',
        bigint           => 'bigint',
        bigserial        => 'bigserial',
        bit              => 'bit',
        var_bit          => 'bit varying',
        bool             => 'boolean',
        box              => 'box',
        bytea            => 'bytea',
        char             => '"char"',
        character        => 'character',
        varchar          => 'character varying',
        cid              => 'cid',
        cidr             => 'cidr',
        circle           => 'circle',
        date             => 'date',
        daterange        => 'daterange',
        decimal          => 'decimal',
        double_precision => 'double precision',
        gtsvector        => 'gtsvector',
        inet             => 'inet',
        int2vector       => 'int2vector',
        int4range        => 'int4range',
        int8range        => 'int8range',
        integer          => 'integer',
        interval         => 'interval',
        json             => 'json',
        line             => 'line',
        lseg             => 'lseg',
        macaddr          => 'macaddr',
        money            => 'money',
        name             => 'name',
        numeric          => 'numeric',
        numrange         => 'numrange',
        oid              => 'oid',
        oidvector        => 'oidvector',
        path             => 'path',
        pg_node_tree     => 'pg_node_tree',
        point            => 'point',
        polygon          => 'polygon',
        real             => 'real',
        refcursor        => 'refcursor',
        regclass         => 'regclass',
        regconfig        => 'regconfig',
        regdictionary    => 'regdictionary',
        regoper          => 'regoper',
        regoperator      => 'regoperator',
        regproc          => 'regproc',
        regprocedure     => 'regprocedure',
        regtype          => 'regtype',
        reltime          => 'reltime',
        serial           => 'serial',
        smallint         => 'smallint',
        smallserial      => 'smallserial',
        smgr             => 'smgr',
        text             => 'text',
        tid              => 'tid',
        timestamp        => 'timestamp without time zone',
        timestamp_tz     => 'timestamp with time zone',
        time             => 'time without time zone',
        time_tz          => 'time with time zone',
        tinterval        => 'tinterval',
        tsquery          => 'tsquery',
        tsrange          => 'tsrange',
        tstzrange        => 'tstzrange',
        tsvector         => 'tsvector',
        txid_snapshot    => 'txid_snapshot',
        uuid             => 'uuid',
        xid              => 'xid',
        xml              => 'xml',
    };
}

sub select_get_table {
    return
        q~SELECT t.table_name AS table_name FROM information_schema.tables t WHERE t.table_type = 'BASE TABLE' AND t.table_schema = ? AND t.table_name = ?~;
}

sub convert_defaults {
    my ($self, $params) = @_;
    $params->{default} =~ s/^'(.*)'$/$1/;
    if ($params->{type} eq 'bit') {
        return qq~$params->{default}::bit~;
    }
    return $params->{default};
}

sub parse_default {
    my ($self, $default_value) = @_;
    return $1 * 1 if ($default_value =~ m/\w'(\d+)'::"\w+"/);
    return $default_value;
}

sub can_create_empty_table { return 0 }

sub colums_information {
    my ($self, $ar_raw_data) = @_;
    return [] if scalar @{$ar_raw_data} == 0;
    my $table_row = shift @{$ar_raw_data};
    $table_row->{sql} =~ s/^.*(CREATE|create) .*\(//g;
    my $columns = [];
    for (split m/,/, $table_row->{sql}) {
        s/^\s*(.*)\s*$/$1/g;
        my $rx_not_null      = 'NOT NULL';
        my $rx_primary_key   = 'PRIMARY KEY';
        my $rx_default       = 'SERIAL|DEFAULT';
        my $rx_column_values = qr/($rx_not_null)*\s($rx_primary_key)*.*($rx_default \w{1,})*/;
        my @column           = m/^(\w+)\s([[:upper:]]+)(\(\d*\))*\s$rx_column_values$/;
        next if scalar @column == 0;
        $column[$I_CONST_LENGTH_VALUE] =~ s/([\(\)])//g if $column[$I_CONST_LENGTH_VALUE];
        push @{$columns},
            {
            name => $column[0],
            type => $column[1],
            ($column[$I_CONST_LENGTH_VALUE]      ? (length      => $column[$I_CONST_LENGTH_VALUE])      : ()),
            ($column[$I_CONST_NOT_NULL_VALUE]    ? (not_null    => $column[$I_CONST_NOT_NULL_VALUE])    : ()),
            ($column[$I_CONST_PRIMARY_KEY_VALUE] ? (primary_key => $column[$I_CONST_PRIMARY_KEY_VALUE]) : ()),
            ($column[$I_CONST_DEFAULT_VALUE]     ? (default     => $column[$I_CONST_DEFAULT_VALUE])     : ()),
            };
    }
    return $columns;
}

sub index_information {
    my ($self, $ar_raw_data) = @_;
    my @mapped = ();
    for (@{$ar_raw_data}) {
        next if !$_->{sql};
        my ($s_columns) = $_->{sql} =~ m/\((.*)\)$/;
        my @columns = split m/,/, $s_columns;
        s/^\s+|\s+$//g for @columns;
        push @mapped, {name => $_->{name}, table => $_->{tbl_name}, columns => \@columns};
    }
    return \@mapped;
}

sub view_information {
    my ($self, $ar_raw_data) = @_;
    return [] unless $ar_raw_data;
    return [map { {name => $_->{name}, sql => $_->{sql}} } @{$ar_raw_data}];
}

sub constraints {
    return shift->_get_value('constraints', 'Geoffrey::Converter::Pg::Constraints', 1);
}

sub index {
    my ($self, $new_value) = @_;
    $self->{index} = $new_value if defined $new_value;
    return $self->_get_value('index', 'Geoffrey::Converter::Pg::Index');
}

sub table {
    return shift->_get_value('table', 'Geoffrey::Converter::Pg::Tables');
}

sub view {
    return shift->_get_value('view', 'Geoffrey::Converter::Pg::View', 1);
}

sub foreign_key {
    my ($self, $new_value) = @_;
    $self->{foreign_key} = $new_value if defined $new_value;
    return $self->_get_value('foreign_key', 'Geoffrey::Converter::Pg::ForeignKey', 1);
}

sub trigger {
    return shift->_get_value('trigger', 'Geoffrey::Converter::Pg::Trigger', 1);
}

sub primary_key {
    return shift->_get_value('primary_key', 'Geoffrey::Converter::Pg::PrimaryKey', 1);
}

sub unique {
    return shift->_get_value('unique', 'Geoffrey::Converter::Pg::UniqueIndex', 1);
}

sub sequence {
    return shift->_get_value('sequence', 'Geoffrey::Converter::Pg::Sequence', 1);
}

sub _get_value {
    my ($self, $key, $s_package_name, $b_ignore_require) = @_;
    $self->{$key} //= $self->_set_value($key, $s_package_name, $b_ignore_require);
    return $self->{$key};
}

sub _set_value {
    my ($self, $key, $s_package_name, $b_ignore_require) = @_;
    require Geoffrey::Utils;
    $self->{$key} = $b_ignore_require ? $s_package_name->new(@_) : Geoffrey::Utils::obj_from_name($s_package_name);
    return $self->{$key};

}

1;    # End of Geoffrey::Converter::Pg

__END__

=pod

=head1 NAME

Geoffrey::Converter::Pg - PostgreSQL converter for Geoffrey

=head1 VERSION

Version 0.000200

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 can_create_empty_table

=head2 constraints

Create an instance of Geoffrey::Converter::Pg::Constraints and returns the object.

=head2 foreign_key

Create an instance of Geoffrey::Converter::Pg::ForeignKey and returns the object.

=head2 index

Create an instance of Geoffrey::Converter::Pg::Index and returns the object.

=head2 primary_key

Create an instance of Geoffrey::Converter::Pg::PrimaryKey and returns the object.

=head2 table

Create an instance of Geoffrey::Converter::Pg::Tables and returns the object.

=head2 trigger

Create an instance of Geoffrey::Converter::Pg::Trigger and returns the object.

=head2 unique

Create an instance of Geoffrey::Converter::Pg::UniqueIndex and returns the object.

=head2 view

Create an instance of Geoffrey::Converter::Pg::View and returns the object.

=head2 sequence

Create an instance of Geoffrey::Converter::Pg::Sequence and returns the object.

=head2 view_information

=head2 colums_information

=head2 convert_defaults

=head2 defaults

=head2 index_information

=head2 select_get_table

=head2 types

=head2 parse_default

=head2 type

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * Inherits

L<Geoffrey::Role::Converter|Geoffrey::Role::Converter>

=item * Internal usage

L<Readonly|Readonly>, L<Geoffrey::Role::ConverterType|Geoffrey::Role::ConverterType>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-Geoffrey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geoffrey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Geoffrey::Converter::Pg

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geoffrey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geoffrey>

=item * Search CPAN

L<http://search.cpan.org/dist/Geoffrey/>

=back

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
