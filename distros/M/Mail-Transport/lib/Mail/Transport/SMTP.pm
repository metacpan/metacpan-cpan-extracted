# Copyrights 2001-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Transport.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Transport::SMTP;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Transport::Send';

use strict;
use warnings;

use Net::SMTP;


sub init($)
{   my ($self, $args) = @_;

    my $hosts   = $args->{hostname};
    unless($hosts)
    {   require Net::Config;
        $hosts  = $Net::Config::NetConfig{smtp_hosts};
        undef $hosts unless @$hosts;
        $args->{hostname} = $hosts;
    }

    $args->{via}  ||= 'smtp';
    $args->{port} ||= '25';

    $self->SUPER::init($args) or return;

    my $helo = $args->{helo}
      || eval { require Net::Config; $Net::Config::NetConfig{inet_domain} }
      || eval { require Net::Domain; Net::Domain::hostfqdn() };

    $self->{MTS_net_smtp_opts} =
     +{ Hello   => $helo
      , Debug   => ($args->{smtp_debug} || 0)
      };
    $self->{MTS_esmtp_options} = $args->{esmtp_options};
    $self->{MTS_from}          = $args->{from};
    $self;
}


sub trySend($@)
{   my ($self, $message, %args) = @_;

    my %send_options =
      ( %{$self->{MTS_esmtp_options} || {}}
      , %{$args{esmtp_options}       || {}}
      );

    # From whom is this message.
    my $from = $args{from} || $self->{MTS_from} || $message->sender || '<>';
    $from = $from->address if ref $from && $from->isa('Mail::Address');

    # Which are the destinations.
    ! defined $args{To}
        or $self->log(WARNING =>
   "Use option `to' to overrule the destination: `To' refers to a field");

    my @to = map $_->address, $self->destinations($message, $args{to});

    unless(@to)
    {   $self->log(NOTICE =>
            'No addresses found to send the message to, no connection made');
        return 1;
    }

    # Prepare the header
    my @headers;
    require IO::Lines;
    my $lines = IO::Lines->new(\@headers);
    $message->head->printUndisclosed($lines);

    #
    # Send
    #

    if(wantarray)
    {   # In LIST context
        my $server;
        return (0, 500, "Connection Failed", "CONNECT", 0)
            unless $server = $self->contactAnyServer;

        return (0, $server->code, $server->message, 'FROM', $server->quit)
            unless $server->mail($from, %send_options);

        foreach (@to)
        {     next if $server->to($_);
# must we be able to disable this?
# next if $args{ignore_erroneous_destinations}
              return (0, $server->code, $server->message,"To $_",$server->quit);
        }

        my $bodydata = $message->body->file;

        $server->data;
        $server->datasend(\@headers);
        $server->datasend( [ ref $bodydata eq 'GLOB' ? <$bodydata> : $bodydata->getlines ] );
        $server->dataend
            or return (0, $server->code, $server->message,'DATA',$server->quit);

        my $accept = ($server->message)[-1];
        chomp $accept;

		my $rc     = $server->quit;
        return ($rc, $server->code, $server->message, 'QUIT', $rc, $accept);
    }

    # in SCALAR context
    my $server;
    return 0 unless $server = $self->contactAnyServer;

    $server->quit, return 0
        unless $server->mail($from, %send_options);

    foreach (@to)
    {
          next if $server->to($_);
# must we be able to disable this?
# next if $args{ignore_erroneous_destinations}
          $server->quit;
          return 0;
    }

    my $bodydata = $message->body->file;

    $server->data;
    $server->datasend(\@headers);
    $server->datasend( [ ref $bodydata eq 'GLOB' ? <$bodydata> : $bodydata->getlines ] );

    $server->quit, return 0
        unless $server->dataend;

    $server->quit;
}

#------------------------------------------

sub contactAnyServer()
{   my $self = shift;

    my ($enterval, $count, $timeout) = $self->retry;
    my ($host, $port, $username, $password) = $self->remoteHost;
    my @hosts = ref $host ? @$host : $host;

    foreach my $host (@hosts)
    {   my $server = $self->tryConnectTo
         ( $host, Port => $port,
         , %{$self->{MTS_net_smtp_opts}}, Timeout => $timeout
         );

        defined $server or next;

        $self->log(PROGRESS => "Opened SMTP connection to $host.");

        if(defined $username)
        {   if($server->auth($username, $password))
            {    $self->log(PROGRESS => "$host: Authentication succeeded.");
            }
            else
            {    $self->log(ERROR => "Authentication failed.");
                 return undef;
            }
        }

        return $server;
    }

    undef;
}


sub tryConnectTo($@)
{   my ($self, $host) = (shift, shift);
    Net::SMTP->new($host, @_);
}

1;
