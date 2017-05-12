package Games::SolarConflict::ComputerPlayer;
{
  $Games::SolarConflict::ComputerPlayer::VERSION = '0.000001';
}

# ABSTRACT: Computer player model

use strict;
use warnings;
use Mouse;

with 'Games::SolarConflict::Roles::Player';

has _fire_time => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    if ( $t > $self->_fire_time + 1 ) {
        $self->spaceship->fire_torpedo();
        $self->_fire_time($t);
    }
}

__PACKAGE__->meta->make_immutable;

no Mouse;

1;



=pod

=head1 NAME

Games::SolarConflict::ComputerPlayer - Computer player model

=head1 VERSION

version 0.000001

=for Pod::Coverage handle_move

=head1 SEE ALSO

=over 4

=item * L<Games::SolarConflict>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


