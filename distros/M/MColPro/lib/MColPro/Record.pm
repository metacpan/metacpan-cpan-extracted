package MColPro::Record;

=head1 NAME

 MColPro::Record - mysql operating for recording 

=cut

use warnings;
use strict;
use utf8;

use Carp;
use YAML::XS;
use Net::MySQL;

sub new
{
    my ( $this, $conf, $sqlbase ) = @_;

    my %class;
    $class{mysql} = $sqlbase;
    $class{record} = $conf->{record};

    my $i = 0;
    map { $class{column}{$_} = $i++ }
        qw( id time type cluster node detail label level locate );

    bless \%class, ref $this || $this;
}

sub insert
{
    my ( $this, %param ) = @_;

    my @c = grep { $this->{column}{$_} > 1 } keys %{ $this->{column} };

    map { return unless defined $param{$_} } @c;

    $this->{mysql}->dbquery
    (
        sprintf( "INSERT INTO %s ( %s ) VALUES ( %s )", $this->{record}
            , ( join ',', @c )
            , ( join ',', map{"'$param{$_}'"} @c ) )
    );
}

sub lastid
{
    my $this = shift;

    my $sql = sprintf "SELECT max(id) FROM %s", $this->{record};
    if( defined $this->{mysql}->dbquery( $sql ) )
    {
        my $record_set = $this->{mysql}->create_record_iterator->each;
        my $maxid = $record_set->[0];
        return $maxid;
    }

    undef;
}

sub init_position
{
    ## get max id before last interval 
    my ( $this, $name, $interval ) = @_;
    return undef unless $name && $interval;
    
    my ( $sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst )
        = localtime( time - $interval );
    $year += 1900;
    $mon  += 1;
    my $btime = sprintf( "%d-%02d-%02d %02d:%02d:%02d"
        , $year, $mon, $day, $hour, $min, $sec ); 
    my $sql = sprintf( 
        "SELECT max(id) FROM %s WHERE time < \'%s\' ORDER BY id DESC LIMIT 1"
        , $this->{record}, $btime );
    $this->{mysql}->dbquery( $sql );
    my $record_set = $this->{mysql}->create_record_iterator->each;
    my $maxid = $record_set->[0];

    $maxid = $this->lastid() unless defined $maxid;

    return $maxid if defined $maxid;

    return 0;
}

sub dump
{
    my ( $this, $name, $cond, $position ) = @_;
    my %result;

    my $last = $this->lastid();

    return ( undef, $position ) unless defined $last;

    return ( undef, $last ) unless defined $name;
    return ( undef, $last ) unless defined $position;

    my @sql;
    while( my ( $column, $values ) = each %$cond )
    {
        next unless defined $this->{column}{$column};

        push @sql, sprintf( "%s IN (%s)", $column, 
            join( ',', map { "\'$_\'" } @{ $values->{in} } ) )
                if $values->{in};

        push @sql, sprintf( "%s NOT IN (%s)", $column, 
            join( ',', map { "\'$_\'" } @{ $values->{notin} } ) )
                if $values->{notin};
    }

    my $sql = sprintf( "SELECT * FROM %s where id > %d"
        , $this->{record}, $position );
    $sql .= sprintf( " AND %s", join " AND ", @sql ) if @sql;

    $this->{mysql}->dbquery( $sql );

    my $record_set = $this->{mysql}->create_record_iterator;
    while ( my $record = $record_set->each )
    {
        my $cluster = $record->[$this->{column}{cluster}];
        my $node = $record->[$this->{column}{node}];
        $result{$cluster}{$node}{label}{$record->[$this->{column}{label}]} = 1;

        utf8::decode( $record->[$this->{column}{detail}] );
        push @{ $result{$cluster}{$node}{detail} }, 
            $record->[$this->{column}{detail}];
        push @{ $result{$cluster}{$node}{id} }, 
            $record->[$this->{column}{id}],
    }

    return ( \%result, $last );
}

1;

__END__
