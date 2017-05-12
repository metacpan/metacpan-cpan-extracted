package Log::Sentry;

=head1 NAME

Log::Sentry - sending log messages to Sentry.

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS


 my $raven = Log::Sentry->new(
    sentry_public_key => "public",
    sentry_secret_key => "secret",
    remote_url        => "sentry url"
 );


 $raven->message({ message => "Panic!" });

=head1 EXPORT


=cut

use strict;
use warnings;

use HTTP::Request::Common;
use LWP::UserAgent;
use JSON;
use MIME::Base64 'encode_base64';
use Time::HiRes (qw(gettimeofday));
use DateTime;
use Sys::Hostname;

=head4 new

Constructor. Use like:

    my $raven = Log::Sentry->new(
        sentry_public_key => "public",
        sentry_secret_key => "secret",
        remote_url        => "sentry url",
        sentry_version    => 3 # can be omitted
    );

=cut
sub new {
    my ( $class, %options ) = @_;

    foreach (qw(sentry_public_key sentry_secret_key remote_url)) {
        if (!exists $options{$_}) {
            die "Mandatory paramter '$_' not defined";
        }
    }
 
    my $self = {
        ua => LWP::UserAgent->new(),
        %options,
    };

    $self->{'sentry_version'} ||= 3;

    bless $self, $class;
}

=head4 message

Send message to Sentry server.

  $raven->message( { 
    'message'     => "Message", 
    'logger'      => "Name of the logger",                  # defult "root"
    'level'       => "Error level",                         # default 'error'
    'platform'    => "Platform name",                       # default 'perl',
    'culprit'     => "Module or/and function raised error", # default ""
    'tags'        => "Arrayref of tags",                    # default []
    'server_name' => "Server name where error occured",     # current host name is default
    'modules'     => "list of relevant modules",
    'extra'       => "extra params described below"
  } );

The structure of 'modules' list is:

    [
        {
            "my.module.name": "1.0"
        }
    ]

The structure of 'extra' field is:

  {
    "my_key"           => 1,
    "some_other_value" => "foo bar"
  }


=cut
sub message {
    my ( $self, $params ) = @_;
    
    my $message = $self->buildMessage( $params );
    my $stamp = gettimeofday();
    $stamp = sprintf ( "%.12g", $stamp );

    my $header_format = sprintf ( 
            "Sentry sentry_version=%s, sentry_timestamp=%s, sentry_key=%s, sentry_client=%s, sentry_secret=%s",
            $self->{sentry_version},
            time(),
            $self->{'sentry_public_key'},
            "perl_client/0.02",
            $self->{'sentry_secret_key'},
        );
    my %header = ( 'X-Sentry-Auth' => $header_format );

    my $request = POST($self->{remote_url}, %header, Content => $message);
    my $response = $self->{'ua'}->request( $request );

    return $response;
}


sub buildMessage {
    my ( $self, $params ) = @_;
 
    my $data = {
        'event_id'    => sprintf("%x%x%x", time(), time() + int(rand()), time() + int(rand())),
        'message'     => $params->{'message'},
        'timestamp'   => time(),
        'level'       => $params->{'level'} || 'error',
        'logger'      => $params->{'logger'} || 'root',
        'platform'    => $params->{'platform'} || 'perl',
        'culprit'     => $params->{'culprit'} || "",
        'tags'        => $params->{'tags'} || [],
        'server_name' => $params->{server_name}||hostname,
        'modules'     => $params->{'modules'},
        'extra'       => $params->{'extra'} || {}
    };

    my $json = JSON->new->utf8(1)->pretty(1)->allow_nonref(1);
    return $json->encode( $data );
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Danil Orlov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
