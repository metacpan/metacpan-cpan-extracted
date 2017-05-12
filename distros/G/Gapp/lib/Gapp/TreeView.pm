package Gapp::TreeView;
{
  $Gapp::TreeView::VERSION = '0.60';
}

use Moose;
extends 'Gapp::Container';

use Gapp::Util;
use Gapp::Types qw( GappTreeViewColumn );

use Moose::Util;
use MooseX::Types::Moose qw( ArrayRef HashRef );

has '+gclass' => (
    default => 'Gtk2::TreeView',
);

has 'model' => (
    is => 'rw',
    isa => 'Maybe[Object]',
    trigger => sub {
        my ( $self, $newval, $oldval ) = @_;
        
        if ( $self->has_gobject ) {
            $self->gobject->set_model( $newval->gobject );
        }
    }
);

has 'columns' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

has 'data_column' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    # coerce column values if they are not Gapp::TreViewColumn objects
    if ( exists $args{columns} ) {
        
        my @columns;
        
        for my $c ( @{$args{columns}} ) {
            $c = to_GappTreeViewColumn( $c ) if ! is_GappTreeViewColumn( $c );
            push @columns, $c if $c;
        }
        
        $args{columns} = \@columns;
    }
    
    # headers visible
    for my $att ( qw(headers_visible headers_clickable) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

after '_build_gobject' => sub {
    my $self = shift;

    for my $c ( @{ $self->columns } ) {
        $c = to_GappTreeViewColumn( $c ) if ! is_GappTreeViewColumn( $c );
        $self->gobject->append_column( $c->gobject );
        $self->gobject->{columns}{$c->name} = $c->gobject;
    }
};



sub find_column {
    my ( $self, $cname ) = @_;
    
    for my $c ( @{ $self->columns } ) {
        if ( $c->name eq $cname ) {
            return $c;
        }
    }
}

sub get_selected {
    my ( $self ) = @_;
    
    my @records;
    $self->gobject->get_selection->selected_foreach( sub{
        my ( $model, $path, $iter ) = @_;
        push @records, $model->get( $iter, $self->data_column );
        return;
    });
    
    
    return wantarray ? @records : $records[0];
}

1;



__END__

=pod

=head1 NAME

Gapp::TreeView - TreeView Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::TreeView>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<columns>

=over 4

=item is rw

=item isa ArrayRef[L<Gapp::TreeViewColumn>]

=item default []

=back

The columns to add to the treeview.

=item B<data_column>

=over 4

=item is rw

=item isa Int

=item default 0

=back

The default column in the model to retrieve data from. The contents of this
column in the model will be returned when calling C<get_selected>.

=item B<model>

=over 4

=item isa L<Gapp::Model>|GtkModel|Undef

=back

The model to use. May be a L<Gapp::Model> or Gtk2:: object.

=back

An array of L<Gapp::TreeViewColumn> objects to be displayed in the view.

=back

=head1 PROVIDED METHODS

=over 4

=item B<find_column $name>

Searches for and returns a column with the specified name.

=over 4

=item returns L<Gapp::TreeViewColumn>|Undef

=back

=item B<get_selected>

Returns a list of items selected in the view. For each of the rows selected,
the contents from C<data_column> in the model will be returned.

=over 4

=item returns Array|Undef

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
