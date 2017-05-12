package Log::Log4perl::Appender::Lumberjack;

use warnings;
use strict;

use base qw{Log::Log4perl::Appender};
use Net::Lumberjack::Client;
use Sys::Hostname;

# ABSTRACT: log appender writing to a lumberjack server
our $VERSION = '1.00'; # VERSION


sub new {
  my ($class, %options) = @_;

  my $self = bless {
    host => $options{host} || 'localhost',
    port => $options{port} || 5044,
    keepalive => defined $options{keepalive} ?
      $options{keepalive} : 0,
    frame_format => $options{frame_format},

    use_ssl => defined $options{use_ssl} ?
      $options{use_ssl} : 0,
    ssl_verify => defined $options{ssl_verify} ?
      $options{ssl_verify} : 1,
    ssl_ca_file => $options{ssl_ca_file},
    ssl_ca_path => $options{ssl_ca_path},
    ssl_version => $options{ssl_version},
    ssl_hostname => $options{ssl_hostname},
    ssl_cert => $options{ssl_cert},
    ssl_key => $options{ssl_key},

    message_field => $options{message_field} || 'message',
    level_field => $options{level_field} || 'level',
    hostname_field => $options{hostname_field} || '@source_host',
  }, $class;

  $self->{'client'} = Net::Lumberjack::Client->new(
    host => $self->{host},
    port => $self->{port},
    keepalive => $self->{keepalive},
    frame_format => $self->{frame_format},

    use_ssl => $self->{use_ssl},
    ssl_verify => $self->{ssl_verify},
    ssl_ca_file => $self->{ssl_ca_file},
    ssl_ca_path => $self->{ssl_ca_path},
    ssl_version => $self->{ssl_version},
    ssl_hostname => $self->{ssl_hostname},
    ssl_cert => $self->{ssl_cert},
    ssl_key => $self->{ssl_key},
  );

  return $self;
}

sub log {
  my ($self, %params) = @_;

  my $msg = $params{message};
  my $category = $params{log4p_category};
  my $level = $params{log4p_level};

  $msg = $msg->[0] if ref $msg eq 'ARRAY' && @$msg == 1;

  if (eval { $msg->isa('Log::Message::JSON') }) {
    $msg = { %$msg };
  } elsif (eval { $msg->DOES("Log::Message::Structured") }) {
    $msg = $msg->as_hash;
  } else {
    $msg = { $self->{message_field} => $msg };
  }

  if ($self->{hostname_field}) {
    $msg->{ $self->{hostname_field} } = hostname();
  }
  if ($self->{category_field}) {
    $msg->{ $self->{category_field} } = $category;
  }
  if ($self->{level_field}) {
    $msg->{ $self->{level_field} } = $level;
  }

  $self->{'client'}->send_data($msg);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Log4perl::Appender::Lumberjack - log appender writing to a lumberjack server

=head1 VERSION

version 1.00

=head1 SYNOPSIS

  use Log::Log4perl;

  my $conf = q(
    log4perl.category = INFO, Remote
    # ...
    log4perl.appender.Remote = Log::Log4perl::Appender::Lumberjack
    log4perl.appender.Remote.host = 127.0.0.1
    log4perl.appender.Remote.port = 5044
    log4perl.appender.Remote.keepalive = 0
    log4perl.appender.Remote.frame_format = json
    #log4perl.appender.Remote.use_ssl = 1
    #log4perl.appender.Remote.ssl_verify = 1
    # these two options prevent the message from being stringified
    log4perl.appender.Remote.layout = Log::Log4perl::Layout::NoopLayout
    log4perl.appender.Remote.warp_message = 0
  );

  Log::Log4perl::init( \$conf );

  my $log = Log::Log4perl::get_logger("Foo::Bar");
  $log->info('just for information...');

=head1 OPTIONS

=head2 host (default: '127.0.0.1')

Host to connect to.

=head2 port (default: 5044)

TCP port to connect to.

=head2 keepalive (default: 0)

If enabled connection will be keept open between send_data() calls.
Otherwise it will be closed and reopened on every call.

Needs to be disabled for logstash-input-beats since it expects only 
one bulk of frames per connection.

=head2 frame_formt (default: 'json')

The following frame formats are supported:

=over

=item 'json', 'v2'

Uses json formatted data frames as defined in lumberjack protocol v2. (type 'J')

=item 'data', 'v1'

Uses lumberjack DATA (type 'D') frames as defined in lumberjack protocol v1.

This format only supports a flat hash structure.

=back

=head2 use_ssl (default: 0)

Enable SSL transport encryption.

=head2 ssl_verify (default: 1)

Enable verification of SSL server certificate.

=head2 ssl_ca_file (default: emtpy)

Use a non-default CA file to retrieve list of trusted root CAs.

Otherwise the system wide default will be used.

=head2 ssl_ca_path (default: emtpy)

Use a non-default CA path to retrieve list of trusted root CAs.

Otherwise the system wide default will be used.

=head2 ssl_version (default: empty)

Use a non-default SSL protocol version string.

Otherwise the system wide default will be used.

Check L<IO::Socket::SSL> for string format.

=head2 ssl_hostname (default: emtpy)

Use a hostname other than the hostname give in 'host' for
SSL certificate verification.

This could be used if you use a IP address to connecting to
server that only lists the hostname in its certificate.

=head2 ssl_cert (default: empty)

=head2 ssl_key (default: empty)

If 'ssl_cert_file' and 'ssl_key_file' is the client will enable
client side authentication and use the supplied certificate/key.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
