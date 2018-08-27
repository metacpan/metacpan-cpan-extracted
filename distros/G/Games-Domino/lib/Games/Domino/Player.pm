package Games::Domino::Player;

$Games::Domino::Player::VERSION   = '0.31';
$Games::Domino::Player::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Games::Domino::Player - Represents the player of the Domino game.

=head1 VERSION

Version 0.31

=cut

use 5.006;
use Data::Dumper;
use Games::Domino::Params qw(HorC);

use Moo;
use namespace::autoclean;

use overload q{""} => 'as_string', fallback => 1;

has 'name'  => (is => 'ro', isa => HorC, required => 1);
has 'bank'  => (is => 'rw');
has 'score' => (is => 'rw');
has 'show'  => (is => 'rw', default => sub { return 0 });

=head1 DESCRIPTION

It is used internally by L<Games::Domino>.

=head1 METHODS

=head2 save()

Saves the given tile to the bank of the player.

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));

=cut

sub save {
    my ($self, $tile) = @_;

    die("ERROR: Undefined tile found.\n") unless defined $tile;

    push @{$self->{bank}}, $tile;
}

=head2 reset()

Resets player's score and bank (of tiles).

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));
    $player-reset();

=cut

sub reset {
    my ($self) = @_;

    $self->{bank}  = [];
    $self->{score} = 0;
}

=head2 value()

Returns the total value of all the tiles of the current player.

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));
    $player->save(Games::Domino::Tile->new({ left => 5, right => 3 }));
    print "The total value of the player is [" . $player->value . "]\n";

=cut

sub value {
    my ($self) = @_;

    $self->{score} = 0;
    foreach (@{$self->{bank}}) {
        $self->{score} += $_->value;
    }
    return $self->{score};
}

=head2 pick()

Returns  a  matching  tile for the given open ends. If no open ends found it then
returns highest value tile from the bank of the player.

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));
    $player->save(Games::Domino::Tile->new({ left => 5, right => 3 }));
    my $tile = $player->pick();
    print "Tile: $tile\n";

=cut

sub pick {
    my ($self, $left, $right) = @_;

    return $self->_pick($left, $right)
        if (defined($left) && defined($right));

    my $i    = 0;
    my $pos  = 0;
    my $max  = 0;
    my $tile = undef;

    foreach (@{$self->{bank}}) {
        if ($_->value > $max) {
            $max  = $_->value;
            $tile = $_;
            $pos  = $i;
        }
        $i++;
    }

    splice(@{$self->{bank}}, $pos, 1);
    return $tile;
}

=head2 as_string()

Returns  the player object as string.This method is overloaded as string context.
So  if  we  print the object then this method gets called. You can explictly call
this method  as  well. Suppose the  player has 2 tiles then this return something
like [1 | 4] == [5 | 3].

    use strict; use warnings;
    use Games::Domino::Tile;
    use Games::Domino::Player;

    my $player = Games::Domino::Player->new({ name => 'H' });
    $player->save(Games::Domino::Tile->new({ left => 1, right => 4 }));
    $player->save(Games::Domino::Tile->new({ left => 5, right => 3 }));
    print "Player: $player\n";

=cut

sub as_string {
    my ($self) = @_;

    my $bank = '';
    foreach (@{$self->{bank}}) {
        if ($self->show) {
            $bank .= sprintf("[%d | %d]==", $_->left, $_->right);
        } else {
            $bank .= sprintf("[x | x]==");
        }
    }
    $bank =~ s/[\=]+\s?$//;
    $bank =~ s/\s+$//;
    return $bank;
}

#
#
# PRIVATE METHODS

sub _pick {
    my ($self, $left, $right) = @_;

    my $i    = 0;
    my $pos  = 0;
    my $tile = undef;

    # Find all matching tiles.
    my $matched = {};
    foreach (@{$self->{bank}}) {
        my $L = $_->left;
        my $R = $_->right;
        if (($left =~ /$L|$R/) || ($right =~ /$L|$R/)) {
            $pos = $i;
            $tile = $_;
            $matched->{$i} = $tile;
        }
        $i++;
    }

    # Pick the maximum value tile among all the matched ones.
    my $pick = undef;
    my $max = 0;
    foreach (keys %{$matched}) {
        if ($matched->{$_}->value > $max) {
            $max = $matched->{$_}->value;
            $pick = { i => $_, t => $matched->{$_} };
        }
    }

    if (defined($pick)) {
        splice(@{$self->{bank}}, $pick->{i}, 1);
        return $pick->{t};
    }
    return;
}

sub _available_indexes {
    my ($self) = @_;

    return 1 if (scalar(@{$self->{bank}}) == 1);
    return "1..".scalar(@{$self->{bank}});
}

sub _validate_index {
    my ($self, $index) = @_;

    return 0 unless (defined($index) && ($index =~ /^\d+$/));
    return 1 if ((scalar(@{$self->{bank}}) >= $index) && ($index >= 1));
    return 0;
}

sub _validate_tile {
    my ($self, $index, $left, $right) = @_;

    return 0 unless (defined($index) && ($index =~ /^\d+$/));
    return 1 unless (defined $left && defined $right);

    my $tile = $self->{bank}->[$index-1];
    my $L = $tile->left;
    my $R = $tile->right;

    return 1 if (($left =~ /$L|$R/) || ($right =~ /$L|$R/));
    return 0;
}

sub _tile {
    my ($self, $index) = @_;

    return $self->{bank}->[$index-1];
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Games-Domino>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-domino at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Domino>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Domino::Player

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Domino>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Domino>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Domino>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Domino/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Games::Domino::Player
