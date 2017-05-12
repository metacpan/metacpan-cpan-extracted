package Gapp::FileChooserDialog;
{
  $Gapp::FileChooserDialog::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( ArrayRef );

extends 'Gapp::Dialog';
with 'Gapp::Meta::Widget::Native::Role::FileChooser';

has '+gclass' => (
    default => 'Gtk2::FileChooserDialog',
);

has '+gobject' => (
    handles => ['run'],
);

has '+parent' => (
    is => 'rw',
    isa => 'Maybe[Object]',
    default => undef,
);


before '_build_gobject' => sub {
    my $self = shift;
    $self->set_args( [ ( $self->properties->{title} ? $self->properties->{title} : '' ) ,
                      ( $self->parent ? $self->parent->gobject : undef ),
                      $self->action ] );
};
    


1;

__END__

=pod

=head1 NAME

Gapp::FileChooserDialog - FileChooserDialog Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Window>

=item ............+-- L<Gapp::Dialog>

=item ................+-- L<Gapp::FileChooserDialog>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<action>

=over 4

=item is rw

=item isa Str

=item default open

=back

Describes whether the C<FileChooser> is being used to open an existing file
or to save to a possibly new file. The available options are: C<open>, C<save>,
C<select-folder>, C<create-folder>.

=back

=item B<filters>

=over 4

=item is rw

=item isa ArrayRef[L<Gapp::FileFilter>]

=back

The file filters available to the user in the dialog.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut