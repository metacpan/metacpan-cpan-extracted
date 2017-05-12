package Jifty::DBI::Collection::Union;
use strict;
use warnings;

# WARNING --- This is still development code.  It is experimental.

our $VERSION = '0';

# This could inherit from Jifty::DBI, but there are _a lot_
# of things in Jifty::DBI that we don't want, like Limit and
# stuff.  It probably makes sense to (eventually) split out
# Jifty::DBI::Collection to contain all the iterator logic.
# This could inherit from that.

=head1 NAME

Jifty::DBI::Collection::Union - Deal with multiple L<Jifty::DBI::Collection>
result sets as one

=head1 SYNOPSIS

  use Jifty::DBI::Collection::Union;
  my $U = new Jifty::DBI::Collection::Union;
  $U->add( $tickets1 );
  $U->add( $tickets2 );

  $U->GotoFirstItem;
  while (my $z = $U->Next) {
    printf "%5d %30.30s\n", $z->Id, $z->Subject;
  }

=head1 WARNING

This module is still experimental.

=head1 DESCRIPTION

Implements a subset of the L<Jifty::DBI::Collection> methods, but
enough to do iteration over a bunch of results.  Useful for displaying
the results of two unrelated searches (for the same kind of objects)
in a single list.

=head1 METHODS

=head2 new

Create a new L<Jifty::DBI::Collection::Union> object.  No arguments.

=cut

sub new {
    bless {
        data  => [],
        curp  => 0,       # current offset in data
        item  => 0,       # number of indiv items from First
        count => undef,
        },
        shift;
}

=head2 add COLLECTION

Add L<Jifty::DBI::Collection> object I<COLLECTION> to the Union
object.

It must be the same type as the first object added.

=cut

sub add {
    my $self   = shift;
    my $newobj = shift;

    unless ( @{ $self->{data} } == 0
        || ref($newobj) eq ref( $self->{data}[0] ) )
    {
        die
            "All elements of a Jifty::DBI::Collection::Union must be of the same type.  Looking for a "
            . ref( $self->{data}[0] ) . ".";
    }

    $self->{count} = undef;
    push @{ $self->{data} }, $newobj;
}

=head2 first

Return the very first element of the Union (which is the first element
of the first Collection).  Also reset the current pointer to that
element.

=cut

sub first {
    my $self = shift;

    die "No elements in Jifty::DBI::Collection::Union"
        unless @{ $self->{data} };

    $self->{curp} = 0;
    $self->{item} = 0;
    $self->{data}[0]->First;
}

=head2 next

Return the next element in the Union.

=cut

sub next {
    my $self = shift;

    return undef unless defined $self->{data}[ $self->{curp} ];

    my $cur = $self->{data}[ $self->{curp} ];

    # do the search to avoid the count query and then search
    $cur->_do_search if $cur->{'must_redo_search'};

    if ( $cur->_items_counter == $cur->count ) {

        # move to the next element
        $self->{curp}++;
        return undef unless defined $self->{data}[ $self->{curp} ];
        $cur = $self->{data}[ $self->{curp} ];
        $self->{data}[ $self->{curp} ]->goto_first_item;
    }
    $self->{item}++;
    $cur->next;
}

=head2 last

Returns the last item

=cut

sub last {
    die "Last doesn't work right now";
    my $self = shift;
    $self->goto_item( ( $self->count ) - 1 );
    return ( $self->next );
}

=head2 count

Returns the total number of elements in the union collection

=cut

sub count {
    my $self = shift;
    my $sum  = 0;

    # cache the results
    return $self->{count} if defined $self->{count};

    $sum += $_->count for ( @{ $self->{data} } );

    $self->{count} = $sum;

    return $sum;
}

=head2 goto_first_item

Starts the recordset counter over from the first item. the next time
you call L</next>, you'll get the first item returned by the database,
as if you'd just started iterating through the result set.

=cut

sub goto_first_item {
    my $self = shift;
    $self->goto_item(0);
}

=head2 goto_item

Unlike L<Jifty::DBI::Collection/goto_item>, Union only supports going to the
first item in the collection.

=cut

sub goto_item {
    my $self = shift;
    my $item = shift;

    die "We currently only support going to the First item"
        unless $item == 0;

    $self->{curp} = 0;
    $self->{item} = 0;
    $self->{data}[0]->goto_item(0);

    return $item;
}

=head2 is_last

Returns true if the current row is the last record in the set.

=cut

sub is_last {
    my $self = shift;

    $self->{item} == $self->count ? 1 : undef;
}

=head2 items_array_ref

Return a reference to an array containing all objects found by this search.

Will destroy any positional state.

=cut

sub items_array_ref {
    my $self = shift;

    return [] unless $self->count;

    $self->goto_first_item();
    my @ret;
    while ( my $r = $self->next ) {
        push @ret, $r;
    }

    return \@ret;
}

=head1 AUTHOR

Copyright (c) 2004 Robert Spier

All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Jifty::DBI>, L<Jifty::DBI::Collection>

=cut

1;

__END__

