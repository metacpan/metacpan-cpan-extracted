package Event::ScreenSaver;

# Created on: 2009-07-10 19:40:40
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.0.6');

my %module = (
    linux   => 'Unix',
    solaris => 'Unix',
);

my $module = $module{$OSNAME} || $OSNAME;

extends "Event::ScreenSaver::$module";

1;

__END__

=head1 NAME

Event::ScreenSaver - Provides the ability to hook functions to the starting
and stopping of the screen saver (Linux only at the moment)

=head1 VERSION

This documentation refers to Event::ScreenSaver version 0.0.6.

=head1 SYNOPSIS

   use Event::ScreenSaver;

   # create the screen saver object
   my $ss = Event::ScreenSaver->new();

   # add functions to events
   $ss->start( sub {print "The screen saver started\n" } );
   $ss->stop( sub { print "The screen saver stopped\n" } );

   # run the event handler
   $ss->run();

   # or more simply
   Event::ScreenSaver->new(
       start => sub {say "Screen saver started"},
       stop  => sub {say "Screen saver stopped"},
   )->run;

=head1 DESCRIPTION

This module will try to load the most appropriate class for monitoring the
starting and stopping of the screen saver. Currently that means the Unix
module os it probably wont work that broadly.

=head2 Extending

The recommended method of implementing this for other operating systems is to
extend L<Event::ScreenSaver::Unix> and over write the run method with an OS
specific version.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Starts the event loop monitoring the screen saver.

Note that this will never return you will need to implement some other
exit strategy (like Ctrl-C).

=head2 C<start ( [$sub] )>

Gets/Sets the start handler code.

=head2 C<stop ( [$sub] )>

Gets/Sets the stop handler code.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

This module is currently only tested on a Ubuntu Linux system it will
probably work on other Desktop Linuxes and may work on other Unix systems
but will probably not work on other operating systems.

See L<Event::ScreenSaver> for its bugs and limitations.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome (Particularly for other operating systems).

Code can be found at L<http://github.com/ivanwills/Event-ScreenSaver/tree/master>

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
