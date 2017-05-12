package MColPro::Exclude;

=head1 NAME

 MColPro::Exclude - mysql operating for excluding

=cut

use warnings;
use strict;

use Carp;
use Net::MySQL;
use YAML::XS;

sub new
{
    my ( $this, $conf, $sqlbase ) = @_;

    my %class;
    $class{mysql}  = $sqlbase;
    $class{exclude} = $conf->{exclude};

    my $i = 0;
    map { $class{column}{$_} = $i++ }
        qw( time cluster node expire user );

    bless \%class, ref $this || $this;   
}

sub set
{
    my ( $this, %param ) = @_;

    my @c = grep { $this->{column}{$_} > 0 } keys %{ $this->{column} };

    map
    {
        unless( defined $param{$_} )
        {
            warn "$_ not defined";
            return undef;
        }
    } @c;

    my $value = join ',', map { sprintf( "\'%s\'", $param{$_} ) } @c;   
    my $sql = sprintf( "REPLACE INTO %s(%s) VALUES(%s)"
        , $this->{exclude}, join( ',', @c ), $value );

    $this->{mysql}->dbquery( $sql );
}

sub dump
{
    my ( $this, %cond ) = @_;
    my %exclude;

    my @sql;
    while( my ( $column, $values ) = each %cond )
    {
        next unless defined $this->{column}{$column};
        push @sql, sprintf( "%s IN (%s)", $column, 
            join( ',', map{ "\'$_\'" } @$values ) );
    }

    my $sql = sprintf "SELECT * FROM ".$this->{exclude};
    $sql .= " WHERE ".sprintf( " %s", join " AND ", @sql ) if @sql;
    my ( $now, @delete ) = time;
    $this->{mysql}->dbquery( $sql );

    my $record_set = $this->{mysql}->create_record_iterator;
    return \%exclude unless $record_set;
    while ( my $record = $record_set->each )
    {
        my $expire = $record->[$this->{column}{expire}];
        my $cluster = $record->[$this->{column}{cluster}];
        my $node = $record->[$this->{column}{node}];

        next unless defined $expire && defined $cluster && defined $node;

        if( $expire < $now  )
        {
            push @delete, [ $cluster, $node ];
            next;
        }

        if( $node eq 'ALL' )
        {
            $exclude{cluster}{$cluster} = 1;
        }
        else
        {
            $exclude{$cluster}{$node} = 1;
        }
    }

    $this->delete( \@delete );

    return \%exclude;
}

sub delete
{
    my ( $this, $delete ) = @_;

    if( @$delete )
    {
        map
        {
            my $sql = sprintf( "DELETE FROM %s WHERE cluster=\'%s\' AND node=\'%s\'", 
                $this->{exclude}, $_->[0], $_->[1] );

            $this->{mysql}->dbquery( $sql );
        } @$delete;
    }
}

1;
