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

package Games::Pandemic::Tk::Dialog::ResilientPopulation;
{
  $Games::Pandemic::Tk::Dialog::ResilientPopulation::VERSION = '1.120510';
}
# ABSTRACT: dialog window to remove a city from being infected

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
has _selcard => ( is=>'rw', isa=>'Games::Pandemic::Card' );

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
sub _build__ok       { T('Remove from game') }
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
    my $img  = image( catfile($SHAREDIR, 'cards', 'resilient-population-48.png') );
    $f->Label(-image => $img)->pack(left, fill2, pad10);
    $f->Label(
        -text       => $card->description,
        -justify    => 'left',
        -wraplength => '8c',
    )->pack(left, fillx, pad10);

    # main elements
    my $text = T('Select infected city to remove from game:');
    $top->Label(-text => $text, W)->pack(top, fillx, pad5);
    my $tiler = $top->Scrolled( 'Tiler',
        -scrollbars => 'oe',
        -rows       => 8,
        -columns    => 3,
    )->pack(top, xfill2, pad2);

    # get past infections. if no previous infection, an epidemic just
    # stroke and thus we allow the user to use whatever infection that
    # was available just before the epidemic.
    my $deck = Games::Pandemic->instance->infection;
    my @citycards = $deck->nbdiscards
        ? $deck->past
        : ( reverse $deck->future )[ 0 .. $deck->previous_nbdiscards-1 ];

    # display cards
    @citycards =
        sort { $a->city->disease->name cmp $b->city->disease->name
            || $a->label cmp $b->label }
        @citycards;

    foreach my $card ( @citycards ) {
        # to display a checkbutton with image + text, we need to
        # create a checkbutton with a label just next to it.
        my $fcard = $tiler->Frame;
        my $img = $fcard->Label( -image => image($card->icon, $top) )->pack(left);
        my $lab = $fcard->Label( -text  => $card->label, W )->pack(left, fillx);
        $_->bind('<1>', [$self, '_select_city', $card, $fcard, $img, $lab] )
            for ($img, $lab, $fcard);
        $tiler->Manage($fcard);
    }
};


#
# $rpd->_finish_gui;
#
# prevent valid button to be clicked (no city selected at first)
#
sub _finish_gui {
    my $self = shift;
    $self->_w('ok')->configure(disabled);
}


#
# $rpd->_select_city( $card, $fcard, $img, $lab );
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

    # allow validation
    $self->_w('ok')->configure(enabled);
}


#
# $ggd->_valid;
#
#
# called when the action button has been clicked. Request the controller
# to play the card and build a research station in the selected city.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'resilient_population',
        $self->player,
        $self->card,
        $self->_selcard->city,
    );
    $self->_close;
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Dialog::ResilientPopulation - dialog window to remove a city from being infected

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::ResilientPopulation->new(
        parent => $mw,
        card   => $card,        # special govt grant card
        player => $player,      # player owning it
    );

=head1 DESCRIPTION

This dialog implements a dialog to let the user choose which city to
remove from past infections when playing a
L<Games::Pandemic::Card::Special::ResilientPopulation> card.

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

