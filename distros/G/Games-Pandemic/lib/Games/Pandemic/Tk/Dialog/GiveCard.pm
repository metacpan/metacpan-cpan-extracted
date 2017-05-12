#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Dialog::GiveCard;
{
  $Games::Pandemic::Tk::Dialog::GiveCard::VERSION = '1.120510';
}
# ABSTRACT: pandemic dialog to give cards

use Moose;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;
use Tk::Sugar;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Tk::Utils qw{ image };
use Games::Pandemic::Utils;

Readonly my $K => $poe_kernel;


# -- accessors

has cards => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has players => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has _card   => ( is=>'rw', weak_ref=>1, isa=>'Games::Pandemic::Card::City' );
has _player => ( is=>'rw', weak_ref=>1, isa=>'Games::Pandemic::Player' );


# -- initialization

sub _build_title   { T('Sharing') }
sub _build_header  { T('Give a card') }
sub _build__ok     { T('Give') }
sub _build__cancel { T('Cancel') }


# -- gui methods

#
# $dialog->_valid;
#
# request to give a card & destroy the dialog.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'action', 'share', $self->_card, $self->_player );
    $self->_close;
}


# -- private methods

#
# $main->_valid;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;

    my $fcenter = $top->Frame->pack(top, xfill2);


    # if more than one player, select which one will receive the card
    my @players = $self->players;
    $self->_set_player( $players[0] );
    if ( @players > 1 ) {
        # enclose players in their own frame
        my $f = $fcenter->Frame->pack(left, pad10, NW);
        $f->Label(
            -text   => T('Select player receiving the card:'),
            -anchor => 'w',
        )->pack(top, fillx);

        # display players
        my $selplayer = $self->_player->role;
        foreach my $player ( @players ) {
            # to display a radiobutton with image + text, we need to
            # create a radiobutton with a label just next to it.
            my $fplayer = $f->Frame->pack(top, fillx);
            my $rb = $fplayer->Radiobutton(
                -text     => $player->role,
                -variable => \$selplayer,
                -value    => $player->role,
                -anchor   => 'w',
                -command  => sub{ $self->_set_player($player); },
            )->pack(left, xfillx);
            my $lab = $fplayer->Label(
                -image    => image( $player->image('icon', 32), $top ),
            )->pack(left);
            $lab->bind( '<1>', sub { $rb->invoke; } );
        }
    }

    # if more than one card, select which one to give
    my @cards = $self->cards;
    $self->_set_card( $cards[0] );
    if ( @cards > 1 ) {
        # enclosed cards in their own frame
        my $f = $fcenter->Frame->pack(left, fillx, pad10, NW);
        $f->Label(
            -text   => T('Select city card to give:'),
            -anchor => 'w',
        )->pack(top, fillx);

        # display cards
        my $selcard = $self->_card->label;
        foreach my $card ( @cards ) {
            # to display a radiobutton with image + text, we need to
            # create a radiobutton with a label just next to it.
            my $fcity = $f->Frame->pack(top, fillx);
            my $rb = $fcity->Radiobutton(
                -image    => image($card->icon, $top),
                -variable => \$selcard,
                -value    => $card->label,
                -command  => sub { $self->_set_card($card); },
            )->pack(left);
            my $lab = $fcity->Label(
                -text   => $card->label,
                -anchor => 'w',
            )->pack(left, fillx);
            $lab->bind( '<1>', sub { $rb->invoke; } );
        }
    }
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Dialog::GiveCard - pandemic dialog to give cards

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::GiveCard->new(
        parent  => $mw,
        cards   => \@cards,
        players => \@players,
    );

=head1 DESCRIPTION

The game allows player to give cards to each other, provided that the
players are in the same city.

This dialog will show the C<@cards> of current player, with the list of
C<@players> currently in the city. When clicking ok, the selected card
will be given to the selected player. This takes one action, and is
handled by L<Games::Pandemic::Controller>.

=for Pod::Coverage BUILD

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

