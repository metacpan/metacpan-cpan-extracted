##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Table.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Table;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :table );
    use Want;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'table' if( !CORE::length( "$self->{tag}" ) );
    $self->{_table_reset_caption} = 1;
    $self->{_table_reset_tbody} = 1;
    $self->{_table_reset_tfoot} = 1;
    $self->{_table_reset_thead} = 1;
    $self->{_table_reset_rows}  = 1;
    $self->{_reset_fields} = [qw( _table_reset_caption _table_reset_tbody _table_reset_tfoot _table_reset_thead _table_reset_rows )];
    my $callback = sub
    {
        my $def = shift( @_ );
        # my $info = [caller(5)];
        # print( STDERR ref( $self ), "::children->callback(add): called from package ", $info->[0], " at line ", $info->[2], " for '", $def->{added}->[0], "'\n" );
        
        # Our children were modified from outside our package.
        # We need to check if it affects our rows and reset the cache accordingly
        unless( $def->{caller}->[0] eq ref( $self ) )
        {
            # my $has_row = 0;
            # for( @{$def->{data}} )
            # {
            #     $has_row++, last if( $self->_is_a( $_ => 'HTML::Object::DOM::Element::TableRow' ) );
            # }
            # $self->_reset_table( 'rows' ) if( $has_row );
            $self->_reset_table( 'all' );
        }
        return(1);
    };
    $self->children->callback( add => $callback );
    $self->children->callback( remove => $callback );
    return( $self );
}

# Note: deprecated property align is inherited

# Note: deprecated property bgColor
sub bgColor : lvalue { return( shift->_set_get_property( 'bgcolor', @_ ) ); }

# Note: deprecated property border
sub border : lvalue { return( shift->_set_get_property( 'border', @_ ) ); }

# Note: property caption
sub caption : lvalue { return( shift->_set_get_section( caption => 'HTML::Object::DOM::Element::TableCaption', @_ ) ); }

# Note: deprecated property cellPadding
sub cellPadding : lvalue { return( shift->_set_get_property( 'cellpadding', @_ ) ); }

# Note: deprecated property cellSpacing
sub cellSpacing : lvalue { return( shift->_set_get_property( 'cellspacing', @_ ) ); }

sub createCaption
{
    my $self = shift( @_ );
    if( $self->{_table_captions} && !$self->_is_table_reset( 'caption' ) && !$self->{_table_captions}->is_empty )
    {
        return( $self->{_table_captions}->first );
    }

    my $list = $self->children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Element::TableCaption' ) });
    my $capt = $list->first;
    if( !$capt )
    {
        $self->_load_class( 'HTML::Object::DOM::Element::TableCaption' ) ||
            return( $self->pass_error );
        $capt = HTML::Object::DOM::Element::TableCaption->new( @_ ) || 
            return( $self->pass_error( HTML::Object::DOM::Element::TableCaption->error ) );
        $capt->close;
        $capt->parent( $self );
        $self->children->unshift( $capt );
        $list->unshift( $capt );
        $self->reset(1);
        $self->_load_class( 'HTML::Object::DOM::Collection' ) ||
            return( $self->pass_error );
        $self->{_table_captions} = HTML::Object::DOM::Collection->new( $list );
        $self->_remove_table_reset( 'caption' );
    }
    return( $capt );
}

sub createTBody { return( shift->_create_tsection( tbody => @_ ) ); }

sub createTFoot { return( shift->_create_tsection( tfoot => @_ ) ); }

sub createTHead { return( shift->_create_tsection( thead => @_ ) ); }

sub deleteCaption { return( shift->_delete_first_element( caption => @_ ) ); }

sub deleteRow
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    return( $self->error({
        message => "Value provided (" . overload::StrVal( $pos // '' ) . ") is not an integer.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( !defined( $pos ) || !$self->_is_integer( $pos ) );
    my $rows = $self->rows;
    my $size = $rows->size;
    return( $self->error({
        message => "Value provided ($pos) is greater than the zero-based number of rows available (" . $rows->size . ").",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $pos > $size );
    return( $self->error({
        message => "Value provided ($pos) is lower than the zero-based number of rows available (" . $rows->size . "). If you want to specify a negative index, it must be between -1 and -${size}",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $pos < 0 && abs( $pos ) > $size );
    $pos = ( $rows->length + $pos ) if( $pos < 0 );
    my $elem = $rows->index( $pos );
    my $parent = $elem->parent;
    my $children = $parent->children;
    my $kid_pos = $children->pos( $elem );
    return( $self->error({
        message => "Unable to find the row element for index $pos",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $kid_pos ) );
    my $rv = $children->splice( $kid_pos, 1 );
    $elem->parent( undef );
    $parent->reset(1);
    $self->_reset_table( 'rows' );
    return( $elem );
}

sub deleteTFoot { return( shift->_delete_first_element( tfoot => @_ ) ); }

sub deleteTHead { return( shift->_delete_first_element( thead => @_ ) ); }

# Note: deprecated property frame
sub frame : lvalue { return( shift->_set_get_property( 'frame', @_ ) ); }

sub insertRow
{
    my $self = shift( @_ );
    my $pos  = shift( @_ );
    my $rows = $self->rows;
    my $size = $rows->size;
    if( defined( $pos ) )
    {
        return( $self->error({
            message => "Value provided (" . overload::StrVal( $pos // '' ) . ") is not an integer.",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( !$self->_is_integer( $pos ) );
        return( $self->error({
            message => "Value provided ($pos) is greater than the zero-based number of rows available (" . $rows->size . ").",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( $pos > $size );
        return( $self->error({
            message => "Value provided ($pos) is lower than the zero-based number of rows available (" . $rows->size . "). If you want to specify a negative index, it must be between -1 and -${size}",
            class => 'HTML::Object::IndexSizeError',
        }) ) if( $pos < 0 && abs( $pos ) > $size );
        $pos = ( $rows->length + $pos ) if( $pos < 0 );
    }
    # "If a table has multiple <tbody> elements, by default, the new row is inserted into the last <tbody>."
    # $self->messagef( 4, "%d tbody found.", $self->tbodies->length );
    my $body = $self->tbodies->last;
    # If there is no tbody and no rows yet, we create a tbody
    if( !$rows->length && !$body )
    {
        $body = $self->createTBody();
    }
    $self->_load_class( 'HTML::Object::DOM::Element::TableRow' ) || return( $self->pass_error );
    my $row;
    # A position was provided
    if( defined( $pos ) )
    {
        # ..., but there are no rows yet
        if( $rows->is_empty )
        {
            # if we have a tbody, we add the new row there
            if( $body )
            {
                $row = $body->insertRow();
            }
            # otherwise, we just add as the last child of the table.
            # However, this should not happen, because if there are no rows and no tbody, oen is created and this condition is never reached
            else
            {
                $self->children->push( $row );
                $row->parent( $self );
                $self->reset(1);
            }
        }
        else
        {
            my $elem = $rows->index( $pos );
            return( $self->error({
                message => "No element could be found at row index $pos",
                class => 'HTML::Object::HierarchyRequestError',
            }) ) if( !defined( $elem ) );
            my $parent = $elem->parent;
            my $children = $parent->children;
            return( $self->error({
                message => "Element at row index $pos has no parent!",
                class => 'HTML::Object::HierarchyRequestError',
            }) ) if( !$parent );
            my $real_pos = $children->pos( $elem );
            return( $self->error({
                message => "Unable to find the row element for index $pos",
                class => 'HTML::Object::HierarchyRequestError',
            }) ) if( !defined( $real_pos ) );
            $row = HTML::Object::DOM::Element::TableRow->new( @_ ) ||
                return( $self->pass_error( HTML::Object::DOM::Element::TableRow->error ) );
            $row->close;
            $row->parent( $parent );
            $children->splice( $real_pos, 0, $row );
            $parent->reset(1);
        }
    }
    # If there is already a tbody, the new row will be added there
    elsif( $body )
    {
        $row = $body->insertRow();
    }
    # otherwise, there are already other rows directly under <table> and the new row is just added at the end of the table, even if there is a <tfoot> element.
    else
    {
        $row = HTML::Object::DOM::Element::TableRow->new( @_ ) ||
            return( $self->pass_error( HTML::Object::DOM::Element::TableRow->error ) );
        $row->close;
        $children->push( $row );
        $row->parent( $self );
        $self->reset(1);
    }
    $self->_reset_table( 'rows' );
    return( $row );
}

# Note: property rows read-only
sub rows
{
    my $self = shift( @_ );
    return( $self->{_table_rows} ) if( $self->{_table_rows} && !$self->_is_table_reset( qw( rows tbody tfoot thead ) ) );
    my $results = $self->new_array;
    my $children = $self->children;
    $children->foreach(sub
    {
        my $tag = $_->tag;
        if( $tag eq 'tr' )
        {
            $results->push( $_ );
        }
        elsif( $tag eq 'tbody' || $tag eq 'tfoot' || $tag eq 'thead' )
        {
            my $rows = $_->rows;
            $results->push( $rows->list ) if( !$rows->is_empty );
        }
        return(1);
    });
    unless( $self->{_table_rows} )
    {
        $self->_load_class( 'HTML::Object::DOM::Collection' ) ||
            return( $self->pass_error );
        $self->{_table_rows} = HTML::Object::DOM::Collection->new ||
            return( $self->pass_error( HTML::Object::DOM::Collection->error ) );
    }
    # Re-use the same object, so that we can update the object the user may have retrieved
    # e.g.:
    # my $rows = $table->rows
    # then do some row changes, and
    # say $rows->length; # shows updated number of rows. No need to redo $table->rows
    $self->{_table_rows}->set( $results );
    $self->_remove_table_reset( 'rows' );
    return( $self->{_table_rows} );
}

# Note: deprecated property rules
sub rules : lvalue { return( shift->_set_get_property( 'rules', @_ ) ); }

# Note: deprecated property summary
sub summary : lvalue { return( shift->_set_get_property( 'summary', @_ ) ); }

# Note: property tBodies read-only
sub tBodies { return( shift->_get_tsection_collection( 'tbody' ) ); }

sub tbodies { return( shift->tBodies( @_ ) ); }

# Note: property tFoot
sub tFoot : lvalue { return( shift->_set_get_section( tfoot => 'HTML::Object::DOM::Element::TableSection', @_ ) ); }

sub tfoot : lvalue { return( shift->tFoot( @_ ) ); }

# Note: property tHead
sub tHead : lvalue { return( shift->_set_get_section( thead => 'HTML::Object::DOM::Element::TableSection', @_ ) ); }

sub thead : lvalue { return( shift->tHead( @_ ) ); }

# Note: deprecated property width is inherited

# Common for tbody, thead and tfoot
sub _create_tsection
{
    my $self = shift( @_ );
    my $tag  = shift( @_ ) || return( $self->error( "No tag name was provided for this table section." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $self->_load_class( 'HTML::Object::DOM::Element::TableSection' ) ||
        return( $self->pass_error );
    $opts->{tag} = $tag;
    my $children = $self->children;
    my $elem = HTML::Object::DOM::Element::TableSection->new( %$opts ) ||
        return( $self->pass_error( HTML::Object::DOM::Element::TableSection->error ) );
    $elem->close;
    $elem->parent( $self );
    my $list = $children->grep(sub{ $self->_is_a( $_ => 'HTML::Object::DOM::Element::TableSection' ) && $_->tag eq $tag });
    $self->messagef( 4, "Search for $tag among table children resulted in %d elements.", $list->length );
    if( $tag eq 'tbody' )
    {
        my $last_elem = $list->last;
        $self->message( 4, "Last tbody element is '$last_elem'" );
        if( $last_elem )
        {
            $last_elem->after( $elem );
        }
        else
        {
            $children->push( $elem );
        }
        $self->reset(1);
        $self->_reset_table( $tag );
    }
    elsif( $tag eq 'tfoot' )
    {
        if( $list->is_empty )
        {
            $children->push( $elem );
            $self->reset(1);
            $self->_reset_table( $tag );
        }
        else
        {
            return( $list->first );
        }
    }
    elsif( $tag eq 'thead' )
    {
        if( $list->is_empty )
        {
            my $len = $children->length;
            my $pos;
            for( my $i = 0; $i < $len; $i++ )
            {
                my $e = $children->[$i];
                next if( !$e->_is_a( 'HTML::Object::DOM::Node' ) );
                my $tag = $e->tag;
                if( $tag ne 'caption' && $tag ne 'colgroup' )
                {
                    $pos = $i;
                    $children->splice( $i, 0, $elem );
                    $self->reset(1);
                    $self->_reset_table( $tag );
                    last;
                }
            }
            if( !defined( $pos ) )
            {
                $children->push( $elem );
                $self->reset(1);
                $self->_reset_table( $tag );
            }
        }
        else
        {
            return( $list->first );
        }
    }
    return( $elem );
}

sub _delete_first_element
{
    my $self = shift( @_ );
    my $tag  = shift( @_ ) || return( $self->error( "No tag was provided." ) );
    $tag = lc( $tag );
    my $children = $self->children;
    my $len = $children->length;
    for( my $i = 0; $i < $len; $i++ )
    {
        if( $self->_is_a( $children->[$i] => 'HTML::Object::Element' ) && 
            $children->[$i]->tag eq $tag )
        {
            my $elem = $children->[$i];
            $children->splice( $i, 1 );
            $elem->parent( undef );
            $self->reset(1);
            $self->_reset_table( $tag );
            return( $elem );
        }
    }
    return;
}

sub _get_tsection_collection
{
    my $self = shift( @_ );
    my $tag  = shift( @_ ) || return( $self->error( "No tag name was provided for this table section." ) );
    my $cache_name = "_table_collection_${tag}";
    return( $self->{ $cache_name } ) if( $self->{ $cache_name } && !$self->_is_table_reset( $tag ) );
    my $results = $self->new_array;
    my $children = $self->children;
    $children->foreach(sub
    {
        # if( $_->tag eq $tag && !$self->_is_a( $_ => 'HTML::Object::DOM::Closing' ) )
        if( $_->tag eq $tag )
        {
            $self->message( 4, "Found tag '$tag' -> '", $_->as_string, "'" );
            $results->push( $_ );
        }
    });
    $self->_load_class( 'HTML::Object::DOM::Collection' ) || return( $self->pass_error );
    my $col = HTML::Object::DOM::Collection->new( $results ) ||
        return( $self->pass_error( HTML::Object::DOM::Collection->error ) );
    $self->{ $cache_name } = $col;
    $self->_remove_table_reset( $tag );
    return( $col );
}

sub _is_table_reset
{
    my $self = shift( @_ );
    my @types = @_;
    my $type = shift( @_ );
    if( scalar( @types ) )
    {
        foreach my $type ( @types )
        {
            if( defined( $type ) && CORE::length( $type ) )
            {
                return(1) if( CORE::length( $self->{ "_table_reset_${type}" } ) );
            }
        }
    }
    else
    {
        for( @{$self->{_reset_fields}} )
        {
            return(1) if( CORE::exists( $self->{ $_ } ) && CORE::length( $self->{ $_ } ) );
        }
    }
    return(0);
}

sub _remove_table_reset
{
    my $self = shift( @_ );
    my @types = @_;
    for( @types )
    {
        CORE::delete( $self->{ "_table_reset_${_}" } );
    }
    return( $self );
}

sub _reset_table
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    if( $type eq 'all' )
    {
        for( @{$self->{_reset_fields}} )
        {
            $self->{ $_ } = 1;
        }
    }
    else
    {
        $self->{ "_table_reset_${type}" } = 1;
    }
    $self->rows if( $type eq 'rows' || $type eq 'all' );
    $self->reset(1);
    return( $self );
}

sub _set_get_section : lvalue
{
    my $self = shift( @_ );
    my $tag  = shift( @_ );
    my $class = shift( @_ );
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        my $new = $arg;
        if( !$self->_is_a( $new => $class ) || $new->tag ne $tag )
        {
            my $error = "New ${tag} object provided is not an ${class} object";
            if( $has_arg eq 'assign' )
            {
                $self->error({ message => $error, class => 'HTML::Object::HierarchyRequestError' });
                my $dummy = $error;
                return( $dummy );
            }
            return( $self->error({ message => $error, class => 'HTML::Object::HierarchyRequestError' }) ) if( want( 'LVALUE' ) );
            rreturn( $self->error({ message => $error, class => 'HTML::Object::HierarchyRequestError' }) );
        }
        $new->detach;
        my( $old, $pos );
        my $children = $self->children;
        my $len = $children->length;
        for( my $i = 0; $i < $len; $i++ )
        {
            my $e = $children->[$i];
            my $e_tag = $e->tag;
            if( $e_tag eq $tag )
            {
                $old = $e;
                $pos = $i;
                last;
            }
            # Find out the default position we would insert the new element if there is no previous ($old) element
            elsif( !defined( $pos ) &&
                   (
                    ( $tag eq 'thead' && $e_tag ne 'caption' && $e_tag ne 'colgroup' ) ||
                    ( $tag eq 'tfoot' && $e_tag ne 'caption' && $e_tag ne 'colgroup' && $e_tag ne 'thead' )
                   ) )
            {
                $pos = $i;
            }
        }
        
        if( !defined( $pos ) )
        {
            if( $tag eq 'caption' )
            {
                $pos = 0;
            }
            # For thead, or tfoot, put them as the last element
            else
            {
                $pos = $len;
            }
        }
        
        $self->reset(1);
        $self->_reset_table( $tag );
        $new->parent( $self );
        if( defined( $old ) )
        {
            $children->splice( $pos, 1, $new );
            my $dummy = '';
            return( $dummy ) if( $has_arg eq 'assign' );
            return( $old ) if( want( 'LVALUE' ) );
            rreturn( $old );
        }
        else
        {
            $children->splice( $pos, 0, $new );
            my $dummy = '';
            return( $dummy ) if( $has_arg eq 'assign' );
            return if( want( 'LVALUE' ) );
            rreturn;
        }
    }
    else
    {
        my $list = $self->_get_tsection_collection( $tag );
        return( $list->first );
    }
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Table - HTML Object DOM Table Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Table;
    my $table = HTML::Object::DOM::Element::Table->new || 
        die( HTML::Object::DOM::Element::Table->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the regular L<HTML::Object::DOM::Element> object interface it also has available to it by inheritance) for manipulating the layout and presentation of tables in an HTML document.

Tables can have, in this order:

=over 4

=item 1. an optional L<caption|HTML::Object::DOM::Element::TableCaption> element,

=item 2. zero or more L<colgroup|HTML::Object::DOM::Element::TableCol> elements,

=item 3. an optional L<thead|HTML::Object::DOM::Element::TableSection> element,

=item 4. either one of the following:

=over 8

=item * zero or more L<tbody|HTML::Object::DOM::Element::TableSection> elements

=item * one or more L<tr|HTML::Object::DOM::Element::TableRow> elements

=back

=item 5. an optional L<tfoot|HTML::Object::DOM::Element::TableSection> element

=back

The above is for reference only and is not enforced by this interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Table |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 caption

Is a L<table caption element|HTML::Object::DOM::Element::TableCaption> representing the first L<caption|HTML::Object::DOM::Element::TableCaption> that is a child of the element, or C<undef> if none is found.

When set, if the object does not represent a L<caption|HTML::Object::DOM::Element::TableCaption>, a C<HTML::Object::HierarchyRequestError> error is returned. If a correct object is given, it is inserted in the tree as the first child of this element and the first L<caption|HTML::Object::DOM::Element::TableCaption> that is a child of this element is removed from the tree, if any, and returned.

Example:

    my $table = $doc->getElementsByTagName( 'table' )->first;
    my $old_caption = $table->caption( $new_caption );
    # or
    $table->caption = $new_caption;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/caption>

=head2 rows

Read-only.

Returns a L<HTML Collection|HTML::Object::DOM::Collection> containing all the rows of the element, that is all C<tr> that are a child of the element, or a child of one of its C<thead>, C<tbody> and C<tfoot> children. The rows members of a C<thead> appear first, in tree order, and those members of a C<tbody> last, also in tree order.

Note that for performance improvement, the collection is cached until changes are made that would affect the results.

Example:

    <table id="myTable">
        <tr></tr>
        <tbody>
            <tr></tr>
        </tbody>
    </table>

    my $rows = $doc->getElementById( 'myTable' )->rows;
    say $rows->length; # 2

    <table id="myTable2">
        <tr>
            <td>
                <table>
                    <tr></tr>
                </table>
            </td>
        </tr>
        <tbody>
            <tr></tr>
        </tbody>
    </table>

    my $rows = $doc->getElementById( 'myTable2' )->rows;
    say $rows->length; # Still 2

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/rows>

=head2 tBodies

Read-only.

Returns a L<HTML Collection|HTML::Object::DOM::Collection> containing all the L<tbody|HTML::Object::DOM::Element::TableSection> of the element.

Note that for performance improvement, the collection is cached until changes are made that would affect the results.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/tBodies>

=head2 tbodies

Alias for L</tBodies>

=head2 tFoot

Is a L<HTML::Object::DOM::Element::TableSection> representing the first L<tfoot|HTML::Object::DOM::Element::TableSection> that is a child of the element, or C<undef> if none is found. 

When set, if the object does not represent a L<tfoot|HTML::Object::DOM::Element::TableSection>, a C<HTML::Object::HierarchyRequestError> error is returned.

If a correct object is given, it is inserted in the tree immediately before the first element that is neither a L<caption|HTML::Object::DOM::Element::TableCaption>, a L<colgroup|HTML::Object::DOM::Element::TableCol>, nor a L<thead|HTML::Object::DOM::Element::TableSection>, or as the last child if there is no such element, and the first L<tfoot|HTML::Object::DOM::Element::TableSection> that is a child of this element is removed from the tree, if any.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/tFoot>

=head2 tHead

Is a L<HTML::Object::DOM::Element::TableSection> representing the first L<thead|HTML::Object::DOM::Element::TableSection> that is a child of the element, or C<undef> if none is found. 

When set, if the object does not represent a L<thead|HTML::Object::DOM::Element::TableSection>, a C<HTML::Object::HierarchyRequestError> error is returned.

If a correct object is given, it is inserted in the tree immediately before the first element that is neither a L<caption|HTML::Object::DOM::Element::TableCaption>, nor a L<colgroup|HTML::Object::DOM::Element::TableCol>, or as the last child if there is no such element, and the first L<thead|HTML::Object::DOM::Element::TableSection> that is a child of this element is removed from the tree, if any.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/tHead>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 createCaption

Returns an L<HTML::Object::DOM::Element> representing the first L<caption|HTML::Object::DOM::Element::TableCaption> that is a child of the element. If none is found, a new one is created and inserted in the tree as the first child of the C<table> element.

Example:

    <table>
        <tr><td>Cell 1.1</td><td>Cell 1.2</td><td>Cell 1.3</td></tr>
        <tr><td>Cell 2.1</td><td>Cell 2.2</td><td>Cell 2.3</td></tr>
    </table>

    my $table = $doc->querySelector('table');
    my $caption = $table->createCaption();
    $caption->textContent = 'This caption was created by JavaScript!';

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/createCaption>

=head2 createTBody

Returns a L<HTML::Object::DOM::Element::TableSection> representing a new L<tbody|HTML::Object::DOM::Element::TableSection> that is a child of the element. It is inserted in the tree after the last element that is a L<tbody|HTML::Object::DOM::Element::TableSection>, or as the last child if there is no such element.

Example:

    my $mybody = $mytable->createTBody();
    # Now this should be true: $mybody == mytable->tBodies->item( $mytable->tBodies->length - 1 )

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/createTBody>

=head2 createTFoot

Returns an L<HTML::Object::DOM::Element::TableSection> representing the first L<tfoot|HTML::Object::DOM::Element::TableSection> that is a child of the element. If none is found, a new one is created and inserted in the tree as the last child.

Example:

    my $myfoot = $mytable->createTFoot();
    # Now this should be true: $myfoot == $mytable->tFoot

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/createTFoot>

=head2 createTHead

Returns an L<HTML::Object::DOM::Element::TableSection> representing the first L<thead|HTML::Object::DOM::Element::TableSection> that is a child of the element. If none is found, a new one is created and inserted in the tree immediately before the first element that is neither a L<caption|HTML::Object::DOM::Element::TableCaption>, nor a L<colgroup|HTML::Object::DOM::Element::TableCol>, or as the last child if there is no such element.

Example:

    my $myhead = mytable->createTHead();
    # Now this should be true: $myhead == mytable->tHead

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/createTHead>

=head2 deleteCaption

Removes the first L<caption|HTML::Object::DOM::Element::TableCaption> that is a child of the element and returns the object of the caption element.

Example:

    <table>
        <caption>This caption will be deleted!</caption>
        <tr><td>Cell 1.1</td><td>Cell 1.2</td></tr>
        <tr><td>Cell 2.1</td><td>Cell 2.2</td></tr>
    </table>

    my $table = $doc->querySelector('table');
    $table->deleteCaption();

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/deleteCaption>

=head2 deleteRow

Removes the row corresponding to the index given in parameter. If the index value is C<-1> the last row is removed; if it smaller than C<-1> or greater than the amount of rows in the collection, an C<HTML::Object::IndexSizeError> is returned.

Example:

    <table>
        <tr><td>Cell 1.1</td><td>Cell 1.2</td><td>Cell 1.3</td></tr>
        <tr><td>Cell 2.1</td><td>Cell 2.2</td><td>Cell 2.3</td></tr>
        <tr><td>Cell 3.1</td><td>Cell 3.2</td><td>Cell 3.3</td></tr>
    </table>

    my $table = $doc->querySelector('table');
    # Delete second row
    $table->deleteRow(1);

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/deleteRow>

=head2 deleteTFoot

Removes the first L<tfoot|HTML::Object::DOM::Element::TableSection> that is a child of the element and returns the object of the caption element.

Example:

    <table>
        <thead><th>Name</th><th>Score</th></thead>
        <tr><td>Bob</td><td>541</td></tr>
        <tr><td>Jim</td><td>225</td></tr>
        <tfoot><th>Average</th><td>383</td></tfoot>
    </table>

    my $table = $doc->querySelector('table');
    $table->deleteTFoot();

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/deleteTFoot>

=head2 deleteTHead

Removes the first L<thead|HTML::Object::DOM::Element::TableSection> that is a child of the element and returns the object of the caption element.

Example:

    <table>
        <thead><th>Name</th><th>Occupation</th></thead>
        <tr><td>Bob</td><td>Plumber</td></tr>
        <tr><td>Jim</td><td>Roofer</td></tr>
    </table>

    my $table = $doc->querySelector('table');
    $table->deleteTHead();

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/deleteTHead>

=head2 insertRow

Returns an L<HTML::Object::DOM::Element::TableRow> representing a new row of the table. It inserts it in the rows collection immediately before the C<tr> element at the given index position, if any was provided. If there are no existing rows yet, a L<tbody|HTML::Object::DOM::Element::TableSection> is created and the new row inserted into it. If a table has multiple C<tbody> elements, by default, the new row is inserted into the last C<tbody>.

If the index is not given or is C<-1>, the new row is appended to the collection. If the index is smaller than C<-1>, it will start that far back from the end of the collection array. If index is greater than the number of rows in the collection, an C<HTML::Object::IndexSizeError> error is returned.

Example:

    <table></table>

    $doc->getElementsByTagName('table')->[0]->insertRow();

Table is now:

    <table>
        <tbody>
            <tr></tr>
        </tbody>
    </table>

But if there are already existing rows and no tbody, the new row will merely be added as the las child of the table.

    <table>
        <tr></tr>
    </table>

    $doc->getElementsByTagName('table')->[0]->insertRow();

Table is now:

    <table>
        <tr></tr>
        <tr></tr>
    </table>

Even if there is a C<tfoot>, the new row will be added after:

    <table>
        <tr></tr>
        <tfoot></tfoot>
    </table>

    $doc->getElementsByTagName('table')->[0]->insertRow();

Table is now:

    <table>
        <tr></tr>
        <tfoot></tfoot>
        <tr></tr>
    </table>

If an index is negative, the new row will be added that far back from the end:

    <table>
        <tr id="one"></tr>
        <tr id="two"></tr>
        <tr id="three"></tr>
    </table>

    $doc->getElementsByTagName('table')->[0]->insertRow(-2);

Table is now:

    <table>
        <tr id="one"></tr>
        <tr></tr>
        <tr id="two"></tr>
        <tr id="three"></tr>
    </table>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/insertRow>

=head2 DEPRECATED PROPERTIES

=head2 align

Is a string containing an enumerated value reflecting the align attribute. It indicates the alignment of the element's contents with respect to the surrounding context. The possible values are "left", "right", and "center".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/align>

=head2 bgColor

A string containing the background color of the table. It reflects the obsolete bgcolor attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/bgColor>

=head2 border

Is a string containing the width in pixels of the border of the table. It reflects the obsolete border attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/border>

=head2 cellPadding

Is a string containing the width in pixels of the horizontal and vertical sapce between cell content and cell borders. It reflects the obsolete cellpadding attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/cellPadding>

=head2 cellSpacing

Is a string containing the width in pixels of the horizontal and vertical separation between cells. It reflects the obsolete cellspacing attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/cellSpacing>

=head2 frame

Is a string containing the type of the external borders of the table. It reflects the obsolete frame attribute and can take one of the following values: C<void>, C<above>, C<below>, C<hsides>, C<vsides>, C<lhs>, C<rhs>, C<box>, or C<border>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/frame>

=head2 rules

Is a string containing the type of the internal borders of the table. It reflects the obsolete rules attribute and can take one of the following values: C<none>, C<groups>, C<rows>, C<cols>, or C<all>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/rules>

=head2 summary

Is a string containing a description of the purpose or the structure of the table. It reflects the obsolete summary attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/summary>

=head2 width

Is a string containing the length in pixels or in percentage of the desired width fo the entire table. It reflects the obsolete width attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement/width>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTableElement>, L<Mozilla documentation on table element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/table>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
