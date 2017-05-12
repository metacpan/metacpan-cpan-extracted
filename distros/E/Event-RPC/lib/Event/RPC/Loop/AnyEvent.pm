#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Loop::AnyEvent;

use base qw( Event::RPC::Loop );

use strict;
use utf8;

use AnyEvent;

my %watchers;

sub get_loop_cv                 { shift->{loop_cv}                      }
sub set_loop_cv                 { shift->{loop_cv}              = $_[1] }

sub add_io_watcher {
    my $self = shift;
    my %par = @_;
    my ($fh, $cb, $desc, $poll) = @par{'fh','cb','desc','poll'};

    my $watcher = AnyEvent->io (
      fh   => $fh,
      poll => $poll,
      cb   => $cb,
    );

    $watchers{"$watcher"} = $watcher;
    
    return $watcher;
}

sub del_io_watcher {
    my $self = shift;
    my ($watcher) = @_;

    delete $watchers{"$watcher"};

    1;
}

sub add_timer {
    my $self = shift;
    my %par = @_;
    my  ($interval, $after, $cb, $desc) =
    @par{'interval','after','cb','desc'};

    my $timer = AnyEvent->timer (
        after       => $after,
        interval    => $interval,
        cb          => $cb,
    );

    $watchers{"$timer"} = $timer;
    
    return $timer;
}

sub del_timer {
    my $self = shift;
    my ($timer) = @_;

    delete $watchers{"$timer"};

    1;
}

sub enter {
    my $self = shift;

    my $loop_cv = AnyEvent->condvar;

    $self->set_loop_cv($loop_cv);

    $loop_cv->wait;

    1;
}

sub leave {
    my $self = shift;

    $self->get_loop_cv->send;

    1;
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Loop::AnyEvent - AnyEvent mainloop for Event::RPC

=head1 SYNOPSIS

  use Event::RPC::Server;
  use Event::RPC::Loop::AnyEvent;
  
  my $server = Event::RPC::Server->new (
      ...
      loop => Event::RPC::Loop::AnyEvent->new(),
      ...
  );

  $server->start;

=head1 DESCRIPTION

This modules implements a mainloop using AnyEvent for the
Event::RPC::Server module. It implements the interface
of Event::RPC::Loop. Please refer to the manpage of
Event::RPC::Loop for details.

=head1 AUTHORS

  Jörn Reder <joern AT zyn.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
