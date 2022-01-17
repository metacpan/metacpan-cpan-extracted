use strict;
use warnings;

package minitree;

{
    my( @parent, @next_sibling, @previous_sibling, @first_child, @name, @value, @attributes, @pos );
    my $last_obj = 0;
  
    sub new
    {
        my $class      = shift( @_ );
        my $att_class  = shift( @_ );
        my %attributes = @_;
      
        $last_obj++;
        my $id = $last_obj;

        my $self = bless( \$id, $class );

        $self->name( $attributes{name} );
        delete( $attributes{name} );
        $self->value( $attributes{value} );
        delete( $attributes{value} );

        my @node_attributes = map{ $att_class->new( $self, $_ => $attributes{$_} ) } sort( keys( %attributes ) );
        $self->attributes( \@node_attributes );
        return( $self );
    }
    
    BEGIN
    {
        foreach my $method ( qw( parent next_sibling previous_sibling first_child name value pos ) )
        {
            no strict 'refs';
            *{$method} = sub
            {
                my $self = shift( @_ );
                # print( STDERR ref( $self ), "::$method: returning ", scalar( @{ ${$method}[$$self] } ), " elements.\n" );
                if( @_ )
                {
                    ${$method}[$$self] = shift( @_ );
                }
                # print( STDERR ref( $self ), "::$method: returning ", ${$method}[$$self], "\n" );
                return( ${$method}[$$self] );
            };
        }
    }

    sub attributes
    {
        my $self = shift( @_ );
        if( @_ )
        {
            $attributes[ $$self ] = shift( @_ );
        } 
        return( $attributes[ $$self ] || [] );
    };

    sub root
    {
        my $self = shift( @_ );
        while( $self->parent )
        {
            $self = $self->parent;
        }
        return( $self );
    }

    sub last_child
    {
        my $self = shift( @_ );
        my $child = $self->first_child || return;
        while( $child->next_sibling )
        {
            $child = $child->next_sibling;
        }
        return( $child );
    }

    sub children
    {
        my $self = shift( @_ );
        my @children;
        my $child = $self->first_child || return;
        while( $child )
        {
            push( @children, $child );
            $child = $child->next_sibling;
        }
        return( @children );
    }

    sub add_as_last_child_of
    {
        my( $child, $parent)= @_;
        $child->parent( $parent);
        if( my $previous_sibling= $parent->last_child )
        {
            $previous_sibling->next_sibling( $child );
            $child->previous_sibling( $previous_sibling);
        }
        else
        {
            $parent->first_child( $child );
        }
    }

    sub set_pos
    {
        my $self = shift( @_ );
        my $pos  = shift( @_ ) || 1;
        $self->pos( $pos++ );
        foreach my $att (@{$self->attributes})
        {
            $att->pos( $pos++ );
        }
        foreach my $child ( $self->children )
        {
            $pos= $child->set_pos( $pos);
        }
        return( $pos );
    }

    sub dump
    {
        my $self= shift( @_ );
        my @fields = qw( name value pos );
        return(
            "$$self : " .
            join( ' - ', map{ "$_ : " . $self->$_ }  @fields ) .
            ' : ' . 
            join( ' - ', map{ $_->dump } @{$self->attributes} )
        );
    }
 
    sub dump_all
    {
        my $class = shift( @_ );
        foreach my $id ( 1..$last_obj )
        {
            my $self = bless( \$id, $class );
            print( $self->dump, "\n" );
        }
    }
}
      
package attribute;

{
    my( @name, @value, @parent, @pos );
    my $last_obj = 0;

    sub new
    {
        my( $class, $parent, $name, $value ) = @_;
        my $id = $last_obj++;
        my $self = bless( \$id, $class );

        $self->name( $name );
        $self->value( $value );
        $self->parent( $parent );
        return( $self );
    }

    BEGIN
    {
        foreach my $method ( qw( parent name value pos ) )
        {
            no strict 'refs';
            *{$method}= sub
            {
                my $self = shift( @_ );
                if( @_ )
                {
                    ${$method}[ $$self ] = shift( @_ );
                } 
                return( ${$method}[ $$self ] );
            };
        }
    }

    sub dump
    {
        my $self = shift( @_ );
        return( $self->name . ' => ' . $self->value . ' (' . $self->pos . ')' );
    }
}

1;
      
__END__

