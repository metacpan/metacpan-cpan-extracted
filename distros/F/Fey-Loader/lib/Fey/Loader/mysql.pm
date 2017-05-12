package Fey::Loader::mysql;
{
  $Fey::Loader::mysql::VERSION = '0.13';
}

use Moose;

use namespace::autoclean;

use DBD::mysql 4.004;

use Fey::Literal;
use Scalar::Util qw( looks_like_number );

extends 'Fey::Loader::DBI';

package    # hide from PAUSE
    DBD::mysql::Fixup;

BEGIN {
    use B::Deparse;

    # XXX - hack of epic proportions - DBD::mysql::DB defined a totally broken
    # statistics_info that attempts to call SUPER::statistics_info
    # internally. The method doesn't exist in the parent class so it
    # explodes. However, since this broken method is in place, we can't just
    # check to see if the method exists before monkey patching.
    my $meth = DBD::mysql::db->can('statistics_info');
    if ( $meth ) {
        my @lines = split /[\r\n]+/, B::Deparse->new()->coderef2text($meth);

        # The broken implementation is just a few lines. If this ever gets
        # implemented for real it will have to be longer.
        no warnings 'redefine';
        *DBD::mysql::db::statistics_info = \&_statistics_info
            if @lines < 10;
    }
}

sub _statistics_info {
    my ( $dbh, $catalog, $schema, $table, $unique_only ) = @_;

    if ( DBD::mysql->VERSION >= 4.018 ) {
        return unless $dbh->func('_async_check');
    }

    $dbh->{mysql_server_prepare} ||= 0;
    my $mysql_server_prepare_save = $dbh->{mysql_server_prepare};

    my $table_id = $dbh->quote_identifier( $catalog, $schema, $table );

    my @names = qw(
        TABLE_CAT TABLE_SCHEM TABLE_NAME NON_UNIQUE INDEX_QUALIFIER
        INDEX_NAME TYPE ORDINAL_POSITION COLUMN_NAME COLLATION
        CARDINALITY PAGES FILTER_CONDITION
    );
    my %index_info;

    local $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $desc_sth = $dbh->prepare("SHOW KEYS FROM $table_id");
    my $desc = $dbh->selectall_arrayref( $desc_sth, { Columns => {} } );
    my $ordinal_pos = 0;

    for my $row ( grep { $_->{key_name} ne 'PRIMARY' } @$desc ) {
        next if $unique_only && $row->{non_unique};

        $index_info{ $row->{key_name} } = {
            TABLE_CAT        => $catalog,
            TABLE_SCHEM      => $schema,
            TABLE_NAME       => $table,
            NON_UNIQUE       => $row->{non_unique},
            INDEX_NAME       => $row->{key_name},
            TYPE             => lc $row->{index_type},
            ORDINAL_POSITION => $row->{seq_in_index},
            COLUMN_NAME      => $row->{column_name},
            COLLATION        => $row->{collation},
            CARDINALITY      => $row->{cardinality},
            mysql_nullable   => ( $row->{nullable} ? 1 : 0 ),
            mysql_comment    => $row->{comment},
        };
    }

    my $sponge = DBI->connect( "DBI:Sponge:", '', '' )
        or ( $dbh->{mysql_server_prepare} = $mysql_server_prepare_save
        && return $dbh->DBI::set_err( $DBI::err, "DBI::Sponge: $DBI::errstr" )
        );

    my $sth = $sponge->prepare(
        "statistics_info $table", {
            rows => [ map { [ @{$_}{@names} ] } values %index_info ],
            NUM_OF_FIELDS => scalar @names,
            NAME          => \@names,
        }
        )
        or ( $dbh->{mysql_server_prepare} = $mysql_server_prepare_save
        && return $dbh->DBI::set_err( $sponge->err(), $sponge->errstr() ) );

    $dbh->{mysql_server_prepare} = $mysql_server_prepare_save;

    return $sth;
}

package Fey::Loader::mysql;

sub _build_dbh_name {
    my $self = shift;

    return $self->dbh()->selectrow_arrayref('SELECT DATABASE()')->[0];
}

sub _column_params {
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    my %col = $self->SUPER::_column_params( $table, $col_info );

    # DBD::mysql adds the max length for some data types to the column
    # info, but we only care about user-specified lengths.
    #
    # Unfortunately, DBD::mysql itself adds a length to some types
    # (notably integer types) that isn't really useful, but it's
    # impossible to distinguish between a length specified by the user
    # and one specified by DBD::mysql.
    delete $col{length}
        if (
           $col{type} =~ /(?:text|blob)$/i
        || $col{type} =~ /^(?:float|double)/i
        || $col{type} =~ /^(?:enum|set)/i
        || ( $col{type} =~ /^(?:date|time)/i
            && lc $col{type} ne 'timestamp' )
        );

    delete $col{precision}
        if $col{type} =~ /date|time/o;

    delete $col{default}
        if ( exists $col{default}
        && $col_info->{COLUMN_DEF} eq ''
        && $col_info->{TYPE_NAME} =~ /int|float|double/i );

    return %col;
}

sub _is_auto_increment {
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    return $col_info->{mysql_is_auto_increment} ? 1 : 0;
}

sub _default {
    my $self     = shift;
    my $default  = shift;
    my $col_info = shift;

    if ( $default =~ /^NULL$/i ) {
        return Fey::Literal::Null->new();
    }
    elsif ( $default =~ /^CURRENT_TIMESTAMP$/i ) {
        return Fey::Literal::Term->new($default);
    }
    elsif ( looks_like_number($default) ) {
        return Fey::Literal::Number->new($default);
    }
    else {
        return Fey::Literal::String->new($default);
    }
}

{
    my $quoted_name = qr/["`](.*?)["`]/;
    my $fk = qr/CONSTRAINT $quoted_name FOREIGN KEY \($quoted_name\) REFERENCES $quoted_name \($quoted_name\)/;

    sub _fk_info_sth {
        my $self = shift;
        my $name = shift;

        my ( $pk_tbl, $ddl ) = eval {
            $self->dbh()->selectrow_array("SHOW CREATE TABLE `$name`");
        };

        return unless defined $ddl;

        my @fk_info;

        while ( $ddl =~ /$fk/g ) {
            my $fk_name = $1;
            my $pk_cols = $2;
            my $fk_tbl  = $3;
            my $fk_cols = $4;

            my @pk_col = split /\s*,\s*/, $pk_cols;
            my @fk_col = split /\s*,\s*/, $fk_cols;

            push @fk_info,
                [ $fk_tbl, $fk_col[$_], $pk_tbl, $pk_col[$_], $fk_name ]
                for 0 .. $#pk_col;
        }

        return unless @fk_info;

        return DBI->connect( 'dbi:Sponge:', '', '', { RaiseError => 1 } )
            ->prepare(
            "foreign_key_info $name", {
                NAME => [
                    qw( PKTABLE_NAME PKCOLUMN_NAME FKTABLE_NAME FKCOLUMN_NAME FK_NAME )
                ],
                rows => \@fk_info,
            }
            );
    }
}

__PACKAGE__->meta()->make_immutable();

1;

=head1 SYNOPSIS

  my $loader = Fey::Loader->new( dbh => $dbh );

  my $schema = $loader->make_schema( name => $name );

=head1 DESCRIPTION

C<Fey::Loader::mysql> implements some MySQL-specific loader
behavior.

=head1 METHODS

This class provides the same public methods as L<Fey::Loader::DBI>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-fey-loader@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=cut
