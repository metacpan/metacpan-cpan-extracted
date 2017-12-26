use strict;
use warnings;

package Footprintless::Plugin::Atlassian::Confluence::Client;
$Footprintless::Plugin::Atlassian::Confluence::Client::VERSION = '1.03';
# ABSTRACT: A REST client for Atlassian Confluence
# PODNAME: Footprintless::Plugin::Atlassian::Confluence::Client

use parent qw(Footprintless::MixableBase);

use Footprintless::Mixins qw(
    _sub_entity
);
use Footprintless::Util qw(
    dynamic_module_new
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub _init {
    my ( $self, %options ) = @_;

    $self->{username} = $self->_sub_entity( 'automation.username', 1 );
    $self->{password} = $self->_sub_entity( 'automation.password', 1 );
    $self->{agent} = $options{agent} || $self->{factory}->agent();
    $self->{request_builder} = dynamic_module_new(
        (   $options{request_builder_module}
                || 'Footprintless::Plugin::Atlassian::Confluence::RequestBuilder'
        ),
        $self->_web_url()
    );
    $self->{response_parser} = dynamic_module_new(
        (   $options{response_parser_module}
                || 'Footprintless::Plugin::Atlassian::Confluence::ResponseParser'
        )
    );

    return $self;
}

sub request {
    my ( $self, $endpoint, $args, %response_options ) = @_;

    my $response;
    eval {
        $logger->debugf( 'requesting %s', $endpoint );
        my $http_request = $self->{request_builder}->$endpoint( ( $args ? @$args : () ) );
        $http_request->authorization_basic( $self->{username}, $self->{password} );

        if ( $logger->is_trace() ) {
            $logger->trace(
                join( '',
                    "----------------------BEGIN REQUEST--------------------\n",
                    $http_request->dump( maxlength => 500 ),
                    "\n---------------------- END REQUEST --------------------\n" )
            );
        }

        my @content = ();
        if ( $response_options{content_file} ) {
            $logger->tracef( 'writing response to %s', $response_options{content_file} );
            push( @content, $response_options{content_file} );
        }
        elsif ( $response_options{content_cb} ) {
            $logger->trace('writing response to callback');
            push( @content, $response_options{content_cb}, $response_options{read_size_hint} );
        }

        my $http_response = $self->{agent}->request( $http_request, @content );

        if ( $logger->is_trace() ) {
            $logger->trace(
                join( '',
                    "----------------------BEGIN RESPONSE--------------------\n",
                    $http_response->dump( maxlength => 500 ),
                    "\n---------------------- END RESPONSE --------------------\n" )
            );
        }

        $response = $self->{response_parser}->$endpoint( $http_response, %response_options );
    };
    if ($@) {
        if ( ref($@) eq 'HASH' && $@->{code} ) {
            $response = $@;
        }
        else {
            $response = {
                code    => 500,
                content => {},
                message => $@,
                success => 0,
            };
        }
    }
    return $response;
}

sub request_all {
    my ( $self, $endpoint, $args, @response_options ) = @_;

    my $response = $self->request(
        $endpoint,
        [   @$args,
            limit => 100,
            start => 0
        ],
        @response_options
    );

    my $next = $response;
    while ( $next->{success} && $next->{content}{_links}{next} ) {
        my $limit = $response->{content}{limit};
        $next = $self->request(
            $endpoint,
            [   @$args,
                limit => $limit,
                start => $next->{content}{start} + $limit,
            ],
            @response_options
        );
        push( @{ $response->{content}{results} }, @{ $next->{content}{results} } );
    }

    delete( $response->{content}{_links}{next} );
    $response->{content}{limit} = scalar( @{ $response->{content}{results} } );
    $response->{content}{size}  = $response->{content}{limit};
    $response->{content}{start} = 0;

    return $response;
}

sub _web_url {
    my ($self) = @_;
    my $web = $self->_sub_entity( 'web', 1 );

    return
          ( $web->{https} ? 'https://' : 'http://' )
        . $web->{hostname}
        . ( $web->{port} ? ":$web->{port}" : '' )
        . ( $web->{context_path} || '' );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Atlassian::Confluence::Client - A REST client for Atlassian Confluence

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    use Footprintless;
    use Footprintless::Util qw(
        dumper
        factory
    );
    use Log::Any;

    my $logger = Log::Any->get_logger();

    # Obtain a client from footprintless as a plugin:
    my $client = $footprintless->confluence_client('proj.env.confluence');

    # Or create one as a standalone:
    my $client = Footprintless::Plugin::Atlassian::Confluence::Client
        ->new(
            factory({
                foo => {
                    prod => {
                        confluence => {
                            automation => {
                                password => 'pa$$w0rd',
                                username => 'automation',
                            },
                            web => {
                                https => 1,
                                hostname => 'wiki.pastdev.com',
                                context_path => 'confluence',
                            }
                        }
                    }
                }
            }), 
            'foo.prod.confluence');

    # Now make a request:
    my $response = $client->request('get_content',
        [spaceKey => 'FPAC', title => 'API']);
    die($logger->errorf('couldn\'t find page API: %s', dumper($response)))
        unless ($response->{success});
    my $api_page_id = $response->{content}{results}[0]{id};

=head1 DESCRIPTION

This module provides a client for the 
L<Atlassian Confluence REST API|https://docs.atlassian.com/atlassian-confluence/REST/latest-server/> 
in the form of a L<Footprintless plugin|Footprintless::Plugin>.

=head1 CONSTRUCTORS

=head2 new(%options)

Constructs a new confluence client.  The availble options are:

=over 4

=item agent

An L<LWP::UserAgent> instance.  Defaults to a new agent returned by
L<$footprintless->agent()|Footprintless/agent(%options)>.

=item request_builder_module

A module that implements request building methods.  Defaults to
L<Fooptrintless::Plugin::Atlassian::Confluence::RequestBuilder>.

=item response_parser_module

A module that implements response parsing methods.  Defaults to
L<Fooptrintless::Plugin::Atlassian::Confluence::ResponseParser>.

=back

=head1 METHODS

=head2 request($endpoint, \@args, %response_options)

Generates a request by calling a method named C<$endpoint> on the request
builder, supplying it with C<@args>.  The request is sent using the agent,
and the response is parsed by calling a method named C<$endpoint> on the
response parser, supplying it with C<%response_options>.

=head2 request_all($endpoint, \@args, %response_options)

Same as L<request/request($endpoint, \@args, %response_options)> except
that it will loop through I<all> pages until all results have been 
returned.  This method assumes that the last argument to request builder
will be an options hash that will be used as query parameters.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Atlassian::Confluence|Footprintless::Plugin::Atlassian::Confluence>

=item *

L<Footprintless::Plugin::Atlassian::Confluence|Footprintless::Plugin::Atlassian::Confluence>

=item *

L<Footprintless::Plugin::Atlassian::Confluence::Client|Footprintless::Plugin::Atlassian::Confluence::Client>

=item *

L<https://docs.atlassian.com/atlassian-confluence/REST/latest-server|https://docs.atlassian.com/atlassian-confluence/REST/latest-server>

=back

=cut
