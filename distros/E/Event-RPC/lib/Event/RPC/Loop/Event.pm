#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Loop::Event;

use base qw( Event::RPC::Loop );

use strict;
use utf8;

use Event;

sub add_io_watcher {
    my $self = shift;
    my %par = @_;
    my ($fh, $cb, $desc, $poll) = @par{'fh','cb','desc','poll'};

    return Event->io (
        fd        => $fh,
        poll      => $poll,
        cb        => $cb,
        desc      => $desc,
        reentrant => 0,
        parked    => 0,
    );
}

sub del_io_watcher {
    my $self = shift;
    my ($watcher) = @_;

    $watcher->cancel;

    1;
}

sub add_timer {
    my $self = shift;
    my %par = @_;
    my  ($interval, $after, $cb, $desc) =
    @par{'interval','after','cb','desc'};

    die "interval and after can't be used together"
        if $interval && $after;

    return Event->timer (
        interval        => $interval,
        after           => $after,
        cb              => $cb,
        desc            => $desc,
    );
}

sub del_timer {
    my $self = shift;
    my ($timer) = @_;

    $timer->cancel;

    1;
}

sub enter {
    my $self = shift;

    Event::loop();

    1;
}

sub leave {
    my $self = shift;

    Event::unloop_all("ok");

    1;
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Loop::Event - Event mainloop for Event::RPC

=head1 SYNOPSIS

  use Event::RPC::Server;
  use Event::RPC::Loop::Event;
  
  my $server = Event::RPC::Server->new (
      ...
      loop => Event::RPC::Loop::Event->new(),
      ...
  );

  $server->start;

=head1 DESCRIPTION

This modules implements a mainloop using the Event module
for the Event::RPC::Server module. It implements the interface
of Event::RPC::Loop. Please refer to the manpage of
Event::RPC::Loop for details.

=head1 AUTHORS

  Jörn Reder <joern AT zyn.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
