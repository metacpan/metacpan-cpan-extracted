use strict;
use warnings;

package Footprintless::Plugin::Atlassian::Confluence::ResponseParser;
$Footprintless::Plugin::Atlassian::Confluence::ResponseParser::VERSION = '1.03';
# ABSTRACT: A response parser for the Atlassian Confluence REST API
# PODNAME: Footprintless::Plugin::Atlassian::Confluence::ResponseParser

use JSON;

sub new {
    return bless( {}, shift )->_init(@_);
}

sub create_content {
    my ( $self, $http_response ) = @_;
    return $self->_parse_response($http_response);
}

sub delete_content {
    my ( $self, $http_response ) = @_;
    return $self->_parse_response($http_response);
}

sub get_content {
    my ( $self, $http_response ) = @_;
    return $self->_parse_response($http_response);
}

sub get_content_children {
    my ( $self, $http_response ) = @_;
    return $self->_parse_response($http_response);
}

sub _init {
    my ($self) = @_;
    return $self;
}

sub _parse_response {
    my ( $self, $http_response ) = @_;

    my %response = (
        code    => $http_response->code(),
        message => $http_response->message(),
    );

    my $content = $http_response->decoded_content();
    if ( $http_response->is_success() ) {
        $response{success} = 1;
        $response{content} = $content ? decode_json($content) : '';
    }
    else {
        $response{success} = 0;
        $response{content} = $http_response->decoded_content();
    }

    return \%response;
}

sub update_content {
    my ( $self, $http_response ) = @_;
    return $self->_parse_response($http_response);
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Atlassian::Confluence::ResponseParser - A response parser for the Atlassian Confluence REST API

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    my $response_parser = 
        Footprintless::Plugin::Atlassian::Confluence::ResponseParser
            ->new();

    # A parse a get content response
    my $response = $response_parser->get_content($http_response);
    die('failed') unless $response->{success};

=head1 DESCRIPTION

This is the default implementation of a response parser.  There is a parse 
method for corresponding to each build method in 
L<Footprintless::Plugin::Atlassian::Confluence::RequestBuilder>, and they
all parse http responses into a hasref of the form:

   my $response = {
       status => 0, # truthy if $http_response->is_success()
       code => 200, # $http_response->code()
       message => 'Success', # $http_response->message()
       content => {} # decode_json($http_response->decoded_content())
   };

=head1 CONSTRUCTORS

=head2 new()

Constructs a new response parser.

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

L<Footprintless::Plugin::Atlassian::Confluence::RequestBuilder|Footprintless::Plugin::Atlassian::Confluence::RequestBuilder>

=item *

L<https://docs.atlassian.com/atlassian-confluence/REST/latest-server|https://docs.atlassian.com/atlassian-confluence/REST/latest-server>

=back

=for Pod::Coverage create_content delete_content get_content get_content_children update_content 

=cut
