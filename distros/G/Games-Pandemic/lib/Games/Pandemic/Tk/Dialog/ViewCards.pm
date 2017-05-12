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

package Games::Pandemic::Tk::Dialog::ViewCards;
{
  $Games::Pandemic::Tk::Dialog::ViewCards::VERSION = '1.120510';
}
# ABSTRACT: dialog window to show cards

use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;
use Tk::Sugar;
use Tk::Tiler;

extends 'Games::Pandemic::Tk::Dialog';

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Tk::Utils qw{ image };
use Games::Pandemic::Utils;


# -- accessors

has cards => (
    is         => 'ro',
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    required   => 1,
    auto_deref => 1,
);


# -- initialization

sub _build_resizable { 1 }
sub _build__cancel   { T('Close') }



# -- private methods

#
# $main->_build_gui;
#
# create the various gui elements.
#
augment _build_gui => sub {
    my $self  = shift;
    my $top   = $self->_toplevel;
    my @cards = $self->cards;

    # main elements
    my $tiler = $top->Scrolled( 'Tiler',
        -scrollbars => 'oe',
        -rows       => 8,
        -columns    => 3,
    )->pack(top, xfill2, pad2);
    #$tiler->Manage( $tiler->Label(-text=>T('(older)'), -anchor=>'w') );

    # display cards
    foreach my $card ( reverse @cards ) {
        # to display a checkbutton with image + text, we need to
        # create a checkbutton with a label just next to it.
        my $fcard = $tiler->Frame;
        $fcard->Label( -image => image($card->icon, $top) )->pack(left);
        $fcard->Label( -text  => $card->label, W )->pack(left, fillx);
        $tiler->Manage($fcard);
    }
    #$tiler->Manage( $tiler->Label(-text=>T('(more recent)')) );
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Dialog::ViewCards - dialog window to show cards

=head1 VERSION

version 1.120510

=for Pod::Coverage BUILD

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

