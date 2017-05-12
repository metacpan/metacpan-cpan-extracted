=head1 NAME

DynGig::Automata::EZDB::Exclude - Extends DynGig::Util::EZDB.

=cut

package DynGig::Automata::EZDB::Exclude;

use base DynGig::Util::EZDB;

use warnings;
use strict;

=head1 SCHEMA
 
 alpha INTEGER NOT NULL,
 omega INTEGER NOT NULL,
 key TEXT NOT NULL,
 value TEXT,
 PRIMARY KEY ( key )

=cut
sub new
{
    DynGig::Util::EZDB->schema
    (
        alpha => 'INTEGER NOT NULL',
        omega => 'INTEGER NOT NULL',
        key   => 'TEXT NOT NULL PRIMARY KEY',
        value => 'TEXT',
    );

    bless DynGig::Util::EZDB::new( @_ ), __PACKAGE__;
}

=head1 SYNOPSIS

See DynGig::Util::EZDB for other methods.

 my $table = 'table1';
 my $start = time;
 my $end = $start + 3600;

 $db->set( $table, $start, $end, 'key1', 'value1' );

 $db->get( $table, time );
 $db->get( $table );

 $db->expire( $table, time );
 $db->expire( $table );

=cut
sub set  ## enter a record into a table
{
    my ( $this, $table, $epoch, $period, $key, $value ) = @_;

    map { return unless _numeric( $_ ) } $epoch, $period;
    return unless defined $key && ( $period += $epoch ) > time;

    $value = '' if ! defined $value;

    my @time = map { int $_ } $epoch, $period;
    my $result = $this->_execute( $table, 'insert', @time, $key, $value );
}

sub get  ## get active records from a table
{
    my ( $this, $table, $epoch ) = @_;

    $epoch = _numeric( $epoch ) ? int $epoch : time;

    my ( $result, $sth ) = $this->_execute( $table, 'select', $epoch, $epoch );

    $result = $sth->fetchall_arrayref() if $result;

    return wantarray ? @$result : $result;
}

sub expire  ## delete expired records from a table
{
    my ( $this, $table, $epoch ) = @_;

    $epoch = _numeric( $epoch ) ? int $epoch : time;

    my $result = $this->_execute( $table, 'expire', int $epoch );
}

sub _statement
{
    my ( $this, $table ) = @_;

    DynGig::Util::EZDB::_statement( $this, $table );

    my $dbh = $this->{dbh};
    my $sth = $this->{sth}{$table} ||= {};
    my $neat = DBI::neat( $table );

    my %op =
    (
        expire => 'DELETE FROM %s WHERE omega < ?',
        select => 'SELECT * FROM %s WHERE alpha <= ? AND omega >= ?',
    );

    map { $sth->{$_} = $dbh->prepare( sprintf $op{$_}, $neat ) } keys %op;
}

sub _numeric
{
    return defined $_[0] && ! ref $_[0] && $_[0] =~ /^\d+(\.\d+)?$/;
}

=head1 NOTE

See DynGig::Automata

=cut

1;

__END__
