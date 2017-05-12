use strict;
use warnings;
package MetaCPAN::API;
# ABSTRACT: A comprehensive, DWIM-featured API to MetaCPAN (DEPRECATED)
$MetaCPAN::API::VERSION = '0.50';
use Moo;
use Types::Standard qw<Str ArrayRef InstanceOf>;
use namespace::autoclean;

use Carp;
use JSON;
use Try::Tiny;
use HTTP::Tiny;
use URI::Escape 'uri_escape';

with qw/
    MetaCPAN::API::Author
    MetaCPAN::API::Distribution
    MetaCPAN::API::Favorite
    MetaCPAN::API::File
    MetaCPAN::API::Autocomplete
    MetaCPAN::API::Module
    MetaCPAN::API::POD
    MetaCPAN::API::Rating
    MetaCPAN::API::Release
    MetaCPAN::API::Source
/;

has base_url => (
    is      => 'ro',
    isa     => Str,
    default => sub{'http://api.metacpan.org/v0'},
);

has ua => (
    is  => 'ro',
    lazy => 1,
    builder => '_build_ua',
    isa => InstanceOf['HTTP::Tiny'],
);

has ua_args => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub {
        my $version = $MetaCPAN::API::VERSION || 'xx';
        return [ agent => "MetaCPAN::API/$version" ];
    },
);

sub _build_ua {
    my $self = shift;
    return HTTP::Tiny->new( @{ $self->ua_args } );
}

sub fetch {
    my $self    = shift;
    my $url     = shift;
    my $extra   = $self->_build_extra_params(@_);
    my $base    = $self->base_url;
    my $req_url = $extra ? "$base/$url?$extra" : "$base/$url";

    my $result  = $self->ua->get($req_url);
    return $self->_decode_result( $result, $req_url );
}

sub post {
    my $self  = shift;
    my $url   = shift;
    my $query = shift;
    my $base  = $self->base_url;

    defined $url
        or croak 'First argument of URL must be provided';

    ref $query and ref $query eq 'HASH'
        or croak 'Second argument of query hashref must be provided';

    my $query_json = to_json( $query, { canonical => 1 } );
    my $result     = $self->ua->request(
        'POST',
        "$base/$url",
        {
            headers => { 'Content-Type' => 'application/json' },
            content => $query_json,
        }
    );

    return $self->_decode_result( $result, $url, $query_json );
}

sub _decode_result {
    my $self = shift;
    my ( $result, $url, $original ) = @_;
    my $decoded_result;

    ref $result and ref $result eq 'HASH'
        or croak 'First argument must be hashref';

    defined $url
        or croak 'Second argument of a URL must be provided';

    if ( defined ( my $success = $result->{'success'} ) ) {
        my $reason = $result->{'reason'} || '';
        $reason .= ( defined $original ? " (request: $original)" : '' );

        $success or croak "Failed to fetch '$url': $reason";
    } else {
        croak 'Missing success in return value';
    }

    defined ( my $content = $result->{'content'} )
        or croak 'Missing content in return value';

    try   { $decoded_result = decode_json $content }
    catch { croak "Couldn't decode '$content': $_" };

    return $decoded_result;
}

sub _build_extra_params {
    my $self = shift;

    @_ % 2 == 0
        or croak 'Incorrect number of params, must be key/value';
    my %extra = @_;

    # if it's deep, JSON encoding needs to be involved
    if (scalar grep { ref } values %extra) {
        my $query_json = to_json( \%extra, { canonical => 1 } );
        %extra = ( source => $query_json );
    }

    my $extra = join '&', map {
        "$_=" . uri_escape( $extra{$_} )
    } sort keys %extra;

    return $extra;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::API - A comprehensive, DWIM-featured API to MetaCPAN (DEPRECATED)

=head1 VERSION

version 0.50

=head1 SYNOPSIS

    # simple usage
    my $mcpan  = MetaCPAN::API->new();
    my $author = $mcpan->author('XSAWYERX');
    my $dist   = $mcpan->release( distribution => 'MetaCPAN-API' );

    # advanced usage with cache (contributed by Kent Fredric)
    require CHI;
    require WWW::Mechanize::Cached;
    require HTTP::Tiny::Mech;
    require MetaCPAN::API;

    my $mcpan = MetaCPAN::API->new(
      ua => HTTP::Tiny::Mech->new(
        mechua => WWW::Mechanize::Cached->new(
          cache => CHI->new(
            driver => 'File',
            root_dir => '/tmp/metacpan-cache',
          ),
        ),
      ),
    );

=head1 DESCRIPTION

This was the original hopefully-complete API-compliant interface to MetaCPAN
(L<https://metacpan.org>).  It has now been superseded by L<MetaCPAN::Client>.

=head1 DEPRECATED

B<THIS MODULE IS DEPRECATED, DO NOT USE!>

This module has been completely rewritten to address a multitude
of problems, and is now available under the new official name:
L<MetaCPAN::Client>.

Please do not use this module.

=head1 ATTRIBUTES

=head2 base_url

    my $mcpan = MetaCPAN::API->new(
        base_url => 'http://localhost:9999',
    );

This attribute is used for REST requests. You should set it to where the
MetaCPAN is accessible. By default it's already set correctly, but if you're
running a local instance of MetaCPAN, or use a local mirror, or tunnel it
through a local port, or any of those stuff, you would want to change this.

Default: I<http://api.metacpan.org/v0>.

This attribute is read-only (immutable), meaning that once it's set on
initialize (via C<new()>), you cannot change it. If you need to, create a
new instance of MetaCPAN::API. Why is it immutable? Because it's better.

=head2 ua

This attribute is used to contain the user agent used for running the REST
request to the server. It is specifically set to L<HTTP::Tiny>, so if you
want to set it manually, make sure it's of HTTP::Tiny.

HTTP::Tiny is used as part of the philosophy of keeping it tiny.

This attribute is read-only (immutable), meaning that once it's set on
initialize (via C<new()>), you cannot change it. If you need to, create a
new instance of MetaCPAN::API. Why is it immutable? Because it's better.

=head2 ua_args

    my $mcpan = MetaCPAN::API->new(
        ua_args => [ agent => 'MyAgent' ],
    );

The arguments that will be given to the L<HTTP::Tiny> user agent.

This attribute is read-only (immutable), meaning that once it's set on
initialize (via C<new()>), you cannot change it. If you need to, create a
new instance of MetaCPAN::API. Why is it immutable? Because it's better.

The default is a user agent string: B<MetaCPAN::API/$version>.

=head1 METHODS

=head2 fetch

    my $result = $mcpan->fetch('/release/distribution/Moose');

    # with parameters
    my $more = $mcpan->fetch(
        '/release/distribution/Moose',
        param => 'value',
    );

This is a helper method for API implementations. It fetches a path from
MetaCPAN, decodes the JSON from the content variable and returns it.

You don't really need to use it, but you can in case you want to write your
own extension implementation to MetaCPAN::API.

It accepts an additional hash as C<GET> parameters.

=head2 post

    # /release&content={"query":{"match_all":{}},"filter":{"prefix":{"archive":"Cache-Cache-1.06"}}}
    my $result = $mcpan->post(
        'release',
        {
            query  => { match_all => {} },
            filter => { prefix => { archive => 'Cache-Cache-1.06' } },
        },
    );

The POST equivalent of the C<fetch()> method. It gets the path and JSON request.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
