use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;

use Fey::Column;

{
    my %MysqlTypes = (
        DATE       => 'date',
        DATETIME   => 'datetime',
        TIMESTAMP  => 'datetime',
        TIME       => 'time',
        TINYTEXT   => 'text',
        TEXT       => 'text',
        MEDIUMTEXT => 'text',
        LONGTEXT   => 'text',
        CHAR       => 'text',
        VARCHAR    => 'text',
        TINYBLOB   => 'blob',
        BLOB       => 'blob',
        MEDIUMBLOB => 'blob',
        LONGBLOB   => 'blob',
        INTEGER    => 'integer',
        TINYINT    => 'integer',
        SMALLINT   => 'integer',
        MEDIUMINT  => 'integer',
        BIGINT     => 'integer',
        YEAR       => 'integer',
        FLOAT      => 'float',
        DOUBLE     => 'float',
        REAL       => 'float',
        DECIMAL    => 'float',
        NUMERIC    => 'float',
    );
    while ( my ( $type, $generic ) = each %MysqlTypes ) {
        my $c = Fey::Column->new(
            name => 'test',
            type => $type,
        );
        is(
            $c->_build_generic_type($type), $generic,
            "builded $generic for generic type of $type"
        );
    }
}

{
    my %PgTypes = (
        ABSTIME     => 'time',
        RELTIME     => 'time',
        TIME        => 'time',
        TIMETZ      => 'time',
        DATE        => 'date',
        TIMESTAMP   => 'datetime',
        TIMESTAMPTZ => 'datetime',
        BIGINT      => 'integer',
        SMALLINT    => 'integer',
        INT         => 'integer',
        INTEGER     => 'integer',
        INT2        => 'integer',
        INT4        => 'integer',
        INT8        => 'integer',
        BOOL        => 'boolean',
        BOOLEAN     => 'boolean',
        BOX         => 'other',
        CIDR        => 'other',
        CIRCLE      => 'other',
        INET        => 'other',
        INTERVAL    => 'other',
        MACADDR     => 'other',
        OID         => 'other',
        VARBIT      => 'other',
        BIT         => 'other',
        BYTEA       => 'blob',
        CHAR        => 'text',
        VARCHAR     => 'text',
        CHARACTER   => 'text',
        TEXT        => 'text',
        DATE        => 'date',
        DECIMAL     => 'float',
        FLOAT       => 'float',
        FLOAT4      => 'float',
        FLOAT8      => 'float',
        MONEY       => 'float',
        NUMERIC     => 'float',
    );
    while ( my ( $type, $generic ) = each %PgTypes ) {
        my $c = Fey::Column->new(
            name => 'test',
            type => $type,
        );
        is(
            $c->_build_generic_type($type), $generic,
            "builded $generic for generic type of $type"
        );
    }
}

done_testing();
