package Game::Sternhalma::Error;

use 5.014;
use strict;
use warnings;

use Carp ();
use overload '""' => sub { $_[0]->message }, bool => sub { 1 }, fallback => 1;

our $VERSION = '0.01';

# A PROGRAMMER'S MISTAKE, NOT A PLAYER'S. A move that is not allowed is a flag
# Game::Sternhalma::play returns; this is what a constructor or replay dies
# with when it was given something no game can be made of. A plain blessed
# hash: it needs no accessors made for it, and overloading is simplest there.

our %CODE = (
    bad_layout => 1,
    bad_first  => 1,
    bad_cap    => 1,
    bad_log    => 1,
    bad_position => 1,
);

sub throw {
    my ($class, $code, $detail) = @_;
    Carp::croak("Game::Sternhalma::Error: no such error as '" . (defined $code ? $code : 'undef') . "'")
        unless defined $code && $CODE{$code};
    my ($pkg, $file, $line) = caller(1);
    ($file, $line) = (caller(0))[1, 2] unless defined $file;
    my $self = bless {
        code    => $code,
        detail  => defined $detail ? $detail : '',
        message => "Game::Sternhalma: $code: " . (defined $detail ? $detail : '') . " at $file line $line.\n",
    }, $class;
    die $self;
}

sub code    { $_[0]{code} }
sub detail  { $_[0]{detail} }
sub message { $_[0]{message} }
sub codes   { sort keys %CODE }

1;

__END__

=head1 NAME

Game::Sternhalma::Error - what Game::Sternhalma dies with when it is misused

=head1 SYNOPSIS

    my $game = eval { Game::Sternhalma->new(seats => 5) };
    if (ref $@ && $@->isa('Game::Sternhalma::Error')) {
        print $@->code, "\n";                   # bad_layout
        print $@->detail, "\n";                 # five cannot play: ...
    }

=head1 DESCRIPTION

A move a player may not make is never an exception: L<Game::Sternhalma/play>
returns a flag. This is for a program that asks for something no game can be
made of: five seats, a first seat the game does not have, a cap of nothing, a
log that is not a game. It stringifies to a message with where it was thrown.

=head1 METHODS

=head2 throw

    Game::Sternhalma::Error->throw($code, $detail)

Dies with a new error. C<$code> is one of L</codes>.

=head2 code

C<bad_layout>, C<bad_first>, C<bad_cap>, C<bad_position> or C<bad_log>.

=head2 detail

What was wrong, in words.

=head2 message

The whole message, as the error stringifies.

=head2 codes

Every code there is.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
