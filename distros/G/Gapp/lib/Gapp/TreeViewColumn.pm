package Gapp::TreeViewColumn;
{
  $Gapp::TreeViewColumn::VERSION = '0.60';
}

use Moose;
extends 'Gapp::Object';

use Gapp::CellRenderer;
use Gapp::Util;
use Gapp::Types qw( GappCellRenderer GappTreeViewColumn );

use Moose::Util;
use MooseX::Types::Moose qw( Str ArrayRef HashRef CodeRef Undef );

has '+gclass' => (
    default => 'Gtk2::TreeViewColumn',
);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'renderer' => (
    is => 'rw',
    isa => GappCellRenderer|Undef,
    default => sub { Gapp::CellRenderer->new( gclass => 'Gtk2::CellRendererText', property => 'markup' ) },
    coerce => 1,
);

has 'data_column' => (
    is => 'rw',
    isa => 'Int|Undef',
    default => 0,
);

has 'data_func' => (
    is => 'rw',
    isa => 'Str|CodeRef|Undef',
);

has 'sort_enabled' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    trigger => sub {
        my ( $self ) = @_;
        if ( $self->has_gobject ) {
            $self->gobject->set_clickable( 1 );
            $self->gobject->signal_connect( 'clicked', sub {
                $self->gobject->get_tree_view->get_model->set_default_sort_func( sub {
                    my ( $model, $itera, $iterb, $self ) = @_;
                    my $a = $model->get( $itera, $self->data_column );
                    my $b = $model->get( $iterb, $self->data_column );
                    $self->sort_func->( $self, $a, $b );
                }, $self)
            } );
        }
    }
);

has 'sort_func' => (
    is => 'rw',
    isa => 'Maybe[CodeRef]',
    default => sub {
        sub {
            my ( $self, $a, $b ) = @_;
            lc $self->get_cell_value( $a ) cmp lc $self->get_cell_value( $b );
        };
    },
);


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    
    for my $att ( qw(alignment clickable expand fixed_width min_width reordable resizable sizing),
                  qw(sort_column_id sort_indicator sort_order spacing title visible width') ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

sub get_cell_value {
    my ( $self, $input ) = @_;
    
    local $_ = $input;
        
    my $value = $input;
    if ( is_CodeRef( $self->data_func ) ) {
        $value = &{ $self->data_func }( @_ );
    }
    elsif ( is_Str( $self->data_func ) ) {
        my $method = $self->data_func;
        $value = $_ ? $_->$method : '';
    }
    
    return $value;
}


1;



__END__

=pod

=head1 NAME

Gapp::TreeViewColumn - TreeViewColumn Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::TreeViewColumn>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<data_column>

=over 4

=item isa: Int

=item default: 0

=back

The column in the model that to pull data from. This is what will be displayed within the
renderer. You can use the C<data_func> attribute to manipulate the data before it is rendered
in the cell.

=item B<data_func>

=over 4

=item isa: Str|CodeRef|Undef

=back

Use this to manipulate the data from C<data_column> before rendering it in the cell. The return value
is what will be passed to the renderer. The <$_> variable will be set to the data from C<data_column>
within the callback.

=item B<name>

=over 4

=item isa: Str

=item default: undef

=back

By naming your column you can use C<$treeview->find_column( $name )> to retrieve them later.

=item B<renderer>

=over 4

=item isa: L<Gapp::CellRenderer>

=item default: Gapp::CellRenderer->new( gclass => 'Gtk2::CellRendererText', property => 'markup' );

=back

=head1 DELEGATED PROPERIES

=over 4

=item B<alignment>

=item B<clickable>

=item B<expand>

=item B<fixed_width>

=item B<min_width>

=item B<reorderable>

=item B<resizable>

=item B<sizing>

=item B<sort_column_id>

=item B<sort_indicator>

=item B<sort_order>

=item B<spacing>

=item B<title>

=item B<visible_width>

=back 

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


