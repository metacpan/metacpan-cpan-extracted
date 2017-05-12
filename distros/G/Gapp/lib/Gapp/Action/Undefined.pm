package Gapp::Action::Undefined;
{
  $Gapp::Action::Undefined::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Carp;
extends 'Gapp::Action';


sub perform {
    my ( $self, @args ) = @_;
    carp 'you are calling "perform" on an undefind action (' . $self->name . ')';
}

sub create_gtk_action {
    my ( $self, @args ) = @_;
    my %opts = (
        name => $self->name,
    );
    
    
    my $gtk_action = Gtk2::Action->new( %opts );
    $gtk_action->signal_connect( activate => sub {
        my ( $gtkw, @gtkargs ) = @_;
        $self->perform( $self, \@args, $gtkw,  \@gtkargs );
    });
    return $gtk_action;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Gapp::Action::Undefined - An undefined action

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Action>

=item +-- L<Gapp::Action::Undefined>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut