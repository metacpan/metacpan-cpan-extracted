# $Id: /mirror/gungho/lib/Gungho/Plugin/RequestTimer.pm 3779 2007-10-23T15:39:50.115570Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki  <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Plugin::RequestTimer;
use strict;
use warnings;
use base qw(Gungho::Plugin);

__PACKAGE__->mk_accessors($_) for qw(verbose);

BEGIN
{
    warn "Gungho::Plugin::RequestTimer has been deprecated, use Gungho::Plugin::RequestLog";
    eval { Time::HiRes->require };
    if (! $@) {
        Time::HiRes->import(qw(time));
    }
}

sub setup
{
    my ($self, $c) = @_;

    $self->verbose(
        exists $self->config->{verbose} ? $self->config->{verbose} : 1
    );

    $c->register_hook(
        'engine.send_request'    => sub { $self->log_start(@_) },
        'engine.handle_response' => sub { $self->log_stop(@_) },
    );
}

sub log_start
{
    my ($self, $c, $args) = @_;

    my $request = $args->{request};
    $request->notes('send_request_time' => time());
}

sub log_stop
{
    my ($self, $c, $args) = @_;

    my $request = $args->{request};

    $request->notes('handle_response_time' => time());
    $request->notes('total_request_time' => $request->notes('handle_response_time') - $request->notes('send_request_time') );

    if ($self->verbose) {
        $c->log->info("RequestTimer: logging end for request " . $request->uri . " = " . $request->notes('total_request_time') . " seconds");
    }
}

1;

__END__

=head1 NAME

Gungho::Plugin::RequestTimer - Keep Track Of Time To Finish Request

=head1 SYNOPSIS

  plugins:
    -
      module: RequestTimer
      config:
        verbose: 0 # optional

=head1 DESCRIPTION

NOTICE This module has been deprecated. Please use RequestLog instead.

Gungho::Plugin::RequestTimer allows you to keep track of the time it took to
finish fetching a particular request. The time when the request started,
the time when the request was handed to handle_response(), and the total
time between the latter two points are stored under the request object's
notes() slot.

  $request->notes('send_request_time');
  $request->notes('handle_response_time');
  $request->notes('total_request_time');

Note that these values may not correspond exactly to when the acutal HTTP
transaction started/finished, but rather, it's just a hook to show when
these particular events happened in Gungho's life cycle.

If you have Time::HiRes in your system, Time::HiRes::time() is used over 
regular time() as the store time values.

=head1 METHODS

=head2 setup()

Sets up the plugin.

=head2 log_start()

Starts logging

=head2 log_stop()

Ends logging

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut