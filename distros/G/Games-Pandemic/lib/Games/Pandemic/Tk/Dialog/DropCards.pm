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

package Games::Pandemic::Tk::Dialog::DropCards;
{
  $Games::Pandemic::Tk::Dialog::DropCards::VERSION = '1.120510';
}
# ABSTRACT: pandemic dialog to drop cards

use Moose;
use MooseX::Has::Sugar;
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

# player that will loose some cards
has player => ( ro, required, weak_ref, isa=>'Games::Pandemic::Player' );

# selected cards to be dropped
has _cards => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef[Games::Pandemic::Card]',
    default => sub { {} },
    handles => {
        _selcards         => 'values',
        _deselect_card    => 'delete',
        _select_card      => 'set',
        _is_card_selected => 'exists',
    }
);


# -- initialization

#
# BUILD()
#
# called as constructor initialization
#
sub BUILD {
    my $self = shift;
    $self->_w('ok')->configure(disabled);
}

sub _build_title   { T('Discard') }
sub _build_header  { T('Drop some cards') }
sub _build__ok     { T('Drop') }
sub _build__cancel { T('Cancel') }


# -- gui methods

#
# $dialog->_card_click($card);
#
# user has de/selected a card.
#
sub _card_click {
    my ($self, $card) = @_;

    # toggle card state
    if ( $self->_is_card_selected($card) ) {
        $self->_deselect_card($card);
    } else {
        $self->_select_card($card, $card);
    }

    # 
    my @cards = $self->_selcards;
    $self->_w('ok')->configure( scalar(@cards) ? enabled : disabled );
}

#
# $dialog->_valid;
#
# request to drop card(s) & destroy the dialog.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'drop_cards', $self->player, $self->_selcards );
    $self->_close;
}


# -- private methods

#
# $main->_build_gui;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;

    my $player = $self->player;
    my @cards  = $player->all_cards;

    my $f = $top->Frame->pack(top, xfill2, pad10);
    $f->Label(
        -text   => T('Select cards to drop:'),
        -anchor => 'w',
    )->pack(top, fillx);

    # display cards
    foreach my $card ( @cards ) {
        # to display a checkbutton with image + text, we need to
        # create a checkbutton with a label just next to it.
        my $fcity = $f->Frame->pack(top, fillx);
        my $selected;
        my $cb = $fcity->Checkbutton(
            -image    => image($card->icon, $top),
            -command  => sub { $self->_card_click($card); },
        )->pack(left);
        my $lab = $fcity->Label(
            -text   => $card->label,
            -anchor => 'w',
        )->pack(left, fillx);
        $lab->bind( '<1>', sub { $cb->invoke; } );
    }
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Dialog::DropCards - pandemic dialog to drop cards

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::DropCards->new(
        parent => $mw,
        player => $player,
    );

=head1 DESCRIPTION

Sometimes, a player has too many cards in her hands. In this case, she
must drop cards to get back to the official limit.

This dialog will show current cards of C<$player> and ask which ones
should be discarded. When clicking ok, the selected card(s) will be
dropped. This takes no action, and is handled by
L<Games::Pandemic::Controller>.

=for Pod::Coverage BUILD

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

