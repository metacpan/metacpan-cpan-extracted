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

package Games::Pandemic::Tk::Dialog::Airlift;
{
  $Games::Pandemic::Tk::Dialog::Airlift::VERSION = '1.120510';
}
# ABSTRACT: dialog window to move a player with airlift

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;
use Tk::Sugar;
use Tk::Tiler;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Tk::Utils qw{ image };
use Games::Pandemic::Utils;

Readonly my $K    => $poe_kernel;
Readonly my $GREY => '#666666';


# -- accessors

has player   => ( is=>'rw', isa=>'Games::Pandemic::Player', required=>1 );
has card     => ( is=>'rw', isa=>'Games::Pandemic::Card', required=>1 );
has _selcard   => ( is=>'rw', isa=>'Games::Pandemic::Card' );
has _selplayer => ( is=>'rw', isa=>'Games::Pandemic::Player' );

has _selected => (
    is         => 'rw',
    isa        => 'ArrayRef[Tk::Widget]',
    predicate  => '_has_selected',
    auto_deref => 1,
);

# -- initialization

sub _build_header    { $_[0]->card->label }
sub _build_resizable { 1 }
sub _build_title     { T('Special event') }
sub _build__ok       { T('Move player') }
sub _build__cancel   { T('Cancel') }



# -- private methods

#
# $main->_build_gui;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self = shift;
    my $top  = $self->_toplevel;
    my $card = $self->card;
    my $game = Games::Pandemic->instance;

    # icon + text
    my $ftop = $top->Frame->pack(top, fillx);
    my $img  = image( catfile($SHAREDIR, 'cards', 'airlift-48.png') );
    $ftop->Label(-image => $img)->pack(left, fill2, pad10);
    $ftop->Label(
        -text       => $card->description,
        -justify    => 'left',
    )->pack(left, fillx, pad10);

    # the frame holding everything
    my $f = $top->Frame->pack(top, xfill2);

    # player chooser
    my $fleft = $f->Frame->pack(left, fill2, pad5);
    $fleft->Label(
        -text   => T('Select player to move:'),
        -anchor => 'w',
    )->pack(top, fillx, pad5);
    my $selplayer = $self->player->role;
    $self->_set_selplayer( $self->player );
    foreach my $player ( $game->all_players ) {
        # to display a radiobutton with image + text, we need to
        # create a radiobutton with a label just next to it.
        my $fplayer = $fleft->Frame->pack(top, fillx);
        my $rb = $fplayer->Radiobutton(
            -text     => $player->role,
            -variable => \$selplayer,
            -value    => $player->role,
            -anchor   => 'w',
            -command  => sub{ $self->_set_selplayer($player); $self->_check_player_city_combo; },
        )->pack(left, xfillx);
        my $lab = $fplayer->Label(
            -image    => image( $player->image('icon', 32), $top ),
        )->pack(left);
        $lab->bind( '<1>', sub { $rb->invoke; } );
    }

    # city chooser
    my $fright = $f->Frame->pack(left, xfill2, pad5);
    $fright->Label(
        -text   => T('Select city in which to move the player:'),
        -anchor => 'w',
    )->pack(top, fillx, pad5);
    my $tiler = $fright->Scrolled( 'Tiler',
        -scrollbars => 'oe',
        -rows       => 8,
        -columns    => 3,
    )->pack(top, xfill2, pad2);

    # display cards
    my @citycards =
        sort { $a->city->disease->name cmp $b->city->disease->name
            || $a->label cmp $b->label }
        Games::Pandemic->instance->map->disease_cards;

    foreach my $card ( @citycards ) {
        # to display a checkbutton with image + text, we need to
        # create a checkbutton with a label just next to it.
        my $fcard = $tiler->Frame;
        my $img = $fcard->Label( -image => image($card->icon, $top) )->pack(left);
        my $lab = $fcard->Label( -text  => $card->label, -anchor => 'w' )->pack(left, fillx);
        $_->bind('<1>', [$self, '_select_city', $card, $fcard, $img, $lab] )
            for ($img, $lab, $fcard);
        $tiler->Manage($fcard);
    }
};


#
# $ad->_check_player_city_combo;
#
# prevent valid button to be clicked if selected player is in
# selected city.
#
sub _check_player_city_combo {
    my $self = shift;
    my $player = $self->_selplayer;

    # no city selected: no validation possible
    return $self->_w('ok')->configure(disabled) unless defined $self->_selcard;

    # city selected: check if player is in city
    my $city  = $self->_selcard->city;
    $self->_w('ok')->configure( $player->location eq $city ? disabled : enabled );
}


#
# $ad->_finish_gui;
#
# prevent valid button to be clicked (no city selected at first)
#
sub _finish_gui {
    my $self = shift;
    $self->_w('ok')->configure(disabled);
}


#
# $ad->_select_city( $card, $fcard, $img, $lab );
#
# Called when one of the frame ($fcard), image ($img) or label ($lab)
# representing the $card has been selected. Hilight the new widgets, un-
# hilight the old widgets and store the new card selected.
#
sub _select_city {
    my ($self, $card, $fcard, $img, $lab) = @_;

    # store new selected card
    $self->_set_selcard($card);

    # remove previous selection
    my $bg = $fcard->cget('-bg');
    if ( $self->_has_selected ) {
        my @old = $self->_selected;
        $_->configure(-bg=>$bg) for @old;
    }

    # add selection
    my @new = ($img, $lab, $fcard);
    $self->_set_selected( \@new );
    $_->configure(-bg=>$GREY) for @new;

    # di/allow validation
    $self->_check_player_city_combo;
}


#
# $ad->_valid;
#
# called when the action button has been clicked. Request the controller
# to play the card and build a research station in the selected city.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'airlift',
        $self->player,
        $self->card,
        $self->_selplayer,
        $self->_selcard->city,
    );
    $self->_close;
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Dialog::Airlift - dialog window to move a player with airlift

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::GovernmentGrant->new(
        parent => $mw,
        card   => $card,        # special govt grant card
        player => $player,      # player owning it
    );

=head1 DESCRIPTION

This dialog implements a dialog to let the user choose which player to
move in which city when playing a
L<Games::Pandemic::Card::Special::Airlift> card.

The card should be passed in the constructor, along with the player
holding the card.

=for Pod::Coverage BUILD

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

