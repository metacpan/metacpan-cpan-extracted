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

package Games::Risk::GUI::MoveArmies;
# ABSTRACT: window to move armies
$Games::Risk::GUI::MoveArmies::VERSION = '4.000';
use POE        qw{ Loop::Tk };
use List::Util qw{ max };
use Tk;
use Tk::Font;
use Tk::Sugar;

use Games::Risk::I18n   qw{ T };
use Games::Risk::Logger qw{ debug };

use constant K => $poe_kernel;


#--
# Constructor

#
# my $id = Games::Risk::GUI::MoveArmies->spawn( \%params );
#
# create a new window to prompt for armies to move. refer to the
# embedded pod for an explanation of the supported options.
#
sub spawn {
    my (undef, $args) = @_;

    my $session = POE::Session->create(
        args          => [ $args ],
        inline_states => {
            _start       => \&_onpriv_start,
            _stop        => sub { debug( "gui-movearmies shutdown\n" ) },
            # gui events
            _but_move        => \&_onpriv_but_move,
            _slide_wheel     => \&_onpriv_slide_wheel,
            # public events
            attack_move      => \&_onpub_attack_move,
            ask_move_armies  => \&_onpub_ask_move_armies,
            shutdown         => \&_onpub_shutdown,
        },
    );
    return $session->ID;
}


#--
# EVENT HANDLERS

# -- public events

#
# event: attack_move( $src, $dst, $min );
#
# request how many armies to move from $src to $dst (minimum $min,
# according to the number of attack dices) during invasion.
#
sub _onpub_attack_move {
    my ($h, $src, $dst, $min) = @_[HEAP, ARG0..$#_];

    # store countries
    $h->{src} = $src;
    $h->{dst} = $dst;
    $h->{reply}   = 'attack_move';
    $h->{replyto} = 'risk'; # FIXME: from?

    # update gui
    my $top = $h->{toplevel};
    $top->title( T('Country invasion') );
    $h->{lab_title}->configure(-text => T('A country has been conquered!') );
    my $title = sprintf T('You have conquered %s while attacking from %s.'),
        $dst->name, $src->name;
    my $max = $src->armies - 1; # 1 army should guard $src
    $h->{scale}->configure(-from=>$min,-to=>$max);
    $h->{lab_info}->configure(-text=>$title);
    $h->{armies} = $max;

    # move window & enforce geometry
    $top->update;               # force redraw
    my ($x,$y) = $top->parent->geometry =~ /\+(\d+)\+(\d+)$/;
    $x += max $src->coordx, $dst->coordx; $x += 50;
    $y += max $src->coordy, $dst->coordy; $y += 50;
    $top->geometry("+$x+$y");
    $h->{toplevel}->deiconify;
    $h->{toplevel}->raise;
    $h->{toplevel}->update;

    #$top->resizable(0,0);
    #my ($maxw,$maxh) = $top->geometry =~ /^(\d+)x(\d+)/;
    #$top->maxsize($maxw,$maxh); # bug in resizable: minsize in effet but not maxsize
}


#
# event: ask_move_armies( $src, $dst, $max );
#
# request how many armies to move from $src to $dst, but no more than
# $max (armies having already travelled this turn.
#
sub _onpub_ask_move_armies {
    my ($h, $src, $dst, $max) = @_[HEAP, ARG0..$#_];

    # store countries
    $h->{src} = $src;
    $h->{dst} = $dst;
    $h->{reply}   = 'move_armies_move';
    $h->{replyto} = 'main'; # FIXME: from?

    # update gui
    my $top = $h->{toplevel};
    $top->title( T('Moving armies') );
    $h->{lab_title}->configure(-text => T('Consolidate your positions') );
    my $title = sprintf T('Moving armies from %s to %s.'),
        $src->name, $dst->name;
    $h->{scale}->configure(-from=>0,-to=>$max);
    $h->{lab_info}->configure(-text=>$title);
    $h->{armies} = 0;

    # move window & enforce geometry
    $top->update;               # force redraw
    my ($x,$y) = $top->parent->geometry =~ /\+(\d+)\+(\d+)$/;
    $x += max $src->coordx, $dst->coordx; $x += 50;
    $y += max $src->coordy, $dst->coordy; $y += 50;
    $top->geometry("+$x+$y");
    $h->{toplevel}->deiconify;
    $h->{toplevel}->raise;
    $h->{toplevel}->update;

    #$top->resizable(0,0);
    #my ($maxw,$maxh) = $top->geometry =~ /^(\d+)x(\d+)/;
    #$top->maxsize($maxw,$maxh); # bug in resizable: minsize in effet but not maxsize
}


#
# event: shutdown()
#
# kill current session. the toplevel window has already been destroyed.
#
sub _onpub_shutdown {
    #my $h = $_[HEAP];
    K->alias_remove('move-armies');
}


# -- private events

#
# event: _start( \%opts );
#
# session initialization. \%params is received from spawn();
#
sub _onpriv_start {
    my ($h, $s, $opts) = @_[HEAP, SESSION, ARG0];

    K->alias_set('move-armies');

    #-- create gui

    my $top = $opts->{parent}->Toplevel;
    $top->withdraw;           # window is hidden first
    $h->{toplevel} = $top;

    my $font = $top->Font(-size=>16);
    my $title = $top->Label(
        -bg   => 'black',
        -fg   => 'white',
        -font => $font,
    )->pack(top,pad20,xfill2);
    my $lab = $top->Label->pack(top,xfill2);
    my $fs  = $top->Frame->pack(top,xfill2);
    $fs->Label( -text => T('Armies to move') )->pack(left, S);
    $h->{armies} = 0;  # nb of armies to move
    my $sld = $fs->Scale(
        -orient    => 'horizontal',
        -width     => 5, # height since we're horizontal
        -showvalue => 1,
        -variable  => \$h->{armies},
    )->pack(left,xfill2,S);
    my $but = $top->Button(
        -text    => T('Move armies'),
        -command => $s->postback('_but_move'),
    )->pack(top);
    $h->{lab_title} = $title;
    $h->{lab_info}  = $lab;
    $h->{but_move}  = $but;
    $h->{scale}     = $sld;

    # window bindings.
    $top->bind('<4>', $s->postback('_slide_wheel',  1));
    $top->bind('<5>', $s->postback('_slide_wheel', -1));
    $top->bind('<Key-Return>', $s->postback('_but_move'));
    $top->bind('<Key-space>', $s->postback('_but_move'));


    #-- trap some events
    $top->protocol( WM_DELETE_WINDOW => sub{} );
}


# -- gui events

#
# event: _but_move()
#
# click on the move button, decide to move armies.
#
sub _onpriv_but_move {
    my $h = $_[HEAP];
    K->post($h->{replyto}, $h->{reply}, $h->{src}, $h->{dst}, $h->{armies});
    $h->{toplevel}->withdraw;
}


#
# event: _slide_wheel([$diff])
#
# mouse wheel on the slider, with an increment of $diff (can be negative
# too).
#
sub _onpriv_slide_wheel {
    my ($h, $args) = @_[HEAP, ARG0];
    $h->{armies} += $args->[0];
}


1;

__END__

=pod

=head1 NAME

Games::Risk::GUI::MoveArmies - window to move armies

=head1 VERSION

version 4.000

=head1 DESCRIPTION

C<GR::GUI::MoveArmies> implements a POE session, creating a Tk window to
ask the number of armies to move between adjacent countries. Once used,
the window is hidden to be reused later on.

=head1 SYNOPSYS

    my $id = Games::Risk::GUI::MoveArmies->spawn(%opts);
    Poe::Kernel->post( $id, 'attack_move', $src, $dst, $min );
    Poe::Kernel->post( $id, 'move_armies', $src, $dst, $max );

=head1 CLASS METHODS

=head2 my $id = Games::Risk::GUI::MoveArmies->spawn( %opts );

Create a window requesting for amies move, and return the associated POE
session ID. One can pass the following options:

=over 4

=item parent => $mw

A Tk window that will be the parent of the toplevel window created. This
parameter is mandatory.

=back

=head1 PUBLIC EVENTS

The newly created POE session accepts the following events:

=over 4

=item attack_move( $src, $dst, $min )

Show window and request how many armies to move from C<$src> to C<$dst>.
This number should be at least C<$min>, matching the number of dices
used for attack.

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
