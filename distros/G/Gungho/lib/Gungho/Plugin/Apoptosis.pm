# $Id: /mirror/gungho/lib/Gungho/Plugin/Apoptosis.pm 31467 2007-11-30T00:42:50.705701Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved,

package Gungho::Plugin::Apoptosis;
use strict;
use warnings;
use base qw(Gungho::Plugin);

__PACKAGE__->mk_accessors('strategy');

sub setup
{
    my $self = shift;
    my $c    = shift;
    $self->next::method(@_);
    $self->strategy( Gungho::Plugin::Apoptosis::Time->new($self->config) );
    $c->register_event(
        'dispatch.dispatch_requests' => sub { $self->check_apoptosis(@_) },
    );
}

sub check_apoptosis
{
    my ($self, $event, $c) = @_;

    # Check apoptosis condition.
    if ($c->is_running && $self->is_time_to_die($c)) {
        $c->log->info("[APOPTOSIS] Apoptosis condition reached. Waiting for engine to stop");
        $c->shutdown("Apoptosis condition reached");
    }
}

sub is_time_to_die
{
    my ($self, $c) = shift;
    $self->strategy->is_time_to_die($c);
}

package Gungho::Plugin::Apoptosis::Time;
use strict;
use warnings;
use base qw(Gungho::Base);

__PACKAGE__->mk_accessors($_) for qw(started timeout);

sub new
{
    my $class = shift;
    my $config = shift;

    my $timeout = $config->{time}{timeout} || 0;
    my $now     = time();
    bless {
        started => $now,
        timeout => $now + $timeout,
    }, $class;
}

sub is_time_to_die
{
    my ($self, $c) = @_;
    if ($self->timeout <= time()) {
        $c->log->info("[APOPTOSIS] Apoptosis condition reached (timeout = " . $self->timeout . ", current time = " . time() . ")");
        return 1;
    }
    return 0;
}

1;

__END__

=head1 NAME

Gungho::Plugin::Apoptosis - Stop Execution In Long-Running Processes

=head1 SYNOPSIS

  plugins:
    - module: Apoptosis
      config:
        timeout: 86400 # Stop execution after 1 day

=head1 DESCRIPTION

Gungho is usually used in a environment where the processes survive a long time.

Sometimes this leads the application to consume too much memory - Yes, a memory
leak!
The memory leak can reside both in Gungho or your particular Provider/Handler
logic. If you or I can fix it, good. But usually memory leaks are just darn
hard to find, and you know your application won't acquire that much garbage
in, say, 1 day. 

I this case you just want to stop the execution of your crawler, and perhaps
replace it by another process. 

This plugin takes care of killing the running crawler process after a
certain amount of time. When it reaches the timeout specified in the config,
then the global "is_running" flag is set to off. After this flag is off,
Gungho will not dispatch any more requests, and waits for other states to
finish, eventually leading it to stop.

At this point you can re-dispatch your crawler proceses the way you want to.

=head1 METHODS

=head2 setup

=head2 check_apoptosis

=head2 is_time_to_die

=cut