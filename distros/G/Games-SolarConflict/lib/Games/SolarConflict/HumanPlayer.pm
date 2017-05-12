package Games::SolarConflict::HumanPlayer;
{
  $Games::SolarConflict::HumanPlayer::VERSION = '0.000001';
}

# ABSTRACT: Human player model

use strict;
use warnings;
use Mouse;

with 'Games::SolarConflict::Roles::Player';

__PACKAGE__->meta->make_immutable;

no Mouse;

1;



=pod

=head1 NAME

Games::SolarConflict::HumanPlayer - Human player model

=head1 VERSION

version 0.000001

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


