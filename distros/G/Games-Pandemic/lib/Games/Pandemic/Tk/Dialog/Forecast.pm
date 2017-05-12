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

package Games::Pandemic::Tk::Dialog::Forecast;
{
  $Games::Pandemic::Tk::Dialog::Forecast::VERSION = '1.120510';
}
# ABSTRACT: dialog window to play a forecast

use File::Spec::Functions qw{ catfile  };
use List::MoreUtils       qw{ firstidx };
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

Readonly my $K => $poe_kernel;


# -- accessors

has player   => ( is=>'rw', isa=>'Games::Pandemic::Player', required=>1 );
has card     => ( is=>'rw', isa=>'Games::Pandemic::Card',   required=>1 );
has _cards => (
    is         => 'rw',
    isa        => 'ArrayRef[Games::Pandemic::Card::City]',
    auto_deref => 1,
);

# -- initialization

sub _build_header    { $_[0]->card->label }
sub _build_resizable { 0 }
sub _build_title     { T('Special event') }
sub _build__ok       { T('Rearrange') }
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

    # icon + text
    my $f   = $top->Frame->pack(top, fillx);
    my $img  = image( catfile($SHAREDIR, 'cards', 'forecast-48.png') );
    $f->Label(-image => $img)->pack(left, fill2, pad10);
    $f->Label(
        -text       => $card->description,
        -justify    => 'left',
        -wraplength => '6c',
    )->pack(left, fillx, pad10);

    # main elements
    my $text = T('Rearrange the infections to come as you wish:');
    $top->Label(-text => $text, W)->pack(top, fillx, pad5);

    # peek the next infections
    my $game = Games::Pandemic->instance;
    my $deck = $game->infection;
    my @cards = $deck->future;
    splice @cards, 0, @cards-6;
    @cards = reverse @cards;
    $self->_set_cards(\@cards);

    # the frame holding the infections to come
    my $finfections = $top->Frame->pack(top, xfill2, pad5);
    my $i = 1;
    foreach my $card ( @cards ) {
        my $fcard = $finfections->Frame->pack(top, fillx);
        my $lab = $fcard->Label( -text  => "$i - ", W )->pack(left);
        $fcard->Label( -image => image($card->icon, $top) )->pack(left);
        $fcard->Label( -text  => $card->label, -anchor => 'w' )->pack(left, xfillx);
        my $up   = $fcard->Button(
            -image   => 'navup16',
            -command => [ $self, '_move', $card, -1 ],
        )->pack(left);
        my $down = $fcard->Button(
            -image   => 'navdown16',
            -command => [ $self, '_move', $card, 1 ],
        )->pack(left);
        $self->_set_w("f$card", $fcard);
        $self->_set_w("lab$card",  $lab);
        $self->_set_w("up$card",   $up);
        $self->_set_w("down$card", $down);
        $i++;
    }
    
    $self->_redraw_infections;
};


#
# $fcd->_move( $card, $diff );
#
# request to move $card up or down, depending on $diff (-1 / 1).
#
sub _move {
    my ($self, $card, $diff) = @_;
    my @cards = $self->_cards;

    # reorder the cards
    my $idx = firstidx { $_ eq $card } @cards;
    $cards[$idx] = $cards[ $idx+$diff ];
    $cards[$idx+$diff] = $card;
    $self->_set_cards( \@cards );
    # update the gui
    $self->_redraw_infections;
}


#
# $fcd->_redraw_infections;
#
# unpack all infection frames, and repack them in the correct order.
# update the infection index, and the button permissions.
#
sub _redraw_infections {
    my $self = shift;

    my @cards = $self->_cards;
    $self->_w("f$_")->packForget for @cards;
    
    my $i = 1;
    foreach my $card ( @cards ) {
        $self->_w("f$card")->pack(top, fillx);
        $self->_w("lab$card") ->configure( -text => "$i - " );
        $self->_w("up$card")  ->configure( $i == 1 ? disabled : enabled );
        $self->_w("down$card")->configure( $i == 6 ? disabled : enabled );
        $i++;
    }
}


#
# $fcd->_valid;
#
#
# called when the action button has been clicked. Request the controller
# to play the card and rearrange the infections to come.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'forecast',
        $self->player,
        $self->card,
        $self->_cards,
    );
    $self->_close;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Dialog::Forecast - dialog window to play a forecast

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::Forecast->new(
        parent => $mw,
        card   => $card,        # special forecast card
        player => $player,      # player owning it
    );

=head1 DESCRIPTION

This dialog implements a dialog to let the user rearrange the next 6
infections in the order she wants when playing a
L<Games::Pandemic::Card::Special::Forecast> card.

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

