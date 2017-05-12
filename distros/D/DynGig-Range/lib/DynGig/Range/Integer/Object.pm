=head1 NAME

DynGig::Range::Integer::Object - Implements DynGig::Range::Interface::Object.

=cut
package DynGig::Range::Integer::Object;

use base DynGig::Range::Interface::Object;

use warnings;
use strict;
use Carp;

use overload
    '+=' => \&add,
    '-=' => \&subtract,
    '&=' => \&intersect,
    'eq' => \&equal;

=head1 DESCRIPTION

=head2 min()

Returns the smallest element in range

=cut
sub min
{
    my $this = shift @_;
    return $this->[0];
}

=head2 max()

Returns the largest element in range

=cut
sub max
{
    my $this = shift @_;
    return $this->[-1];
}

=head2 clear()

Returns the object after clearing its content.

=cut
sub clear
{
    my $this = shift @_;

    splice @$this;
    return $this;
}

=head2 empty()

Returns I<true> if object is empty, I<false> otherwise.

=cut
sub empty
{
    my $this = shift @_;
    return @$this == 0;
}

=head2 size()

Returns number of elements in range.

=cut
sub size
{
    my $this = shift @_;
    my $size = 0;
    my $code = sub { $size = 1 - $_[1] + $_[2] };
    
    $this->_traverse( $code );
    return $size;
}

=head2 clone( object )

Returns a cloned object.

=cut
sub clone
{
    my $this = shift @_;
    bless [ @$this ], ref $this;
}

=head2 equal( object )

Overloads B<eq>. Returns 1 if two objects are of equal value, 0 otherwise.

=cut
sub equal
{
    my ( $this, $that ) = @_;

    return 1 if $this == $that;
    return 0 if @$this != @$that;

    map { return 0 if $this->[$_] != $that->[$_] } 0 .. $#$this;
    return 1;
}

=head2 add( object )

Overloads B<+=>. Returns the object after union with another object.

=cut
sub add
{
    my ( $this, $that ) = @_;
    my $code = sub { $this->insert( $_[1], $_[2] ) };

    $that->_traverse( $code ) if $this != $that;
    return $this;
}

=head2 subtract( object )

Overloads B<-=>. Returns the object after subtraction with another object.

=cut
sub subtract 
{
    my ( $this, $that ) = @_;
    my $code = sub { $this->remove( $_[1], $_[2] ) };

    return $this->clear() if $this == $that;
    $that->_traverse( $code );
    return $this;
}

=head2 intersect( object )

Overloads B<&=>. Returns the object after intersection with another object.

=cut
sub intersect 
{
    my ( $this, $that ) = @_;

    splice @$this, 0, scalar( @$this ), @{ $this->Intersect( $that ) }
        if $this != $that;

    return $this;
}

sub Intersect 
{
    my ( $this, $that ) = @_;

    ( $this, $that ) = ( $that, $this ) if @$this < @$that;
    $this = $this->clone();

    my $result = $this->new();
    my $code = sub { $result->add( $this->remove( $_[1], $_[2] ) ) };

    $that->_traverse( $code );
    return $result;
}

=head2 list( skip => boolean )

Boundary value pairs if I<skip> is set. Values of all elements otherwise.
Returns ARRAY reference in scalar context. Returns ARRAY in list context.

=cut
sub list
{
    my ( $this, %param ) = @_;
    my @list;
    my $code = sub
    {
        push @list, $param{skip} ? [ $_[1], $_[2] ] : $_[1] .. $_[2]
    };

    $this->_traverse( $code );
    return wantarray ? @list : \@list;
}

=head2 string( %symbol )

Serializes object as string.

=cut
sub string
{
    my ( $this, %symbol ) = @_;
    my @list;
    my $code = sub
    {
        push @list, $_[1] == $_[2] ? $_[1] : join $symbol{range}, $_[1], $_[2]
    };

    $this->_traverse( $code );
    return join $symbol{list}, @list;
}

=head2 value( indices )

Values of elements to corresponding indices.
Returns ARRAY reference in scalar context.
Returns ARRAY in list context or only one index is given.

=cut
sub value
{
    my $this = shift @_;
    my %result;
    my $size = $this->size();

    goto DONE unless @$this;

    for my $index ( @_ )
    {
        next if defined $result{$index} || $index >= $size || -$index > $size;

        my $j = $index < 0 ? $index + $size : $index;

        for ( my $i = 0; $i < @$this; $i ++ )
        {
            my $x = $this->[$i];
            my $span = 1 - $x + $this->[++ $i];

            if ( $span > $j )
            {
                $result{$index} = $x + $j;
                last;
            }

            $j -= $span;
        }
    }

    DONE: return @result{@_} if @_ < 2;
    return wantarray ? @result{@_} : [ @result{@_} ];
}

=head2 index( values )

Indices of elements to corresponding values.
Returns ARRAY reference in scalar context.
Returns ARRAY in list context or only one value is given.

=cut
sub index
{
    my $this = shift @_;
    my $size = @$this;
    my @size = 0;
    my ( %result, $index );
    my $code = sub { $index += 1 - $_[1] + $_[2] };

    goto DONE unless @$this;

    if ( @_ > 1 )
    {
        my $code = sub { push @size, 1 - $_[1] + $_[2] + $size[-1] };

        $this->_traverse( $code );
        shift @size;
    }
    
    for my $value ( @_ )
    {
        $index = 0;

        next if ! defined $value || defined $result{$value}
            || $value < $this->[0] || $value > $this->[-1];

        my $i = $this->_search( 0, $size, $value );

        next unless $i % 2 || $this->[$i] == $value;

        if ( @_ > 1 )
        {
            $index = $size[ int( $i / 2 ) ];
        }
        else
        {
            $this->_traverse( $code, $i );
        }

        $result{$value} = $index + $value - $this->[$i];
    }

    DONE: return @result{@_} if @_ < 2;
    return wantarray ? @result{@_} : [ @result{@_} ];
}

=head2 subset( index1, index2 )

Returns an object that contains the inclusive subset within indices

=cut
sub subset
{
    my ( $this, @index ) = @_;
    my $size = $this->size();
    my $result = $this->new();

    @index = map { $_ < 0 ? $_ + $size : $_ } @index;

    return $result if @index != 2 || $index[0] > $index[1]
        || $index[0] < 0 || $index[1] < 0 || $index[1] >= $size;

    $index[1] = $size - 1 if $index[1] >= $size;
    $this->Intersect( bless [ $this->value( @index ) ] );
}

=head2 insert( value1, value2 )

Insert elements delimited by two values. Returns the object.

=cut
sub insert 
{
    my ( $this, $x, $y ) = @_;
    my $size = @$this;

    ( $x, $y ) = ( $y, $x ) if $x > $y;

    unless ( $size )
    {
        push @$this, $x, $y;
        return $this;
    }

    my $j = $this->_search( 0, $size, $y );
    my $i = $x == $y ? $j : $this->_search( 0, $j, $x );
    my ( $m, $n ) = ( $x, $y );

    if ( $j % 2 )
    {
        $n = $this->[$j]; 
    } 
    elsif ( $j != $size && $y + 1 >= $this->[$j] ) 
    {
        $n = $this->[++ $j]; 
    } 
    else
    {
        $j --;
    }

    if ( $i % 2 )
    {
        $m = $this->[-- $i];
    }
    else 
    {
        if ( $i == $size ) 
        {
            $j = $size + 1;

            $this->[$i] = $x;
            $this->[$j] = $y;
        }

        $this->[$i] = $x if $x + 1 >= $this->[$i];

        $m = $this->[$i -= 2] if $x - 1 == $this->[$i - 1];
    }

    splice @$this, $i, $j - $i + 1, $m, $n;
    return $this;
}

=head2 remove( value1, value2 )

Remove elements delimited by two values.
Returns an object containing the removed elements.

=cut
sub remove
{
    my ( $this, $x, $y ) = @_;
    my $size = @$this;
    my @diff;
    
    ( $x, $y ) = ( $y, $x ) if $x > $y;

    return bless \@diff unless @$this && $x <= $this->[-1];
    
    my $j = $this->_search( 0, $size, $y );
    my $i = $x == $y ? $j : $this->_search( 0, $j, $x );
    my $append;
    
    if ( $j % 2 == 0 )
    {
        if ( $j != $size && $this->[$j] == $y )
        {
            if ( $this->[$j] == $this->[$j + 1] )
            { 
                $j += 2;
            }   
            else
            {
                $append = 1;
                $this->[$j] = $y + 1;
            }
        }

        $j --;
    }
    elsif ( $this->[$j] != $y )
    {
        splice @$this, $j + 1, 0, $y + 1, $this->[$j];
        $this->[$j] = $y;
    }

    if ( $i % 2 )
    {
        @diff = ( $x, $this->[$i] );
        $this->[$i ++] = $x - 1;
    }

    push @diff, splice @$this, $i, $j - $i + 1 if $j > $i;
    push @diff, $y, $y if $append;

    bless \@diff;
}

=head1 SEE ALSO

See DynGig::Range::Interface::Object for additional methods.

=cut
sub _traverse
{
    my ( $this, $code, $size ) = @_;

    croak 'private method' unless $this->isa( ( caller )[0] );

    my $i = 0;

    $size = defined $size ? $size - $size % 2 : @$this;
    &$code( $i, $this->[ $i ++ ], $this->[ $i ++ ] ) while $i < $size;
}

sub _search
{
    my ( $this, $left, $right, $value ) = @_;
    my $size = @$this;

    return 0 unless $size && $value > $this->[0];
    return $size if $value > $this->[-1];
    return $left if $left == $right;

    my $pivot = int( ( $left + $right ) / 2 );

    return $this->[$pivot] < $value
        ? _search( $this, $pivot + 1, $right, $value )
        : _search( $this, $left, $pivot, $value);
}

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
