#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Loop;

use strict;
use utf8;

sub new {
    my $class = shift;
    return bless {}, $class;
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Loop - Mainloop Abstraction layer for Event::RPC

=head1 SYNOPSIS

  use Event::RPC::Server;
  use Event::RPC::Loop::Glib;
  
  my $server = Event::RPC::Server->new (
      ...
      loop => Event::RPC::Loop::Glib->new(),
      ...
  );

  $server->start;

=head1 DESCRIPTION

This modules defines the interface of Event::RPC's mainloop
abstraction layer. It's a virtual class all mainloop modules
should inherit from.

=head1 INTERFACE

The following methods need to be implemented:

=over 4

=item $loop->B<enter> ()

Enter resp. start a mainloop.

=item $loop->B<leave> ()

Leave the mainloop, which was started with the enter() method.

=item $watcher = $loop->B<add_io_watcher> ( %options )

Add an I/O watcher. Options are passed as a hash of
key/value pairs. The following options are known:

=over 4

=item B<fh>

The filehandle to be watched.

=item B<cb>

This callback is called, without any parameters, if
an event occured on the filehandle above.

=item B<desc>

A description of the watcher. Not necessarily implemented
by all modules, so it may be ignored.

=item B<poll>

Either 'r', if your program reads from the filehandle, or 'w'
if it writes to it.

=back

A watcher object is returned. What this exactly is depends
on the implementation, so you can't do anything useful with
it besides passing it back to del_io_watcher().

=item $loop->B<del_io_watcher> ( $watcher )

Deletes an I/O watcher which was added with $loop->add_io_watcher().

=item $timer = $loop->B<add_timer> ( %options )

This sets a timer, a subroutine called after a specific
timeout or on a regularly basis with a fixed time interval.

Options are passed as a hash of
key/value pairs. The following options are known:

=over 4

=item B<interval>

A time interval in seconds, may be fractional.

=item B<after>

Callback is called once after this amount of seconds,
may be fractional.

=item B<cb>

The callback.

=item B<desc>

A description of the timer. Not necessarily implemented
by all modules, so it may be ignored.

=back

A timer object is returned. What this exactly is depends
on the implementation, so you can't do anything useful with
it besides passing it back to del_io_timer().

=item $loop->B<del_timer> ( $timer )

Deletes a timer which was added with $loop->add_timer().

=back

=head1 DIRECT USAGE IN YOUR SERVER

You may use the methods of Event::RPC::Loop by yourself
if you like. This way your program keeps independent of
the actual mainloop module in use, if the simplified
interface of Event::RPC::Loop is sufficient for you.

In your server program you access the actual mainloop 
object this way:

  my $loop = Event::RPC::Server->instance->get_loop;

Naturally nothing speaks against making your program
to work only with a specific mainloop implementation,
if you need its features. In that case you may use
the corresponding API directly (e.g. of Event or Glib),
no need to access it through Event::RPC::Loop.

=head1 AUTHORS

  Jörn Reder <joern AT zyn.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
