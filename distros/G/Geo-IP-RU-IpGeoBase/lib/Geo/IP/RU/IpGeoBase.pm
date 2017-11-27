use 5.008;
use strict;
use warnings;

package Geo::IP::RU::IpGeoBase;

our $VERSION = '0.05';

=head1 NAME

Geo::IP::RU::IpGeoBase - look up location by IP address in Russia

=head1 DESCRIPTION

This module allows you to look up location in DB provided by
http://ipgeobase.ru service. Access to the DB is free. Contains
information about city, region, federal district and coordinates.

DB provided as plain text files and is not very suitable for look
ups without loading all data into memory. Instead it's been decided
to import data into a database. Use command line utility to create
and update back-end DB.

At this moment DB can be created in SQLite, mysql and Pg. If
you create table manually then probably module will just work.
It's very easy to add support for more back-end DBs. Patches are
welcome.

=head1 METHODS

=head2 new

Returns a new object. Takes a hash with options, mostly
description of the back-end:

    Geo::IP::RU::IpGeoBase->new( db => {
        dbh => $dbh, table => 'my_table',
    } );
    # or
    Geo::IP::RU::IpGeoBase->new( db => {
        dsn => 'dbi:mysql:mydb',
        user => 'root', pass => 'secret',
        table => 'my_table',
    } );

=over 4

=item * dbh - connected L<DBI> handle, or you can use dsn.

=item * dsn, user, pass - DSN like described in L<DBI>, for
example 'dbi:SQLite:my.db', user name and his password.

=item * table - name of the table with data, default
is 'ip_geo_base_ru'.

=back

=cut

sub new {
    my $proto = shift;
    my $self = bless { @_ }, ref($proto) || $proto;
    return $self->init;
}

sub init {
    my $self = shift;

    die "No information about database"
        unless my $db = $self->{'db'};

    unless ( $db->{'dbh'} ) {
        die "No dsn and no dbh" unless $db->{'dsn'};

        require DBI;
        $db->{'dbh'} = DBI->connect(
            $db->{'dsn'}, $db->{'user'}, $db->{'pass'},
            { RaiseError => 0, PrintError => 0 }
        ) or die "Couldn't connect to the DB: ". DBI->errstr;
        $db->{'dbh'}->do("SET NAMES 'utf8'");
        $db->{'decode'} = 1;
    } else {
        $db->{'decode'} = 1
            unless exists $db->{'decode'};
    }
    if ( $db->{'decode'} ) {
        require Encode;
        $db->{'decoder'} = Encode::find_encoding('UTF-8');
    }

    $db->{'driver'} = $db->{'dbh'}{'Driver'}{'Name'}
        or die "Couldn't figure out driver name of the DB";

    $db->{'table'} ||= 'ip_geo_base_ru';
    $db->{'quoted_table'} = $db->{'dbh'}->quote_identifier($db->{'table'});

    return $self;
}

=head2 find_by_ip

Takes an IP in 'xxx.xxx.xxx.xxx' format and returns information
about blocks that contains this IP. Yep, blocks, not a block.
In theory DB may contain intersecting blocks.

Each record is a hash reference with the fields matching table
columns: istart, iend, start, end, city, region, federal_district,
latitude and longitude.

=cut

sub find_by_ip {
    my $self = shift;
    my $ip = shift or die 'No IP provided';
    my $int = $self->ip2int($ip);
    return $self->intersections( $int, $int, order => 'ASC', @_ );
}

sub ip2int { return unpack 'N', pack 'C4', split /[.]/, $_[1] }
sub int2ip { return join '.', unpack "C4", pack "N",    $_[1] }

sub intersections {
    my $self = shift;
    my ($istart, $iend, %rest) = @_;
    my $table = $self->db_info->{'quoted_table'};
    my $dbh = $self->dbh;
    my $query = "SELECT * FROM $table WHERE "
        . $dbh->quote_identifier('istart') .' <= '. $dbh->quote($iend)
        .' AND '. $dbh->quote_identifier('iend') .' >= '. $dbh->quote($istart);
    $query .= ' ORDER BY iend - istart '. $rest{'order'}
        if $rest{'order'};
    my $res = $dbh->selectall_arrayref( $query, { Slice => {} } );;
    die "Couldn't execute '$query': ". $dbh->errstr if !$res && $dbh->errstr;
    return @{ $self->decode( $res ) };
}

sub fetch_record {
    my $self = shift;
    my ($istart, $iend) = @_;
    my $table = $self->db_info->{'quoted_table'};
    my $dbh = $self->dbh;
    my $query = "SELECT * FROM $table WHERE "
        . $dbh->quote_identifier('istart') .' = '. $dbh->quote($istart)
        .' AND '. $dbh->quote_identifier('iend') .' = '. $dbh->quote($iend);
    my $res = $self->dbh->selectrow_hashref( $query );
    die "Couldn't execute '$query': ". $dbh->errstr if !$res && $dbh->errstr;
    return $self->decode( $res );
}

sub insert_record {
    my $self = shift;
    my %rec  = @_;

    my $table = $self->db_info->{'quoted_table'};
    my @keys = keys %rec;
    my $dbh = $self->dbh;
    my $query = 
        "INSERT INTO $table(". join( ', ', map $dbh->quote_identifier($_), @keys) .")"
        ." VALUES (". join( ', ', map $dbh->quote( $rec{$_} ), @keys ) .")";
    return $dbh->do( $query ) || die "Couldn't execute '$query': ". $dbh->errstr;
}

sub update_record {
    my $self = shift;
    my %rec  = @_;

    my $table = $self->db_info->{'quoted_table'};

    my @keys = grep $_ ne 'istart' && $_ ne 'iend', keys %rec;
    my $dbh = $self->dbh;
    my $query =
        "UPDATE $table SET "
        . join(
            ' AND ', 
            map $dbh->quote_identifier($_) .' = '. $dbh->quote($rec{$_}),
                @keys
        )
        ." WHERE "
        . join(
            ' AND ', 
            map $dbh->quote_identifier($_) .' = '. $dbh->quote($rec{$_}),
                qw(istart iend)
        );
    return $dbh->do( $query ) || die "Couldn't execute '$query': ". $dbh->errstr;
}

sub delete_record {
    my $self = shift;
    my ($istart, $iend) = @_;
    my $table = $self->db_info->{'quoted_table'};
    my $dbh = $self->dbh;
    my $query = "DELETE FROM $table WHERE "
        . $dbh->quote_identifier('istart') .' = '. $dbh->quote($istart)
        .' AND '. $dbh->quote_identifier('iend') .' = '. $dbh->quote($iend);
    return $dbh->do( $query ) || die "Couldn't execute '$query': ". $dbh->errstr;
}

sub decode {
    my $self = shift;
    my $value = shift;
    return $value unless $self->{'db'}{'decode'};
    return $value unless defined $value;

    my $decoder = $self->{'db'}{'decoder'};
    foreach my $rec ( ref($value) eq 'ARRAY'? (@$value) : ($value) ) {
        $_ = $decoder->decode($_) foreach grep defined, values %$rec;
    }
    return $value;
}

sub process_file {
    my $self = shift;
    my %args = (@_%2? (path => @_) : @_);

    my $file   = $args{'path'};
    my @fields = @{ $args{'fields'} };

    open my $fh, '<:encoding(cp1251)', $file
        or die "Couldn't open $file";

    while ( my $str = <$fh> ) {
        chomp $str;

        my %rec;
        @rec{ @fields } = split /\t/, $str;
        delete $rec{'country'};
        @rec{'start', 'end'} = $self->split_block( delete $rec{'block'} )
            if exists $rec{'block'};

        $args{'callback'}->( \%rec );
    }
    close $fh;
}

sub split_block { return split /\s*-\s*/, $_[1], 2; }


sub db_info { return $_[0]->{'db'} }

sub dbh { return $_[0]->{'db'}{'dbh'} }

sub create_table {
    my $self = shift;

    my $driver = $self->db_info->{'driver'};

    my $call = 'create_'. lc( $driver ) .'_table';
    die "Table creation is not supported for $driver"
        unless $self->can($call);

    return $self->$call();
}

sub create_sqlite_table {
    my $self = shift;

    my $table = $self->db_info->{'quoted_table'};
    my $query = <<END;
CREATE TABLE $table (
    istart INTEGER NOT NULL,
    iend INTEGER NOT NULL,
    start TEXT NOT NULL,
    end TEXT NOT NULL,
    city TEXT,
    region TEXT,
    federal_district TEXT,
    latitude REAL,
    longitude REAL,
    in_update INT NOT NULL DEFAULT(0),
    PRIMARY KEY (istart ASC, iend ASC)
)
END
    return $self->dbh->do( $query )
        || die "Couldn't execute '$query': ". $self->dbh->errstr;
}

sub create_mysql_table {
    my $self = shift;
    my $table = $self->db_info->{'quoted_table'};
    my $query = <<END;
CREATE TABLE $table (
    istart INTEGER UNSIGNED NOT NULL,
    iend INTEGER UNSIGNED NOT NULL,
    start VARCHAR(15) NOT NULL,
    end VARCHAR(15) NOT NULL,
    city TEXT,
    region TEXT,
    federal_district TEXT,
    latitude FLOAT(8,6),
    longitude FLOAT(8,6),
    in_update TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY (istart, iend)
) CHARACTER SET 'utf8'
END
    return $self->dbh->do( $query )
        || die "Couldn't execute '$query': ". $self->dbh->errstr;
}

sub create_pg_table {
    my $self = shift;
    my $table = $self->db_info->{'quoted_table'};
    my $endq = $self->dbh->quote_identifier('end');
    my $query = <<END;
CREATE TABLE $table (
    istart BIGINT NOT NULL,
    iend BIGINT NOT NULL,
    start VARCHAR(15) NOT NULL,
    $endq VARCHAR(15) NOT NULL,
    city TEXT,
    region TEXT,
    federal_district TEXT,
    latitude NUMERIC(8,6),
    longitude NUMERIC(8,6),
    in_update INT2 NOT NULL DEFAULT 0,
    PRIMARY KEY (istart, iend)
)
END
    return $self->dbh->do( $query )
        || die "Couldn't execute '$query': ". $self->dbh->errstr;
}

=head1 AUTHOR

Ruslan Zakirov E<gt>Ruslan.Zakirov@gmail.comE<lt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
