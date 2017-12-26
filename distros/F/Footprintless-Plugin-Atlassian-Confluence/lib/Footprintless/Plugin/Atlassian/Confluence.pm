use strict;
use warnings;

package Footprintless::Plugin::Atlassian::Confluence;
$Footprintless::Plugin::Atlassian::Confluence::VERSION = '1.03';
# ABSTRACT: A Footprintless plugin for working with Atlassian Confluence
# PODNAME: Footprintless::Plugin::Atlassian::Confluence

use parent qw(Footprintless::Plugin);

sub _client {
    my ( $self, $footprintless, $coordinate, %options ) = @_;

    $options{request_builder_module} = $self->{config}{request_builder_module}
        if ( !$options{request_builder_module}
        && $self->{config}{request_builder_module} );
    $options{response_parser_module} = $self->{config}{response_parser_module}
        if ( !$options{response_parser_module}
        && $self->{config}{response_parser_module} );

    require Footprintless::Plugin::Atlassian::Confluence::Client;
    return Footprintless::Plugin::Atlassian::Confluence::Client->new( $footprintless,
        $coordinate, %options );
}

sub factory_methods {
    my ($self) = @_;
    return {
        confluence_client => sub {
            return $self->_client(@_);
        },
    };
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Atlassian::Confluence - A Footprintless plugin for working with Atlassian Confluence

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Provides a C<confluence_client> factory method to obtain a REST client for the 
L<Atlassian Confluence REST API|https://developer.atlassian.com/confdev/confluence-server-rest-api>.

=head1 ENTITIES

As with all plugins, this must be registered on the C<footprintless> entity.  

    plugins => [
        'Footprintless::Plugin::Atlassian::Confluence',
    ],

You may provide custom implementation of the request builder or response
parser as well:

    plugins => [
        'Footprintless::Plugin::Atlassian::Confluence',
    ],
    'Footprintless::Plugin::Atlassian::Confluence' => {
        request_builder => 'My::Confluence::RequestBuilder',
        response_parser => 'My::Confluence::ResponseParser',
    }

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

L<Footprintless|Footprintless>

=item *

L<Footprintless::MixableBase|Footprintless::MixableBase>

=item *

L<Footprintless::Plugin::Atlassian::Confluence|Footprintless::Plugin::Atlassian::Confluence>

=item *

L<Footprintless::Plugin::Atlassian::Confluence::Client|Footprintless::Plugin::Atlassian::Confluence::Client>

=item *

L<Footprintless::Plugin::Atlassian::Confluence::RequestBuilder|Footprintless::Plugin::Atlassian::Confluence::RequestBuilder>

=item *

L<Footprintless::Plugin::Atlassian::Confluence::ResponseParser|Footprintless::Plugin::Atlassian::Confluence::ResponseParser>

=item *

L<https://docs.atlassian.com/atlassian-confluence/REST/latest-server|https://docs.atlassian.com/atlassian-confluence/REST/latest-server>

=back

=for Pod::Coverage factory_methods

=cut
