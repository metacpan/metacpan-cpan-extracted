package Games::Tournament::Swiss::Procedure;
$Games::Tournament::Swiss::Procedure::VERSION = '0.21';
# Last Edit: 2011  2月 27, 21時17分29秒
# $Id: $

use warnings;
use strict;

# use Games::Tournament::Swiss::Config;
use base $Games::Tournament::Swiss::Config::algorithm;


=head1 NAME

Games::Tournament::Swiss::Procedure - A wrapper around a swiss pairing algorithm

=cut

=head1 SYNOPSIS

 my $pairing = $tourney->pairing( \@brackets );
 require Games::Tournament::Swiss::Procedure;
 $pairing->matchPlayers;
 @nextGame = map { @{ $_ } } @{$pairing->matches};

=head1 DESCRIPTION

A number of different swiss pairing algorithms exist. This is a wrapper allowing you to swap in a algorithm in a module via a configuration file.

=head1 REQUIREMENTS

The module that you wrap needs a 'new' constructor and 'matchPlayers' and 'matches' methods.

=head1 METHODS

=head2 new

 In Some/Arbitrary/Swiss/Algorithm.pm:

# a possible constructor

    $algorithm = Some::Arbitrary::Swiss::Algorithm->new(
        round       => $round,
        brackets    => $brackets,
        incompatibles => $tourney->incompatibles,
        byes => $args{byes},
        matches     => [] )

Called in the Class::Tournament::Swiss method, 'pairing'.

=cut 

# sub new { my $self = shift; $self->SUPER::new(@_); }

=head2 matchPlayers

 $pairing->matchPlayers;

Run the algorithm adding matches to $pairing->matches. A setter.

=cut 

# sub matchPlayers { my $self = shift; $self->SUPER::matchPlayers(@_); }


=head2 matches

	%matches = map { $n++ => $_ } @{$pairing->matches}

Gets/sets the matches which the algorithm made. Returns an anonymous array of anonymous arrays of Games::Tournament::Card objects representing the matches in the individual brackets.

=cut

# sub matches { my $self = shift; $self->SUPER::matches(@_); }


=head2 incompatibles

	$pairing->incompatibles

You may want to have an incompatibles accessor, getting/setting an anonymous hash, keyed on the pairing numbers of the two opponents, of a previous round in which individual pairs of @grandmasters, if any, met. Such a hash is calculated by Games::Tournament::Swiss::incompatibles. B1

=cut

# sub incompatibles { }


=head2 byes

	$group->byes

You may want to have a byes accessor, getting/setting a anonymous hash, keyed on pairing numbers of players, of a previous round in which these players had a bye. Such a hash is calculated by Games::Tournament::Swiss::byes. B1

=cut

# sub byes { }

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-swiss at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-Swiss>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::Swiss

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-Swiss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-Swiss>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-Swiss>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-Swiss>

=back

=head1 ACKNOWLEDGEMENTS

See L<http://www.fide.com/official/handbook.asp?level=C04> for the FIDE's Swiss rules.

See L<http://www.math.utoronto.ca/jjchew/software/tsh/doc/all.html#_pairing_> for John Chew's perl script tsh and some competition systems principles.

See L<http://search.cpan.org/dist/Algorithm-Pair-Swiss> for a swiss pairing algorithm.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Swiss::Procedure

# vim: set ts=8 sts=4 sw=4 noet:
