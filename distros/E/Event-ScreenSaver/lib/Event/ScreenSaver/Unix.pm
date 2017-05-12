package Event::ScreenSaver::Unix;

# Created on: 2009-07-08 05:33:45
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use List::MoreUtils qw/any/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.0.6');

has start => (
    is  => 'rw',
    isa => 'CodeRef',
);
has stop => (
    is  => 'rw',
    isa => 'CodeRef',
);
has type => (
    is  => 'rw',
);

sub run {
    my ($self) = @_;

    if ( !$self->type ) {
        eval { require X11::Protocol };
        $self->type( $EVAL_ERROR ? 'DBus' : 'X11' );
    }

    if ( $self->type eq 'X11' ) {
        $self->_run_x11();
    }
    elsif ( $self->type eq 'DBus' ) {
        $self->_run_dbus();
    }

    return;
}

sub _run_dbus {
    my ($self) = @_;

    eval { require Net::DBus::Reactor };

    die "You need to install eather Net::DBus or X11::Protocol\n" if $EVAL_ERROR;

    my $reactor = Net::DBus::Reactor->main();
    my $change  = sub {
        my $active = shift;
        my $stop;

        if ($active) {
            $stop = $self->start->($self) if $self->start;
        }
        else {
            $stop = $self->stop->($self) if $self->stop;
        }

        $reactor->shutdown if $stop;
    };

    my $bus = Net::DBus->find;
    my $screensaver = $bus->get_service("org.gnome.ScreenSaver");

    my $screensaver_object = $screensaver->get_object("/org/gnome/ScreenSaver", "org.gnome.ScreenSaver");
    $screensaver_object->connect_to_signal( 'ActiveChanged', $change );

    $reactor->run();

    return;
}

sub _run_x11 {
    my ($self) = @_;

    eval { require X11::Protocol::Ext::DPMS };
    die "You need to install eather Net::DBus or X11::Protocol\n" if $EVAL_ERROR;

    my $x = X11::Protocol->new();
    $x->init_extension('DPMS');

    my $power_level = '';
    while (1) {
        my $old_pl = $power_level;
        ($power_level, undef) = $x->DPMSInfo();
        my $stop;

        if( $old_pl eq 'DPMSModeOn' && $power_level ne 'DPMSModeOn' ) {
            $stop = $self->start->($self) if $self->start;
        }
        elsif ( $power_level eq 'DPMSModeOn' && $old_pl ne 'DPMSModeOn' ) {
            $stop = $self->stop->($self) if $self->stop;
        }

        last if $stop;

        sleep 60;
    }

    return;
}

1;

__END__

=head1 NAME

Event::ScreenSaver::Unix - Provides the Unix & Unix like screen saver
monitoring code.

=head1 VERSION

This documentation refers to Event::ScreenSaver::Unix version 0.0.6.

=head1 SYNOPSIS

   use Event::ScreenSaver::Unix;

   # create the screen saver object
   my $ss = Event::ScreenSaver::Unix->new();

   # add functions to events
   $ss->start( sub {print "The screen saver started\n" } );
   $ss->stop( sub { print "The screen saver stopped\n" } );

   # run the event handler
   $ss->run();

=head1 DESCRIPTION

This library provides an easy way to hook to the starting and stopping of
the screen saver (currently only in Unix like environments).

The call back functions are passed the current event object.

=head1 SUBROUTINES/METHODS

=head2 C<start ( [$sub] )>

Param: C<$sub> - sub - The starting call back function

Return: sub - The currently set starting function

Description: Sets/Gets the function that will be called when the screen
saver is started.

=head2 C<stop ( [$sub] )>

Param: C<$sub> - sub - The stopping call back function

Return: sub - The currently set stopping function

Description: Sets/Gets the function that will be called when the screen
saver is stopped.

=head2 C<run ()>

This function starts the process for listening for screen saver events.
It does not return.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There appears to be an issue with L<Net::DBus> where if the code calling this module
also uses Net::DBus the L<Net::DBus::Reactor> will not run.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
