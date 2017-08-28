package MYDan::Node::Integer;

=head1 NAME

MYDan::Node::Integer - Integer Range

=head1 SYNOPSIS

 use MYDan::Node::Integer;

 my @a = ( 1, 3, 5 .. 10 );
 my $a = MYDan::Node::Integer->new()->load( \@a );

 my %b = ( 1 => 1, 2 => 1, 4 => 1, 6 => 1 );
 my $b = $a->new()->load( \%b );

 my $c = $a->new()->load( 4, 10 );
 my $d = $a->new()->load( $c );

 $a->add( $b );
 $c->intersect( \%b );
 
=cut
use warnings;
use strict;
use Carp;

use base qw( MYDan::Node::Object );

sub new
{
    my $class = shift;
    my $self = bless { set => [] }, ref $class || $class;
}

=head1 DATA METHODS

=head3 get( $o )

Extracts a set of elements from a supported object.

=cut
sub get
{
    my ( $self, $o ) = @_;
    my $ref = ref $o;
    my $obj = $self->new();

    map { $obj->insert( $_, $_ ) } $ref eq 'ARRAY' ? @$o : $ref eq 'HASH'
        ? keys %$o : $self->isa( $ref ) ? return [ @{ $o->{set} } ]
        : confess "cannot operate on unknown type: $ref";
    return $obj->{set};
}

=head3 load( $o )

Loads from a supported object, or a pair of delimiting elements that
indicate a contiguous range.

=cut
sub load
{
    my ( $self, @o ) = splice @_;
    $self->{set} = @o ? ref $o[0] ? $self->get( @o )
        : $self->new->insert( @o )->{set} : [];
    return $self;
}

=head3 min()

Returns the smallest element in range

=cut
sub min { return $_[0]->{set}[0] }

=head3 max()

Returns the largest element in range

=cut
sub max { return $_[0]->{set}[-1] }

=head3 count()

Returns number of elements in range.

=cut
sub count
{
    my ( $self, $count ) = ( shift, 0 );
    traverse( $self->{set}, sub { $count = 1 - $_[1] + $_[2] } );
    return $count;
}

=head3 list( %param )

Returns boundary pairs if I<skip> is set, values of all elements otherwise.

=cut
sub list
{
    my ( $self, %param, @list ) = @_;
    traverse( $self->{set},
        sub { push @list, $param{skip} ? [ $_[1], $_[2] ] : $_[1] .. $_[2] } );
    return wantarray ? @list : \@list;
}

=head3 value( @index )

Values of @index.

=cut
sub value
{
    my ( $self, %value ) = shift;
    my $set = $self->{set};

    goto DONE unless my $count = $self->count();

    for my $index ( @_ )
    {
        next if defined $value{$index} || $index >= $count || -$index > $count;

        my $j = $index < 0 ? $index + $count : $index;

        for ( my $i = 0; $i < @$set; $i ++ )
        {
            my $x = $set->[$i];
            my $span = 1 - $x + $set->[ ++ $i ];

            if ( $span > $j ) { $value{$index} = $x + $j; last }
            $j -= $span;
        }
    }

    DONE: return @value{@_} if @_ < 2;
    return wantarray ? @value{@_} : [ @value{@_} ];
}

=head3 index( @value )

Indices of @value.

=cut
sub index
{
    my ( $self, %index ) = shift;
    my $set = $self->{set};
    my @size = 0;

    goto DONE unless my $size = @$set;

    if ( @_ > 1 )
    {
        traverse( $set, sub { push @size, 1 - $_[1] + $_[2] + $size[-1] } );
        shift @size;
    }
    
    for my $value ( @_ )
    {
        my $index = ! defined $value || defined $index{$value}
            || $value < $set->[0] || $value > $set->[-1] ? next : 0;
        my $i = search( $set, 0, $size, $value );

        next unless $i % 2 || $set->[$i] == $value;

        if ( @_ > 1 ) { $index = $size[ int( $i / 2 ) ] }
        else { traverse( $set, sub { $index += 1 - $_[1] + $_[2] }, $i ) }

        $index{$value} = $index + $value - $set->[$i];
    }

    DONE: return @index{@_} if @_ < 2;
    return wantarray ? @index{@_} : [ @index{@_} ];
}

=head3 subset( @index )

Returns an object that contains the inclusive subset within two indices.

=cut
sub subset
{
    my $self = shift;
    my $count = $self->count();
    my @index = map { $_ < 0 ? $_ + $count : $_ } @_;

    return $self->new() if @index != 2 || $index[0] > $index[1]
        || $index[0] < 0 || $index[1] < 0 || $index[1] >= $count;

    $index[1] = $count - 1 if $index[1] >= $count;
    $self->Intersect( bless { set => [ $self->value( @index ) ] } );
}

=head1 ARITHMETIC METHODS

( These methods modify the invoking object. )

=head3 add( $o )

Adds a supported object to object.

=cut
sub add
{
    my $self = shift;
    traverse( $self->get( @_ ), sub { $self->insert( $_[1], $_[2] ) } );
    return $self;
}

=head3 subtract( $o )

Subtracts a supported object from object.

=cut
sub subtract 
{
    my $self = shift;
    traverse( $self->get( @_ ), sub { $self->remove( $_[1], $_[2] ) } );
    return $self;
}

=head3 intersect( $o )

Intersects with a supported object.

=cut
sub intersect 
{
    my $self = shift;
    my $result = $self->new();

    traverse( $self->get( @_ ),
        sub { $result->add( $self->remove( $_[1], $_[2] ) ) } );

    $self->{set} = $result->{set};
    return $self;
}

=head3 symdiff( $o )

Takes symmetric difference with a supported object.

=cut
sub symdiff
{
    my $self = shift;
    my $clone = $self->clone;
    my $o = $self->new->load( @_ );
    $self->add( $o )->subtract( $clone->intersect( $o ) );
}

=head3 insert( @value )

Insert elements delimited by two values. Returns invoking object.

=cut
sub insert 
{
    my ( $self, $x, $y ) = @_;
    my $set = $self->{set};
    my $size = @$set;

    $y = $x unless defined $y;
    ( $x, $y ) = ( $y, $x ) if $x > $y;

    unless ( $size ) { push @$set, $x, $y; return $self }

    my $j = search( $set, 0, $size, $y );
    my $i = $x == $y ? $j : search( $set, 0, $j, $x );
    my ( $m, $n ) = ( $x, $y );

    if ( $j % 2 ) { $n = $set->[$j] } 
    elsif ( $j == $size || $y + 1 < $set->[$j] ) { $j -- } 
    else { $n = $set->[ ++ $j ] }

    if ( $i % 2 ) { $m = $set->[ -- $i ] }
    else 
    {
        if ( $i == $size ) 
        {
            $j = $size + 1;
            @$set[ $i, $j ] = ( $x, $y );
        }

        $set->[$i] = $x if $x + 1 >= $set->[$i];
        $m = $set->[ $i -= 2 ] if $x - 1 == $set->[ $i - 1 ];
    }

    splice @$set, $i, $j - $i + 1, $m, $n;
    return $self;
}

=head3 remove( @value )

Remove elements delimited by two values. Returns object of removed elements.

=cut
sub remove
{
    my ( $self, $x, $y ) = @_;
    my $set = $self->{set};
    my $size = @$set;
    
    $y = $x unless defined $y;
    ( $x, $y ) = ( $y, $x ) if $x > $y;

    return bless { set => [] } unless @$set && $x <= $set->[-1];
    
    my $j = search( $set, 0, $size, $y );
    my $i = $x == $y ? $j : search( $set, 0, $j, $x );
    my ( $append, @set );
    
    if ( $j % 2 == 0 )
    {
        if ( $j != $size && $set->[$j] == $y )
        {
            if ( $set->[$j] == $set->[ $j + 1 ] ) { $j += 2 }   
            else { $append = 1; $set->[$j] = $y + 1 }
        }
        $j --;
    }
    elsif ( $set->[$j] != $y )
    {
        splice @$set, $j + 1, 0, $y + 1, $set->[$j];
        $set->[$j] = $y;
    }

    if ( $i % 2 )
    {
        @set = ( $x, $set->[$i] );
        $set->[ $i ++ ] = $x - 1;
    }

    push @set, splice @$set, $i, $j - $i + 1 if $j > $i;
    push @set, $y, $y if $append;
    bless { set => \@set };
}

##  private methods

sub traverse
{
    my ( $set, $code, $size ) = @_;
    my $i = 0;
    $size = defined $size ? $size - $size % 2 : @$set;
    &$code( $i, $set->[ $i ++ ], $set->[ $i ++ ] ) while $i < $size;
}

sub search
{
    my ( $set, $left, $right, $value ) = @_;
    my $size = @$set;

    return 0 unless $size && $value > $set->[0];
    return $size if $value > $set->[-1];
    return $left if $left == $right;

    my $pivot = int( ( $left + $right ) / 2 );

    return $set->[$pivot] < $value
        ? search( $set, $pivot + 1, $right, $value )
        : search( $set, $left, $pivot, $value);
}

1;
