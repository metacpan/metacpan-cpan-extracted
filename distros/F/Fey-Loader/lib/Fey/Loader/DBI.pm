package Fey::Loader::DBI;
{
  $Fey::Loader::DBI::VERSION = '0.13';
}

use Moose;

use namespace::autoclean;

use MooseX::Params::Validate qw( validated_hash );

has 'dbh' => (
    is       => 'ro',
    isa      => 'DBI::db',
    required => 1,
);

has 'schema_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Fey::Schema',
);

has 'table_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Fey::Table',
);

has 'column_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Fey::Column',
);

has 'fk_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => 'Fey::FK',
);

has '_dbh_name' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_dbh_name',
);

use Fey::Column;
use Fey::FK;
use Fey::Schema;
use Fey::Table;

use Scalar::Util qw( looks_like_number );

sub make_schema {
    my $self = shift;
    my %p = validated_hash( \@_, name => { isa => 'Str', optional => 1 } );

    my $name = delete $p{name} || $self->_dbh_name();

    my $schema = $self->schema_class()->new( name => $name );

    $self->_add_tables($schema);
    $self->_add_foreign_keys($schema);

    return $schema;
}

sub _build_dbh_name {
    my $self = shift;

    my $dsn_ish = $self->dbh()->{Name};

    return $dsn_ish unless $dsn_ish =~ /\W/;

    return $1 if $dsn_ish =~ /(?:database|dbname)=([^;]+?)(?:;|\z)/;

    die "Cannot figure out the database name from the DSN - $dsn_ish\n";
}

sub _add_tables {
    my $self   = shift;
    my $schema = shift;

    my $sth = $self->dbh()->table_info(
        $self->_catalog_name(), $self->_schema_name(),
        '%',                    'TABLE,VIEW'
    );

    while ( my $table_info = $sth->fetchrow_hashref() ) {
        $self->_add_table( $schema, $table_info );
    }
}

sub _catalog_name {undef}

sub _schema_name {undef}

sub _unquote_identifier {
    my $self  = shift;
    my $ident = shift;

    my $quote = $self->dbh()->get_info(29) || q{"};

    $ident =~ s/^\Q$quote\E|\Q$quote\E$//g;
    $ident =~ s/\Q$quote$quote\E/$quote/g;

    return $ident;
}

sub _add_table {
    my $self       = shift;
    my $schema     = shift;
    my $table_info = shift;

    my $name = $self->_unquote_identifier( $table_info->{TABLE_NAME} );

    my $table = $self->table_class()->new(
        name    => $name,
        is_view => $self->_is_view($table_info),
    );

    $self->_add_columns($table);
    $self->_set_primary_key($table);
    $self->_set_other_keys($table);

    $schema->add_table($table);
}

sub _is_view { $_[1]->{TABLE_TYPE} eq 'VIEW' ? 1 : 0 }

sub _add_columns {
    my $self  = shift;
    my $table = shift;

    my $sth = $self->dbh()->column_info(
        $self->_catalog_name(),
        $self->_schema_name(),
        $table->name(),
        '%'
    );

    while ( my $col_info = $sth->fetchrow_hashref() ) {
        my %col = $self->_column_params( $table, $col_info );

        my $col = $self->column_class()->new(%col);

        $table->add_column($col);
    }
}

sub _column_params {
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    my $name = $self->_unquote_identifier( $col_info->{COLUMN_NAME} );

    my %col = (
        name => $name,
        type => $col_info->{TYPE_NAME},

        # NULLABLE could be 2, which indicates unknown
        is_nullable => ( $col_info->{NULLABLE} == 1 ? 1 : 0 ),
    );

    $col{length} = $col_info->{COLUMN_SIZE}
        if defined $col_info->{COLUMN_SIZE};

    $col{precision} = $col_info->{DECIMAL_DIGITS}
        if defined $col_info->{DECIMAL_DIGITS};

    if ( defined $col_info->{COLUMN_DEF} ) {
        my $default = $self->_default( $col_info->{COLUMN_DEF}, $col_info );
        $col{default} = $default
            if defined $default;
    }

    $col{is_auto_increment} = $self->_is_auto_increment( $table, $col_info );

    return %col;
}

sub _default {
    my $self    = shift;
    my $default = shift;

    if ( $default =~ /^NULL$/i ) {
        return Fey::Literal::Null->new();
    }
    elsif ( $default =~ s/^(["'])(.*)\1$/$2/ ) {
        my $quote = $1;
        $default =~ s/\Q$quote$quote/$quote/g;

        return Fey::Literal::String->new($default);
    }
    elsif ( looks_like_number($default) ) {
        return Fey::Literal::Number->new($default);
    }
    else {
        return Fey::Literal::Term->new($default);
    }
}

sub _is_auto_increment {
    return 0;
}

sub _set_primary_key {
    my $self  = shift;
    my $table = shift;

    my $pk_info = $self->dbh()->primary_key_info(
        $self->_catalog_name(),
        $self->_schema_name(),
        $table->name()
    );

    return unless $pk_info;

    my %pk;
    while ( my $pk_col = $pk_info->fetchrow_hashref() ) {

        # KEY_SEQ refers to the "position" of the column in the table,
        # not in the key, and so may start at any random number.
        $pk{ $pk_col->{KEY_SEQ} }
            = $self->_unquote_identifier( $pk_col->{COLUMN_NAME} );
    }

    my @pk = @pk{ sort keys %pk };

    $table->add_candidate_key(@pk)
        if @pk;
}

sub _set_other_keys {
    my $self  = shift;
    my $table = shift;

    my $key_info = $self->dbh()->statistics_info(
        $self->_catalog_name(),
        $self->_schema_name(),
        $table->name(),
        'unique only',
        'quick'
    );

    return unless $key_info;

    my %ck;
    while ( my $ck_col = $key_info->fetchrow_hashref() ) {
        $ck{ $ck_col->{INDEX_NAME} } ||= [];

        $ck{ $ck_col->{INDEX_NAME} }[ $ck_col->{ORDINAL_POSITION} - 1 ]
            = $self->_unquote_identifier( $ck_col->{COLUMN_NAME} );
    }

    for my $key ( values %ck ) {

        # The defined check is another Pg workaround. ORDINAL_POSITION
        # ends up sequential across all keys, which is wack.
        $table->add_candidate_key( grep {defined} @{$key} );
    }
}

sub _add_foreign_keys {
    my $self   = shift;
    my $schema = shift;

    my @keys
        = qw( UK_TABLE_NAME UK_COLUMN_NAME FK_TABLE_NAME FK_COLUMN_NAME );

    for my $table ( $schema->tables() ) {
        my $sth = $self->_fk_info_sth( $table->name() );

        next unless $sth;

        my %fk;
        while ( my $fk_info = $sth->fetchrow_hashref() ) {
            $self->_translate_fk_info($fk_info);

            for my $k (@keys) {
                $fk_info->{$k} = $self->_unquote_identifier( $fk_info->{$k} )
                    if defined $fk_info->{$k};
            }

            # The FK_NAME might not be unique (two tables can use the
            # same FK name).
            my $key = join q{-},
                @{$fk_info}{qw( FK_NAME FK_TABLE_NAME UK_TABLE_NAME )};

            push @{ $fk{$key}{source_columns} },
                $schema->table( $fk_info->{FK_TABLE_NAME} )
                ->column( $fk_info->{FK_COLUMN_NAME} );

            push @{ $fk{$key}{target_columns} },
                $schema->table( $fk_info->{UK_TABLE_NAME} )
                ->column( $fk_info->{UK_COLUMN_NAME} );
        }

        for my $fk_cols ( values %fk ) {
            my $fk = $self->fk_class()->new( %{$fk_cols} );

            $schema->add_foreign_key($fk);
        }
    }
}

{
    my %ODBCToSQL = (
        PKTABLE_NAME  => 'UK_TABLE_NAME',
        PKCOLUMN_NAME => 'UK_COLUMN_NAME',
        FKTABLE_NAME  => 'FK_TABLE_NAME',
        FKCOLUMN_NAME => 'FK_COLUMN_NAME',
        KEY_SEQ       => 'ORDINAL_POSITION',
    );

    sub _translate_fk_info {
        my $self = shift;
        my $info = shift;

        return if $info->{UK_TABLE_NAME};

        while ( my ( $from, $to ) = each %ODBCToSQL ) {
            $info->{$to} = delete $info->{$from};
        }
    }
}

sub _fk_info_sth {
    my $self = shift;
    my $name = shift;

    return $self->dbh()->foreign_key_info(
        $self->_catalog_name,
        $self->_schema_name,
        $name,
        $self->_catalog_name,
        $self->_schema_name,
        undef,
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Base class (and fallback) for loading a schema



=pod

=head1 NAME

Fey::Loader::DBI - Base class (and fallback) for loading a schema

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  my $loader = Fey::Loader->new( dbh => $dbh );

  my $schema = $loader->make_schema( name => $name );

=head1 DESCRIPTION

C<Fey::Loader::DBI> will create a schema by using the various DBI info
methods. It is a complete implementation of a loader, but it only
works if the driver in question fully supports the info methods
needed, which many don't. In addition, some information simply isn't
available via those methods, like whether a column is auto-incremented.

For that reason, you probably won't get good results for your schema
unless there is a driver-specific loader subclass for your DBMS.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Loader::DBI->new( dbh => $dbh )

Given a database handle, returns a new C<Fey::Loader::DBI> object. You
probably want to call C<Fey::Loader->new()> instead, though.

To change the classes used to build up the schema and its related
objects, you may provide C<schema_class>, C<table_class>,
C<column_class>, and C<fk_class> parameters; they default to
C<Fey::Schema>, C<Fey::Table>, C<Fey::Column>, and C<Fey::FK>
respectively.

=head2 $loader->make_schema( name => $name )

This method returns a new, fully-populated C<Fey::Schema> object. The
name parameter is optional, and if given will be used as the name of
the new schema. Otherwise the name will be found through the C<DBI>
handle.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-fey-loader@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

