package Gapp::Widget;
{
  $Gapp::Widget::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
extends 'Gapp::Object';

has '+gobject' => (
    handles => [qw( destroy hide present show show_all )],  
);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

# if the widget should be homogenous
has 'homogeneous' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

# if the widget should expand its container
has 'expand' => (
    is => 'rw',
    isa => 'Bool',
    default => 1 ,
);

# if the widget should fill its container
has 'fill' => (
    is => 'rw',
    isa => 'Bool',
    default => 1 ,
);

# the grwapper wraps encapsulates a widget
has 'gwrapper' => (
    is => 'rw',
    isa => 'Maybe[Gtk2::Object]',
    reader => 'get_gwrapper',
    writer => 'set_gwrapper',
    default => undef,
);

sub gwrapper {
    my ( $self ) = @_;
    $self->get_gwrapper || $self->gobject;
};


# padding around widget in container
has 'padding' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

# the parent is set when the widget is added
# to a container widget
has 'parent' => (
    is => 'rw',
    isa => 'Maybe[Gapp::Widget]',
    weak_ref => 1,
);

#has 'toplevel' => (
#    is => 'rw',
#    isa => 'Maybe[Gapp::Widget]',
#    weak_ref => 1,
#);

# tooltip to display
has 'tooltip' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);






sub toplevel {
    my ( $self ) = @_;
    return $self if ! $self->parent;
    
    $self->parent ? $self->parent->toplevel : $self;
}




sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    if ( exists $args{alignment} ) {
        $args{properties}{xalign} = $args{alignment}[0];
        $args{properties}{yalign} = $args{alignment}[1];
        delete $args{alignment};
    }
    
    # headers visible
    for my $att ( qw(visible sensitive xalign yalign no_show_all) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}


# this stores a reference to the Gapp::Object within the Gtk2::Widget
# this is done so that if the only-references to the Gapp::Object
# go away before the Gtk2::Widget - the Gapp::Object is still
# available to reference in callbacks - when the Gtk2::Widget is
# destroyed, then the circular reference will be deleted as well

after '_build_gobject' => sub {
    my ( $self ) = @_;
    
    if ( $self->gobject->isa('Gtk2::Widget') ) {
        $self->gobject->{_gapp} = $self;
        $_[0]->{_gapp} = undef;
    }
};



    

1;

__END__

=pod

=head1 NAME

Gapp::Widget - The base class for all Gapp widgets

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=back

=head1 DESCRIPTION

All Gapp widgets inherit from L<Gapp::Widget>.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<expand>

=over 4

=item isa: Bool

=item default: 0

=back

If the widget should expand inside it's container. (Tables widgets ignore this
value because widget expansion is determind by the L<Gapp::TableMap>)

=item B<fill>

=over 4

=item isa: Bool

=item default: 0

=back

If the widget should fill it's container. (Tables widgets ignore this value
because widget layout is determind by the L<Gapp::TableMap>)

=back

=item B<gwrapper>

=over 4

=item is rw

=item isa Gtk2::Widget

=item writer set_gwrapper

=item reader get_gwrapper

=back

The C<gwrapper> is a widget that encapsulates the C<gobject>. This is useful when
creating composite widgets. To retrieve the value of the C<gwrapper> attribute use
the C<get_gwrapper> method. Calling the C<grwapper> will return the C<gwrapper>
if one has been set, otherwise it will return the C<gobject>. 

=item B<padding>

=over 4

=item isa: Int

=item default: 0

=back

Padding around the widget.

=item B<parent>

=over 4

=item isa L<Gapp::Widget>|Undef

=item default undef

=back

The parent widget.

=item B<tooltip>

=over 4

=item isa Str|Undef

=back

The tooltip to display over the widget.

=head1 PROVIDED METHODS

=over 4

=item B<toplevel>

Searches through the widget heirachy to find the furthest widget up the chain
with no parent widget. Returns the calling widget if it has no parent.

=over 4

=item returns L<Gapp::Widget>

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
