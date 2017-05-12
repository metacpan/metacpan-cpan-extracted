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

package Games::Pandemic::Tk::Dialog::ChooseDisease;
{
  $Games::Pandemic::Tk::Dialog::ChooseDisease::VERSION = '1.120510';
}
# ABSTRACT: pandemic dialog to select which disease to treat

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

has diseases => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has _disease => ( is=>'rw', isa=>'Games::Pandemic::Disease' );

# -- initialization

sub _build_title   { T('Treatment') }
sub _build_header  { T('Treat a disease') }
sub _build__ok     { T('Treat') }
sub _build__cancel { T('Cancel') }


# -- gui methods

#
# $dialog->_valid;
#
# request to treat a disease & destroy the dialog.
#
sub _valid {
    my $self = shift;
    $K->post( controller => 'action', 'treat', $self->_disease );
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

    my $f = $top->Frame->pack(top, xfill2, pad10);
    my @diseases = $self->diseases;
    $self->_set_disease( $diseases[0] );
    # enclosed cards in their own frame
    #my $f = $fcenter->Frame->pack(@LEFT, @FILLX, @PAD10, -anchor=>'nw');
    $f->Label(
        -text   => T('Select which disease to treat:'),
        -anchor => 'w',
    )->pack(top, fillx);

    # display cards
    my $seldisease = $self->_disease->name;
    foreach my $disease ( @diseases ) {
        # to display a radiobutton with image + text, we need to
        # create a radiobutton with a label just next to it.
        my $fdisease = $f->Frame->pack(top, fillx);
        my $rb = $fdisease->Radiobutton(
            -image    => image($disease->image('cube', 16), $top),
            -variable => \$seldisease,
            -value    => $disease->name,
            -command  => sub { $self->_set_disease($disease); },
        )->pack(left);
        my $lab = $fdisease->Label(
            -text   => $disease->name,
            -anchor => 'w',
        )->pack(left, fillx);
        $lab->bind( '<1>', sub { $rb->invoke; } );
    }
};



no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Dialog::ChooseDisease - pandemic dialog to select which disease to treat

=head1 VERSION

version 1.120510

=head1 SYNOPSIS

    Games::Pandemic::Tk::Dialog::ChooseDisease->new(
        parent   => $mw,
        diseases => \@diseases,
    );

=head1 DESCRIPTION

When cleaning a city multi-infected, the player must choose which
disease to treat.

This dialog will show the C<@diseases> of current city. When clicking
ok, the selected disease will be treated. This takes one action, and is
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

