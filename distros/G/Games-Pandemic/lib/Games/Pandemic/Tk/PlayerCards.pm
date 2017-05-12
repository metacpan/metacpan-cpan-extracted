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

package Games::Pandemic::Tk::PlayerCards;
{
  $Games::Pandemic::Tk::PlayerCards::VERSION = '1.120510';
}
# ABSTRACT: pandemic dialog to show player cards

use List::Util qw{ max };
use Moose      0.92;
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;
use Tk::Sugar;

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Tk::Utils qw{ image pandemic_icon };
use Games::Pandemic::Utils;

Readonly my $K => $poe_kernel;


# -- attributes & accessors

has parent    => ( ro, required, weak_ref, isa=>'Tk::Widget' );
has _toplevel => ( rw, isa=>'Tk::Toplevel' );

# a hash with all the widgets, for easier reference.
has _widgets => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        _set_w => 'set',
        _w     => 'get',
        _del_w => 'delete',
    },
);

# it's not usually a good idea to retain a reference on a poe session,
# since poe is already taking care of the references for us. however, we
# need the session to call ->postback() to set the various gui callbacks
# that will be fired upon gui events.
has _session => ( rw, weak_ref, isa=>'POE::Session' );


# -- initialization

#
# START()
#
# called during session start
#
sub START {
    my ($self, $session) = @_[OBJECT, SESSION];
    $K->alias_set('cards');
    $self->_set_session($session);
    $self->_build_gui;
}


#
# STOP()
#
# called during session stop
#
sub STOP {
    my $self = shift;
    debug( "~player cards: $self\n" );
}


# -- public events


event new_player => sub {
    my ($self, $player) = @_[OBJECT, ARG0];

    # create the frame holding the player
    my $top   = $self->_toplevel;
    my $frame = $top->Frame->pack(left, xfill2);
    $self->_set_w("f$player", $frame);

    my $ftitle = $frame->Frame->pack(top, fillx);
    $ftitle->Label( -image => image( $player->image('icon', 32), $top ) )->pack(left);
    $ftitle->Label( -text  => $player->role )->pack(left);

    my $fcards = $frame->Frame->pack(top, xfill2);
    $self->_set_w("cards_$player", $fcards);
};



event gain_card => sub {
    my ($self, $player, $card) = @_[OBJECT, ARG0, ARG1];
    my $top = $self->_toplevel;
    my $s   = $self->_session;

    # replace existing cards frame
    my $fcards = $self->_w("cards_$player");
    $fcards->destroy;
    $fcards = $self->_w("f$player")->Frame->pack(top, xfill2);
    $self->_set_w("cards_$player", $fcards);

    # repopulate new frame
    foreach my $card ( $player->all_cards ) {
        my $f = $fcards->Frame->pack(top, fillx);
        my $img = $f->Label( -image => image($card->icon, $top) )->pack(left);
        my $lab = $f->Label( -text => $card->label, -anchor=>'w' )->pack(left);

        # special cards can be clicked
        if ( $card->isa('Games::Pandemic::Card::Special') ) {
            my $sub = $s->postback('_special_card_clicked', $player, $card);
            $_->bind('<1>', $sub) for ($img, $lab, $f);
            $f->bind('<Enter>', sub { $f->configure(-relief=>'raised'); } );
            $f->bind('<Leave>', sub { $f->configure(-relief=>'flat'); } );
        }
    }
};



# drop_card is the same as gain_card, since we're removing all cards and
# re-adding all those belonging to the player.
event drop_card => \&gain_card;



event destroy => sub {
    my $self = shift;
    $K->alias_remove('cards');
    $self->_toplevel->destroy;
};



event toggle_visibility => sub {
    my $self = shift;
    my $top  = $self->_toplevel;
    my $method = $top->state eq 'normal' ? 'withdraw' : 'deiconify';
    $top->$method;
};


# -- private events

#
# event: _special_card_clicked( $card )
#
# received when user has clicked on a special $card.
#
event _special_card_clicked => sub {
    my ($self, $args) = @_[OBJECT, ARG0];
    my ($player, $card) = @$args;
    $K->post( main => $card->event, $player, $card );
};


# -- private methods

#
# dialog->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;
    my $game = Games::Pandemic->instance;
    my $parent = $self->parent;
    my $s = $self->_session;

    my $top = $parent->Toplevel;
    $self->_set_toplevel($top);
    $top->withdraw;

    # compute window width
    my @cards = $game->map->cards;
    my $font = $top->Font;
    my $max = max map { $font->measure($_->label) } @cards;
    my $width  = $max * 3; # FIXME: depends on number of players
    my $height = 40 + 20 * 9;  # FIXME: depends on max cards
    $top->geometry("${width}x${height}");

    # window title
    $top->title( T('Cards') );
    $top->iconimage( pandemic_icon($top) );

    # trap some events
    $top->protocol( WM_DELETE_WINDOW => $s->postback('toggle_visibility') );
    $top->bind('<F2>', $s->postback('toggle_visibility') );

    # center window & make it appear
    $top->Popup( -popover => $parent );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::PlayerCards - pandemic dialog to show player cards

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    Games::Pandemic::Tk::PlayerCards->new( parent=>$mw );

=head1 DESCRIPTION

This module implements a POE session (aliased C<cards>), responsible to
show the cards hold by the various players. It will receive some events
from the main window when the players gain or loose some cards.

=head1 METHODS

=head2 event: new_player( $player )

Request to add a new C<$player> to the window.

=head2 event: gain_card($player, $card)

Request to add a new C<$card> to C<$player>.

=head2 event: drop_card($player, $card)

Request to remove a C<$card> from C<$player>.

=head2 event: destroy()

Request to destroy the window.

=head2 event: toggle_visibility()

Request to hide/show window depending on its previous state.

=for Pod::Coverage START
    STOP

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

