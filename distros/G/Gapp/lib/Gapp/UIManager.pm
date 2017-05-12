package Gapp::UIManager;
{
  $Gapp::UIManager::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
extends 'Gapp::Object';

use Gapp::ActionGroup;

has '+gclass' => (
    default => 'Gtk2::UIManager',
);

has 'files' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

has 'actions' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

has 'action_args' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

after _construct_gobject => sub {
    my $self = shift;
   $self->gobject->add_ui_from_file( $_ ) for @{ $self->files };
   $self->_apply_actions_to_gobject;
};

sub _apply_actions_to_gobject {
    my ( $self ) = @_;
    
    my $group = Gapp::ActionGroup->new( actions => [@{$self->actions}], action_args => [@{$self->action_args}] );
    $self->gobject->insert_action_group( $group->gobject, 0 );
}

1;

__END__

=pod

=head1 NAME

Gapp::UIManager - UIManager object

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::UIManager>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<acton_args>

=over 4

=item isa: ArrayRef

=back

=item B<actions>

=over 4

=item isa: ArrayRef

=back

=item B<files>

=over 4

=item isa: ArrayRef

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
