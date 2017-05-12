#!/usr/bin/perl

=head1 NAME

Log::Log4perl::Appender::Fluent - log appender writing to Fluentd

=head1 SYNOPSIS

  log4perl.category = INFO, Fluentd
  # ...
  log4perl.appender.Fluentd = Log::Log4perl::Appender::Fluent
  log4perl.appender.Fluentd.host = fluentd.example.net
  # this port is default for Fluentd
  #log4perl.appender.Fluentd.port = 24224
  log4perl.appender.Fluentd.hostname_field = source_host
  log4perl.appender.Fluentd.tag_prefix = example
  # these two options prevent the message from being stringified
  log4perl.appender.Fluentd.layout = Log::Log4perl::Layout::NoopLayout
  log4perl.appender.Fluentd.warp_message = 0

=head1 DESCRIPTION

Log::Log4perl::Appender::Fluent is a L<Log::Log4perl(3)> appender plugin that
provides output to Fluentd daemon. The plugin supports sending simple string
messages, but it works way better when is provided with
L<Log::Message::JSON(3)> or L<Log::Message::Structured(3)> object, because the
structure of the message will be preserved.

=cut

package Log::Log4perl::Appender::Fluent;

use warnings;
use strict;

use base qw{Log::Log4perl::Appender};
use Fluent::Logger;
use Sys::Hostname;

#-----------------------------------------------------------------------------

our $VERSION = '0.04';

#-----------------------------------------------------------------------------

=head1 USAGE

Following options are available in L<Log::Log4perl(3)> config:

=cut

#-----------------------------------------------------------------------------

=over

=item I<socket> (default: I<none>)

Path to UNIX socket, where Fluentd listens. If specified, communication with
Fluentd instance will go through this socket, otherwise TCP protocol will be
used.

=item I<host>, I<port> (default: C<localhost>, C<24224>)

Fluentd instance's address. If neither host/port nor socket is specified,
due to default values, TCP communication will take place.

=item I<message_field> (default: C<message>)

Communication with Fluentd imposes using hashes as messages. This option
tells how should be named key if the message is not
a L<Log::Message::JSON(3)>/L<Log::Message::Structured(3)> object.

=item I<hostname_field> (default: I<none>)

Fluentd on its own doesn't provide the information where the record comes
from. Setting I<hostname_field> will make this module to add (replace)
necessary field in messages.

=item I<category_field>, I<level_field> (default: I<none>, I<none>)

These options, similarly to I<hostname_field>, specify where to put message's
category and level.

=item I<tag_prefix>, I<tag> (default: I<none>, I<none>)

If I<tag> is set, this will be the tag for messages. If I<tag_prefix> is set,
message will have the tag set to this prefix plus message's category. If
neither I<tag> nor I<tag_prefix> is set, message's tag is equal to category.

I<tag> has the precedence from these two if both set.

=back

=cut

sub new {
  my ($class, %options) = @_;

  my $self = bless {
    unix => $options{socket},
    tcp  => {
      host => $options{host} || 'localhost',
      port => $options{port} || 24224,
    },
    message_field  => $options{message_field} || 'message',
    hostname_field => $options{hostname_field},
    tag_prefix     => $options{tag_prefix},
    tag            => $options{tag},

    fluent => undef,
  }, $class;

  if ($self->{unix}) {
    $self->{fluent} = new Fluent::Logger(
      socket => $self->{unix},
    );
  } else {
    $self->{fluent} = new Fluent::Logger(
      host => $self->{tcp}{host},
      port => $self->{tcp}{port},
    );
  }

  return $self;
}

sub log {
  my ($self, %params) = @_;

  my $msg      = $params{message};
  my $category = $params{log4p_category};
  my $level    = $params{log4p_level};

  # possibly strip one array level
  $msg = $msg->[0] if ref $msg eq 'ARRAY' && @$msg == 1;

  # repack message
  if (eval { $msg->isa('Log::Message::JSON') }) {
    # strip Log::Message::JSON blessing
    # NOTE: the resulting hash(ref) should be tied to Tie::IxHash, but there's
    # a bug in Data::MessagePack 0.38 (XS version)
    $msg = { %$msg };
  } elsif (eval { $msg->DOES("Log::Message::Structured") }) {
    # Log::Message::Structured support
    # such a message:
    #   * is a Moose object
    #   * has Log::Message::Structured role
    #   * has method as_hash()
    $msg = $msg->as_hash;
  } else {
    $msg = { $self->{message_field} => $msg };
  }

  # add (replace?) fields: hostname, category (facility), level (importance)
  if ($self->{hostname_field}) {
    $msg->{ $self->{hostname_field} } = hostname();
  }
  if ($self->{category_field}) {
    $msg->{ $self->{category_field} } = $category;
  }
  if ($self->{level_field}) {
    $msg->{ $self->{level_field} } = $level;
  }

  my $tag;
  if ($self->{tag}) {
    $tag = $self->{tag};
  } elsif ($self->{tag_prefix}) {
    $tag = "$self->{tag_prefix}.$category";
  } else {
    $tag = $category;
  }

  # TODO: what if error? there was carp() somewhere
  $self->{fluent}->post($tag, $msg);
}

#-----------------------------------------------------------------------------

=head1 NOTES

If the destination host is unavailable, this module may print error messages
using C<warn()>.

=head1 AUTHOR

Stanislaw Klekot, C<< <cpan at jarowit.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stanislaw Klekot.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

http://fluentd.org/, L<Log::Log4perl(3)>, L<Log::Message::JSON(3)>,
L<Log::Message::Structured(3)>.

=cut

#-----------------------------------------------------------------------------
1;
# vim:ft=perl
