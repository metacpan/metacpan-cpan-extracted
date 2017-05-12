# 
# This file is part of Games-RailRoad
# 
# This software is copyright (c) 2008 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use 5.010;
use strict;
use warnings;

package Games::RailRoad::Window::Trains;
BEGIN {
  $Games::RailRoad::Window::Trains::VERSION = '1.101330';
}
# ABSTRACT: an opaque vector class.

use Tk; # should come before POE
use POE;


#--
# constructor

#
# my $id = Games::RailRoad::Window::Trains->spawn( %opts );
#
# pod for an explanation of the supported options.
#
sub spawn {
    my ($class, %opts) = @_;

    my $session = POE::Session->create(
        inline_states => {
            _start     => \&_on_start,
            _stop      => sub { print "ouch!\n" },
            # public events
            visibility_toggle      => \&_do_visibility_toggle,
            # private events
            # gui events
        },
        args => \%opts,
    );
    return $session->ID;
}


#--
# public events

#
# visibility_toggle();
#
# request window to be hidden / shown depending on its previous state.
#
sub _do_visibility_toggle {
    my ($h) = $_[HEAP];

    my $method = $h->{mw}->state eq 'normal' ? 'withdraw' : 'deiconify';
    $h->{mw}->$method;
}


#--
# private events

#
# _on_start( \%opts );
#
# session initialization. %opts is received from spawn();
#
sub _on_start {
    my ($k, $h, $from, $s, $opts) = @_[KERNEL, HEAP, SENDER, SESSION, ARG0];

    #-- create gui

    my $top = $opts->{parent}->Toplevel(-title => 'Trains');
    $h->{mw}   = $top;
    #$h->{list} = $top->Listbox->pack;
#    $h->{but_remove} = $top->Button(
#        -text    => 'Remove',
#        -state   => 'disabled',
#        -width   => 6,
#        -command => $s->postback('_b_breakpoint_remove')
#    )->pack(-side=>'left',-fill=>'x',-expand=>1);
#    $top->Button(
#        -text    => 'Close',
#        -width   => 6,
#        -command => $s->postback('visibility_toggle')
#    )->pack(-side=>'left',-fill=>'x',-expand=>1);

    # trap some events
    $top->protocol( WM_DELETE_WINDOW => $s->postback('visibility_toggle') );
    $top->bind( '<F5>', $s->postback('visibility_toggle') );

    
    $top->update;               # force redraw
    $top->resizable(0,0);
    my ($maxw,$maxh) = $top->geometry =~ /^(\d+)x(\d+)/;
    $top->maxsize($maxw,$maxh); # bug in resizable: minsize in effet but not maxsize
    $top->iconimage($Games::RailRoad::img{train});


    # -- other inits
    $h->{parent_session} = $from->ID;
}


#--
# gui events


1;


=pod

=head1 NAME

Games::RailRoad::Window::Trains - an opaque vector class.

=head1 VERSION

version 1.101330

=head1 DESCRIPTION

GRW::Trains implements a POE session, creating a Tk window listing the
trains existing in the simulation. The window can be hidden at will.

=head1 SYNOPSYS

    my $id = Games::RailRoad::Window::Train->spawn(%opts);
    $kernel->post( $id, 'visibility_toggle' );

=head1 CLASS METHODS

=head2 my $id = Games::RailRoad::Window::Train->spawn( %opts );

Create a window listing trains, and return the associated POE session
ID. One can pass the following options:

=over 4

=item parent => $mw

A Tk window that will be the parent of the toplevel window created. This
parameter is mandatory.

=back

=head1 PUBLIC EVENTS

The newly created POE session accepts the following events:

=over 4

=item visibility_toggle()

Request the window to be hidden or restaured, depending on its previous
state. Note that closing the window is actually interpreted as hiding
the window.

=back

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


