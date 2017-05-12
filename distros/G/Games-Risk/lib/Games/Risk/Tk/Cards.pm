#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Tk::Cards;
# ABSTRACT: cards listing
$Games::Risk::Tk::Cards::VERSION = '4.000';
use POE              qw{ Loop::Tk };
use List::MoreUtils  qw{ any firstidx };
use Moose;
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use Readonly;
use Tk::Sugar;
use Tk::Pane;

with 'Tk::Role::Dialog' => { -version => 1.112380 }; # _clear_w


use Games::Risk::I18n   qw{ T };
use Games::Risk::Logger qw{ debug };
use Games::Risk::Utils  qw{ $SHAREDIR };

Readonly my $K => $poe_kernel;
Readonly my $WIDTH  => 95;
Readonly my $HEIGHT => 145;


# -- attributes

has _bonus => ( rw, isa=>'Int', default=>0 );
has _cards => (
    ro, auto_deref,
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        _remove_card   => 'delete',  # $self->_remove_card( $idx );
        _store_card    => 'push',    # $self->_store_card( $card );
    },
);
has _selected => (
    rw, auto_deref,
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        _clear_selected => 'clear', # $self->_clear_selected;
    },
);
has _state    => ( rw, isa=>'Str', default=>'' );
has _canvases => ( rw, isa=>'ArrayRef', auto_deref, default => sub { [] } );


# -- initialization / finalization

sub _build_hidden    { 1 }
sub _build_title     { 'prisk - ' . T('cards') }
sub _build_icon      { $SHAREDIR->file('icons', '32','cards.png') }
sub _build_header    { T('Cards available') }
sub _build_resizable { 0 }
sub _build_ok        { T('Exchange') }
sub _build_hide      { T('Close') }


#
# session initialization.
#
sub START {
    my ($self, $s) = @_[OBJECT, SESSION];
    $K->alias_set('cards');

    #-- trap some events
    my $top = $self->_toplevel;
    $top->protocol( WM_DELETE_WINDOW => $s->postback('visibility_toggle'));
    $top->bind('<F5>', $s->postback('visibility_toggle'));
}


#
# session destruction.
#
sub STOP {
    debug( "gui-cards shutdown\n" );
}


# -- public events


event card_add => sub {
    my ($self, $card) = @_[OBJECT, ARG0];
    $self->_store_card( $card );
    $K->yield('_redraw_cards');
};



event card_del => sub {
    my ($self, @del) = @_[OBJECT, ARG0..$#_];

    # nothing selected any more
    $self->_clear_selected;
    $self->_set_bonus(0);
    $self->_w('label')->configure(-text=>T('Select 3 cards'));

    # remove the cards
    foreach my $c ( @del ) {
        my $idx = firstidx { $_ eq $c } $self->_cards;
        $self->_remove_card( $idx );
    }

    $K->yield('_redraw_cards');
    $K->yield('_change_button_state');
};



event attack               => \&_do_change_button_state;
event place_armies         => \&_do_change_button_state;
event _change_button_state => \&_do_change_button_state; # also internal event
sub _do_change_button_state {
    my ($self, $event) = @_[OBJECT, STATE];

    my $select;
    if ( $event eq 'attack' ) {
        $self->_set_state('attack');
        $select = 0;
    }
    elsif ( $event eq 'place_armies' ) {
        $self->_set_state('place_armies');
        $select = $self->_bonus;
    }
    else {
        $select = $self->_state eq 'place_armies' && $self->_bonus;
    }
    $self->_w('ok')->configure( $select ? (enabled) : (disabled) );
}



event shutdown => sub {
    my ($self, $destroy) = @_[OBJECT, ARG0];
    $self->_toplevel->destroy if $destroy;
    $self->_clear_w;
    $K->alias_remove('cards');
};



event visibility_toggle => sub {
    my $self = shift;
    my $top = $self->_toplevel;
    my $method = $top->state eq 'normal' ? 'withdraw' : 'deiconify';
    $top->$method;
};


# -- private events

#
# event: _card_clicked()
#
# click on a card, changing its selected status.
#
event _card_clicked => sub {
    my ($self, $args) = @_[OBJECT, ARG1];
    my ($canvas, undef) = @$args;

    # get the lists
    my @cards    = $self->_cards;
    my @canvases = $self->_canvases;
    my @selected = $self->_selected;

    # get index of clicked canvas, and its select status
    my $idx = firstidx { $_ eq $canvas } @canvases;
    my $is_selected = any { $_ == $idx } @selected;

    # change card status: de/selected
    if ( $is_selected ) {
        # deselect
        $canvas->configure(-bg=>'white');
        @selected = grep { $_ != $idx } @selected;
    } else {
        # select
        $canvas->configure(-bg=>'black');
        push @selected, $idx;
    }


    if ( scalar(@selected) == 3 ) {
        # get types of armies
        my @types = sort map { $cards[$_]->type } @selected;

        # compute how much armies it's worth.
        my $combo = join '', map { substr $_, 0, 1 } @types;
        my %bonus;
        $bonus{$_} = 10 for qw{ aci acj aij cij ajj cjj ijj jjj };
        $bonus{$_} = 8  for qw{ aaa aaj };
        $bonus{$_} = 6  for qw{ ccc ccj };
        $bonus{$_} = 4  for qw{ iii iij };
        my $bonus = $bonus{ $combo } // 0;
        $self->_set_bonus( $bonus );

        # update label
        local $" = ', ';
        my $text  = "@types = $bonus armies";
        $self->_w('label')->configure(-text=>$text);

    } else {
        # update label
        $self->_w('label')->configure(-text=>T('Select 3 cards'));
        $self->_set_bonus( 0 );
    }

    # FIXME: check validity of cards selected
    #$top->bind('<Key-Return>', $s->postback('_but_move'));
    #$top->bind('<Key-space>',  $s->postback('_but_move'));

    # store new set of selected cards
    $self->_set_selected( \@selected );

    $K->yield('_change_button_state');
};


#
# event: _card_double_clicked()
#
# double-click on a card, highlighting it on the board.
#
event _card_double_clicked => sub {
    my ($self, $args) = @_[OBJECT, ARG1];
    my $card = $args->[1];
    return if $card->type eq 'joker';   # joker is not a country, nothing to do
    $K->post( gui => flash_country => $card->country );
};


#
# event: _redraw_cards()
#
# ask to discard current cards shown, and redraw them. used when
# receiving a new card, or after exchanging some of them.
#
event _redraw_cards => sub {
    my ($self, $s) = @_[OBJECT, SESSION];

    # removing cards
    $_->destroy for $self->_canvases;

    # update gui
    my @canvases = ();
    my @selected = $self->_selected;
    my @cards    = $self->_cards;
    foreach my $i ( 0 .. $#cards ) {
        my $card = $cards[$i];
        my $country = $card->country;

        #
        my $is_selected = any { $_ == $i } @selected;

        # the canvas containing country info
        my $row = int( $i / 3 );
        my $col = $i % 3;
        my $c = $self->_w('frame')->Canvas(
            -width  => $WIDTH,
            -height => $HEIGHT,
            -bg     => $is_selected ? 'black' : 'white',
        )->grid(-row=>$row,-column=>$col);
        $c->CanvasBind('<1>', [$s->postback('_card_clicked'), $card]);
        $c->CanvasBind('<Double-1>', [$s->postback('_card_double_clicked'), $card]);

        # the info themselves
        my $img = $SHAREDIR->file('images', 'card-bg.png');
        $c->createImage(1, 1, -anchor=>'nw', -image=>$c->Photo(-file=>$img), -tags=>['bg']);

        if ( $card->type eq 'joker' ) {
            # only the joker!
            my $img = $SHAREDIR->file('images', 'card-joker.png');
            $c->createImage(
                $WIDTH/2, $HEIGHT/2,
                -image  => $c->Photo( -file => $img ),
            );
        } else {
            # country name
            $c->createText(
                $WIDTH/2, 15,
                -width  => 70,
                -anchor => 'n',
                -text   => $country->name,
            );
            # type of card
            my $img = $SHAREDIR->file( 'images', 'card-' . $card->type . '.png');
            $c->createImage(
                $WIDTH/2, $HEIGHT-10,
                -anchor => 's',
                -image  => $c->Photo( -file => $img ),
            );
        }

        # storing canvas
        push @canvases, $c;
    }

    $self->_set_canvases(\@canvases);
    $self->_toplevel->deiconify;
};


# -- private methods

#
# $self->_build_gui;
#
# called by tk:role:dialog to build the inner dialog.
#
sub _build_gui {
    my $self = shift;

    my $top = $self->_toplevel;

    #- top label
    my $label = $top->Label( -text => T('Select 3 cards') )->pack(top,fillx);
    $self->_set_w( label => $label );

    #- cards frame
    my $frame = $top->Scrolled('Frame',
        -scrollbars => 'e',
        -width      => ($WIDTH+5)*3,
        -height     => ($HEIGHT+5)*2,
    )->pack(top, xfill2);
    $self->_set_w( frame => $frame );

    #- force window geometry
    $top->update;    # force redraw
}


#
# $self->_finish_gui;
#
# called by tk:role:dialog to finish the inner dialog building.
# needed because win32 somehow mixes START with BUILD. very strange...
#
sub _finish_gui {
    my $self = shift;

    # prevent validation button to be clicked.
    $self->_w('ok')->configure(disabled);
}


#
# $self->_valid;
#
# called by tk:role:dialog when clicking on exchange button to
# trade armies.
#
sub _valid {
    my $self = shift;
    my @cards    = $self->_cards;
    my @selected = $self->_selected;
    $K->post( risk => 'cards_exchange', @cards[ @selected ] );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::Tk::Cards - cards listing

=head1 VERSION

version 4.000

=head1 DESCRIPTION

C<GR::Tk::Cards> implements a POE session, creating a Tk window to
list the cards the player got. It can be used to exchange cards with new
armies during reinforcement.

=head1 METHODS

=head2 card_add

    $K->post( cards => 'card_add', $card );

Player just received a new C<$card>, display it.

=head2 card_del

    $K->post( cards => 'card_del', @cards );

Player just exchanged some C<@cards>, remove them.

=head2 attack

    $K->post( cards => 'attack' );

Prevent user to exchange armies.

=head2 place_armies

    $K->post( cards => 'place_armies' );

Change exchange button state depending on the cards selected.

=head2 shutdown

    $K->post( cards => 'shutdown', $destroy );

Kill current session. If C<$destroy> is true, the toplevel window will
also be destroyed.

=head2 visibility_toggle

    $K->post( 'gui-continents' => 'visibility_toggle' );

Request window to be hidden / shown depending on its previous state.

=for Pod::Coverage START STOP

=head1 SYNOPSYS

    Games::Risk::Tk::Cards->new(%opts);

=head1 CLASS METHODS

=head2 my $id = Games::Risk::Tk::Cards->spawn( %opts );

Create a window listing player cards, and return the associated POE
session ID. One can pass the following options:

=over 4

=item parent => $mw

A Tk window that will be the parent of the toplevel window created. This
parameter is mandatory.

=back

=head1 PUBLIC EVENTS

The newly created POE session accepts the following events:

=over 4

=item * card_add( $card )

Add C<$card> to the list of cards owned by the player to be shown.

=item * card_del( $card )

Remove C<$card> from the list of cards owned by the player to be shown.

=item * visibility_toggle()

Request window to be hidden / shown depending on its previous state.

=back

=head1 SEE ALSO

L<Games::Risk>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
