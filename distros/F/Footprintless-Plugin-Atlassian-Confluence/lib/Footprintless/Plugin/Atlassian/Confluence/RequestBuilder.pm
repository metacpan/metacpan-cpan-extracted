use strict;
use warnings;

package Footprintless::Plugin::Atlassian::Confluence::RequestBuilder;
$Footprintless::Plugin::Atlassian::Confluence::RequestBuilder::VERSION = '1.03';
# ABSTRACT: A request builder for the Atlassian Confluence REST API
# PODNAME: Footprintless::Plugin::Atlassian::Confluence::RequestBuilder

use HTTP::Request;
use JSON;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub create_content {
    my ( $self, $content, %options ) = @_;

    return HTTP::Request->new(
        'POST',
        $self->_url( "/rest/api/content", %options ),
        [ 'Content-Type' => 'application/json' ],
        encode_json($content)
    );
}

sub delete_content {
    my ( $self, $id ) = @_;

    return HTTP::Request->new( 'DELETE', $self->_url("/rest/api/content/$id") );
}

sub get_content {
    my ( $self, %options ) = @_;

    my $id = delete( $options{id} );
    return HTTP::Request->new( 'GET',
          $id
        ? $self->_url( "/rest/api/content/$id", %options )
        : $self->_url( "/rest/api/content",     %options ) );
}

sub get_content_children {
    my ( $self, $id, %options ) = @_;

    my $type = delete( $options{type} );
    return HTTP::Request->new( 'GET',
          $type
        ? $self->_url( "/rest/api/content/$id/child/$type", %options )
        : $self->_url( "/rest/api/content/$id/child",       %options ) );
}

sub _init {
    my ( $self, $base_url ) = @_;

    $self->{base_url} = $base_url;

    return $self;
}

sub update_content {
    my ( $self, $id, $content, %options ) = @_;

    return HTTP::Request->new(
        'PUT',
        $self->_url( "/rest/api/content/$id", %options ),
        [ 'Content-Type' => 'application/json' ],
        encode_json($content)
    );
}

sub _url {
    my ( $self, $path, %query_params ) = @_;

    my $url = "$self->{base_url}$path";
    if (%query_params) {
        require URI::Escape;
        my @query_string = ();
        foreach my $key ( sort( keys(%query_params) ) ) {
            push( @query_string, ( @query_string ? '&' : '?' ) );

            push(
                @query_string,
                join(
                    '&',
                    map { URI::Escape::uri_escape($key) . '=' . URI::Escape::uri_escape($_) } (
                        ref( $query_params{$key} ) eq 'ARRAY'
                        ? @{ $query_params{$key} }
                        : ( $query_params{$key} )
                    )
                )
            );
        }
        $url .= ( @query_string ? join( '', @query_string ) : '' );
    }

    return $url;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Atlassian::Confluence::RequestBuilder - A request builder for the Atlassian Confluence REST API

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    my $request_builder = 
        Footprintless::Plugin::Atlassian::Confluence::RequestBuilder
            ->new($base_url);

    # A request to create content
    my $http_request = $request_builder->create_content(
        [
            {
                type => 'page',
                title => 'Foobar',
                space => 'CPA',
                body => {
                    storage => {
                        value => '<p>Foobar paragraph</p>',
                        representation => 'storage',
                    }
                }
            }
        ]);

    # A request to get the content in space CPA with title Foobar
    my $http_request = $request_builder->get_content(
        spaceKey => 'CPA', title => 'Foobar');

    # A request to get the content with id 123
    my $http_request = $request_builder->get_content(id => 123);

    # A request to update the content
    my $http_request = $request_builder->update_content(123,
        [
            {
                type => 'page',
                title => 'Foobars new title',
                body => {
                    storage => {
                        value => '<p>Foobars new paragraph</p>',
                        representation => 'storage',
                    }
                },
                version => {
                    number => $current_version + 1
                }
            }
        ]);

    # A request to delete the content with id 123
    my $http_request = $request_builder->delete_content(123);

=head1 DESCRIPTION

This is the default implementation of a request builder.  It provides a simple
perl interface to the 
L<Atlassian Confluence REST API|https://docs.atlassian.com/atlassian-confluence/REST/latest-server/>.

=head1 CONSTRUCTORS

=head2 new($base_url)

Constructs a new request builder with the provided C<base_url>.  This url
will be used to compose the url for each REST endpoint.

=head1 METHODS

=head2 create_content($content, %options)

A request to create a new piece of Content or publish a draft if the content 
id is present.  All C<%options> will be transformed into query parameters.

=head2 delete_content($id)

A request to trash or purge a piece of Content.

=head2 get_content(%options)

A request to obtain a paginated list of Content, or if C<$option{id}> is
present, the piece of Content identified by it.  All other C<%options> will
be transformed into query parameters.

=head2 get_content_children($id, %options)

A request to return a map of direct children of a piece of Content.  If 
C<$options{type}> is present, only children of the specified type will be
returned.  All other C<%options> will be transformed into query parameters.

=head2 update_content($id, $content, %options)

A request to update a piece of Content.  All C<%options> will be transformed 
into query parameters.

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

L<Footprintless::Plugin::Atlassian::Confluence::ResponseParser|Footprintless::Plugin::Atlassian::Confluence::ResponseParser>

=item *

L<https://docs.atlassian.com/atlassian-confluence/REST/latest-server|https://docs.atlassian.com/atlassian-confluence/REST/latest-server>

=back

=cut
