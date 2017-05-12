=head1 NAME

DynGig::Range::String::Object - Implements DynGig::Range::Interface::Object.

=cut
package DynGig::Range::String::Object;

use base DynGig::Range::Interface::Object;

use warnings;
use strict;

use overload
    '+=' => \&add,
    '-=' => \&subtract,
    '&=' => \&intersect,
    '*=' => \&multiply,
    '@{}' => \&list,
    'eq' => \&equal;

my $_BREAK;

=head1 DESCRIPTION

=head2 clear()

Returns the object after clearing its content.

=cut
sub clear
{
    my ( $this ) = @_;
    $this->_traverse( sub { delete $this->{ $_[0] } } );
}

=head2 empty()

Returns I<true> if object is empty, I<false> otherwise.

=cut
sub empty
{
    my ( $this ) = @_;
    return keys %$this == 0;
}

=head2 size()

Returns number of elements in range.

=cut
sub size
{
    my ( $this ) = @_;
    my $size = 0;

    $this->_traverse( sub { $size ++ } );
    return $size;
}

=head2 equal( object )

Overloads B<eq>. Returns 1 if two objects are of equal value, 0 otherwise.

=cut
sub equal
{
    my ( $this, $that ) = @_;
    my $code = sub
    {
        my $T = $that;
        my $leaf = shift @_;

        $T = $T->{ shift @_ } while @_ && $T;
        $_BREAK = 1 if $T;
    };

    $this->_traverse( $code );
    return $_BREAK ? $_BREAK = 0 : 1;
}

=head2 clone( object )

Returns a cloned object.

=cut
sub clone
{
    my ( $this ) = @_;
    my %clone;
    my $code = sub
    {
        my $T = \%clone;
        my $leaf = shift @_;

        map { $T = $T->{$_} ||= {} } @_;
        map { $T->{$_} = $leaf->{$_} } keys %$leaf;
    };

    $this->_traverse( $code );
    bless \%clone, ref $this;
}

=head2 add( object )

Overloads B<+=>. Returns the object after union with another object.

=cut
sub add
{
    my ( $this, $that ) = @_;
    my $code = sub
    {
        my $T = $this;
        my $leaf = shift @_;

        map { $T = $T->{$_} ||= {} } @_;
        map { $T->{$_} = $leaf->{$_} } keys %$leaf;
    };

    $that->_traverse( $code ) if $this != $that;
    return $this;
}

=head2 subtract( object )

Overloads B<-=>. Returns the object after subtraction with another object.

=cut
sub subtract
{
    my ( $this, $that ) = @_;
    my $code = sub
    {
        my $T = $that;
        my $leaf = shift @_;

        $T = $T->{ shift @_ } while @_ && $T;
        map { delete $leaf->{$_} } keys %$T if $T;
    };

    $this->clear() if $this == $that;
    $this->_traverse( $code ) if %$this;
    return $this;
}

=head2 intersect( object )

Overloads B<&=>. Returns the object after intersection with another object.

=cut
sub intersect
{
    my ( $this, $that ) = @_;
    my $code = sub
    {
        my $T = $that;
        my $leaf = shift @_;

        $T = $T->{ shift @_ } while @_ && $T;
        map { delete $leaf->{$_} } keys %$leaf unless $T;
    };

    $this->_traverse( $code ) if $this != $that;
    return $this;
}

=head2 multiply( object )

Overloads B<*=>. Returns the object after each element in the second object
is appended to all elements in this object. e.g.

( abc, 123 ) * ( 456, xyz ) = ( abc456, abcxyz, 123456, 123xzy )

=cut
sub multiply
{
    my ( $this, $that ) = @_;

    my $splice = sub  ## splice together operands
    {
        my ( $leaf, $tail ) = @_[ 0, -1 ];
        my ( $key, $value ) = %$leaf;

        my $code = sub
        {
            my $B = $leaf;
            shift @_;

            map { $B = $B->{$_} ||= {} } @_;
            $B->{$key} = $value;
        };

        $that->_traverse( $code );
        delete $leaf->{$key};
    };

    my $rehash = sub  ## clean up after splicing
    {
        my $T = $this;

        for ( my $i = 1; $i < $#_; $i ++ )
        {
            my ( $curr, $next ) = @_[ $i, $i + 1 ];

            if ( 1 != grep { /^\d/ } $curr, $next )
            {
                my $A = $T->{$curr}{$next};

                if ( my $B = $T->{ $curr . $next } )
                {
                    map { $B->{$_} = $A->{$_} } keys %$A;
                }
                else
                {
                    $T->{ $curr . $next } = $A;
                }

                delete $T->{$curr}{$next};
                last;
            }

            $T = $T->{$curr};
        }
    };

    $this->_traverse( $splice );
    $this->_traverse( $rehash );

    return $this;
}

=head2 list()

All elements in a list.
Returns ARRAY reference in scalar context. Returns ARRAY in list context.

=cut
sub list
{
    my ( $this ) = @_;
    my @list;
    my $code = sub
    {
        shift @_;
        push @list, join '', @_;
    };

    $this->_traverse( $code );
    return wantarray ? @list : \@list;
}

=head2 string( %symbol )

Returns a normalized range expression. Least effort is made on numeric
compression. Therefore result will not be in "canonical" form. e.g.

a1b, a2b, a9b .. a100b results in a{1~2,9,10~99,100}b instead of a{1~2,9~100}b.

=cut

sub string
{
    my ( $this, %symbol ) = @_;
    my ( %sort, @string );

    my $sort = sub
    {
        my ( $i, @key, @num ) = 0;

        shift @_;
        unshift @_, '' if $_[0] =~ /^\d/;

        ( $key[$i], $num[ $i ++ ] ) = splice @_, 0, 2 while @_;

        pop @num unless defined $num[-1];
        push @{ $sort{ join '0', @key } ||= [ \@key ] }, \@num;
    };

    $this->_traverse( $sort );

    for my $key ( sort keys %sort )
    {
        my @list = ( $sort{$key}, [] );
        my $key = shift @{ $list[0] };
        my ( $count, $size );
        my $null = shift @{ $list[0] } unless @{ $list[0][0] };

        while ( ( $count = @{ $list[0] } ) > 1 )
        {
            $this->_compress( @list, [ 0 .. $count - 1 ], $size );
            $size = @{ $list[1] };
            @list = ( $list[1], [] );

            last if $count == $size || ( $count = $size ) == 1;
        }

        @list = map { [ map { ref $_ ? $_->string( %symbol ) : $_ } @$_ ] }
            $null || (), @{ $list[0] };

        for my $list ( @list )
        {
            my $string = '';

            map { $string .= $key->[$_] . $list->[$_] } 0 .. $#$list;
            $string .= $key->[-1] if @$key > @$list;
            push @string, $string;
        }
    }

    join $symbol{list}, @string;
}

=head1 SEE ALSO

See DynGig::Range::Interface::Object for additional methods.

=cut
sub _traverse { _recurse( [], @_ ) }

sub _recurse ## traverse to leaf level and run code
{
    my ( $node, $branch, $code ) = @_;

    for my $key ( keys %$branch )
    {
        last if $_BREAK;

        push @$node, $key;

        if ( $key eq '' )
        {
            pop @$node;
            &$code( $branch, @$node );
        }
        else
        {
            _recurse( $node, $branch->{$key}, $code );
            pop @$node;
        }

        if ( my $B = $branch->{$key} )
        {
            delete $branch->{$key} unless %$B;
        }
    }
}

sub _compress
{
    my ( $this, $input, $output, $row, $flag ) = @_;
    my %partition;

    for my $col ( 0 .. @{ $input->[0] } - 1 )
    {
        for my $row ( @$row )
        {
            my $val = $input->[$row][$col];

            if ( $flag )
            {
                $val = $val->string( $this->symbol() );
            }
            elsif ( ref $val )
            {
                next;
            }

            push @{ $partition{$col}{$val} }, $row;
        }

        if ( $flag )
        {
            delete $partition{$col} if keys %{ $partition{$col} } == 1;
        }
        elsif ( $partition{$col} )
        {
            my @val = keys %{ $partition{$col} };

            if ( @val == 1 )
            {
                my $node = _Node->new( @val );

                delete $partition{$col};
                map { $input->[$_][$col] = $node } @$row;
            }
        }
    }

    my @col = sort { keys %{ $partition{$a} } <=> keys %{ $partition{$b} } }
        keys %partition;

    if ( @col > 1 )
    {
        map { $this->_compress( $input, $output, $_, $flag ) }
            values %{ $partition{ $col[0] } };
    }
    else
    {
        if ( @col )
        {
            my $node = _Node->new( $flag
                ? map { $input->[$_][ $col[0] ] } @$row
                : keys %{ $partition{ $col[0] } } );

            map { $input->[$_][ $col[0] ] = $node } @$row;
        }

        push @$output, $input->[ $row->[0] ];
    }
}

package _Node;

use strict;
use warnings;

use DynGig::Range::Integer;

sub new
{
    my $class = shift @_;
    my $this = bless {}, ref $class || $class;

    for my $input ( @_ )
    {
        if ( ref $input )
        {
            $this->add( $input )
        }
        else
        {
            my $range = $this->{ length $input } ||= DynGig::Range::Integer->new();
            $range->insert( $input, $input );
        }
    }
    
    return $this;
}

sub add
{
    my ( $this, $that ) = @_;

    return $this if $this == $that;

    while (  my ( $length, $that ) = each %$that )
    {
        if ( $this->{$length} )
        {
            $this->{$length}->add( $that );
        }
        else
        {
            $this->{$length} = $that->clone();
        }
    }

    return $this;
}

sub string
{
    my ( $this, %symbol ) = @_;
    my @list;

    for my $length ( sort { $a <=> $b } keys %$this )
    {
        for my $pair ( $this->{$length}->list( skip => 1 ) )
        {
            push @list, join $symbol{range}, map { sprintf "%0${length}d", $_ }
                $pair->[0] == $pair->[1] ? $pair->[0] : @$pair;
        }
    };

    $symbol{scope_begin} . join( $symbol{list}, @list ) . $symbol{scope_end};
}

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
