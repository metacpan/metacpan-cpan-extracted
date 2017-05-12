# $Id: /mirror/gungho/lib/Gungho/Plugin/RequestLog.pm 31117 2007-11-26T13:10:33.379262Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Plugin::RequestLog;
use strict;
use warnings;
use base qw(Gungho::Plugin);
use Gungho::Log::Dispatch;

BEGIN
{
    eval "use Time::HiRes";
    if (! $@) {
        Time::HiRes->import( 'time' );
    }
}

__PACKAGE__->mk_accessors($_) for qw(log);

sub setup
{
    my ($self, $c) = @_;

    my $log = Gungho::Log::Dispatch->new(config => {
        logs      => $self->config,
        callbacks => sub {
            my %args = @_;
            my $message = $args{message};
            if ($message !~ /\n$/) {
                $message =~ s/$/\n/;
            }
            return $message;
        },
    });
    $log->setup($c);
    $self->log($log);

    $c->register_event('engine.send_request' => sub { $self->log_request(@_) } );
    $c->register_event('engine.handle_response' => sub { $self->log_response(@_) } );
}

sub log_request
{
    my ($self, $event, $c, $data) = @_;

    # Only log this if we've been asked to do soA
    my $request = $data->{request};
    my $uri     = $request->original_uri;
    my $time    = time();
    $request->notes('send_request_time' => $time);
    $self->log->debug(sprintf("# %s | %s | %s", $time, $uri, $request->id));
}

sub log_response
{
    my ($self, $event, $c, $data) = @_;

    my( $request, $response ) = ($data->{request}, $data->{response});
    my $time = time();
    my $send_time = $request->notes('send_request_time');

    # It's quite possible that we're dealing with a request that was sent
    # when this plugin wasn't loaded. In that case, do not calculate the
    # time elapsed
    my $elapsed;
    if(! defined $send_time ) {
        $elapsed = "(UNKNOWN)";
    } else {
        $elapsed = $time - $send_time;
    }

    $request->notes('handle_response_time' => $time);
    $request->notes('total_request_time'   => $elapsed);
    $self->log->info(sprintf("%s | %s | %s | %s | %s", $time, $elapsed, $response->code, $request->original_uri, $request->id));
}

1;

__END__

=head1 NAME

Gungho::Plugin::RequestLog - Log Requests

=head1 SYNOPSIS

  plugins:
    - module: RequestLog
      config:
        - module: File
          file: /path/to/filename
  
=head1 DESCRIPTION

If you want to know what Gungho's fetching, load this plugin.

The regular logs are logged at 'info' level, so don't set min_level to above
'info' in the config. See Log::Dipatch for details.

=head1 LOG FORMAT

The basic log format is

  CURRENT_TIME | ELAPSED TIME | RESPONSE CODE | URI | REQUEST ID

For the rare cases where for some reason you believe the request has been
requested to be fetched but the response isn't coming back, set the
min_level of the log config to debug:

  plugins:
    - module: RequestLog
      config:
        - module: File
          file: /path/to/filename
          min_level: debug

When you enable debug, lines like this will be logged at send_request time

  # CURRENT_TIME | URI | REQUEST ID

The leading '#' is there to aid you filter out the logs

=head1 METHODS

=head2 setup

=head2 log_request

=head2 log_response

=cut
