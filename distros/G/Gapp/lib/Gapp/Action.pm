package Gapp::Action;
{
  $Gapp::Action::VERSION = '0.60';
}

use Moose;
with 'MooseX::Clone';
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use MooseX::Types::Moose qw( CodeRef HashRef Object Str  );

has 'code' => (
    is => 'rw',
    isa => 'Maybe[CodeRef]',
    clearer => 'clear_code',
    predicate => 'has_code',
);

has 'icon' => (
    is => 'rw',
    isa => 'Maybe[Str]',
    clearer => 'clear_icon',
    predicate => 'has_icon',
);

has [qw( label name mnemonic accelerator )] => (
    is => 'rw',
    isa => 'Maybe[Str]',
    default => '',
);

has 'tooltip' => (
    is => 'rw',
    isa => 'Maybe[Str]',
    clearer => 'clear_tooltip',
    predicate => 'has_tooltip',
);



sub create_gtk_action {
    my ( $self, @args ) = @_;
    my %opts = (
        name => $self->name,
        label => $self->label,
        tooltip => $self->tooltip,
        icon => $self->icon,
        args => [],
        @args
    );
    
    if ( $opts{icon} ) {
        $opts{'stock-id'} = $opts{icon};
    }
    
    delete $opts{icon};
    my $args = delete $opts{args};
    
    my $gtk_action = Gtk2::Action->new( %opts );
    $gtk_action->signal_connect( activate => sub {
        my ( $w, @gtkargs ) = @_;
        $self->perform( $self, $args, $w, \@gtkargs );
    });
    return $gtk_action;
}

sub create_gapp_image {
    my ( $self, @args ) = @_;
    Gapp::Image->new( gobject => Gtk2::Image->new_from_stock( $self->icon , $args[0] ) );
}

sub create_gtk_image {
    my ( $self, @args ) = @_;
    Gtk2::Image->new_from_stock( $self->icon , $args[0] );
}

sub perform {
    my ( $self, @args ) = @_;
    return $self->code->( $self, @args ) if $self->has_code;
}



1;


__END__

=pod

=head1 NAME

Gapp::Action - Action object

=head1 DESCRIPTION

Actions are callbacks that know how to display themselves on Gapp widgets.
See L<Gapp::Actions> for more information.

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Action>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<code>

=over 4

=item is rw

=item isa CodeRef

=back

The code-block to be executed.

=item B<icon>

=over 4

=item is rw

=item isa Str

=back

The stock id of the icon to apply to the widget. 

=item B<label>

=over 4

=item is rw

=item isa Str

=back

The text label to apply to the widget.

=item B<name>

=over 4

=item is rw

=item isa Str

=back

The name of the action.

=item B<tooltip>

=over 4

=item is rw

=item isa Str

=back

The tooltip to apply to the widget.

=back

=head2 PROVIDED METHODS

=over 4

=item B<create_gtk_action>

Creates and returns a L<Gtk2::Action> object.

=item B<create_gapp_image $size >

Creates and returns a L<Gapp::Image> object.

=item B<create_gtk_image $size>

Creates and returns a L<Gtk2::Image> object.

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
