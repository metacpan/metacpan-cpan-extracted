package LWPx::UserAgent::Cached;

# ABSTRACT: Subclass of LWP::UserAgent that caches HTTP GET requests

use strict;
use warnings;
use utf8;
our $VERSION = '0.011';

## no critic (Bangs::ProhibitCommentedOutCode)

#pod =head1 SYNOPSIS
#pod
#pod     use LWPx::UserAgent::Cached;
#pod     use CHI;
#pod
#pod     my $ua = LWPx::UserAgent::Cached->new(
#pod         cache => CHI->new(
#pod             driver => 'File', root_dir => '/tmp/cache', expires_in => '1d',
#pod         ),
#pod     );
#pod     $ua->get('http://www.perl.org/');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module borrows the caching logic from
#pod L<C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached> but
#pod without inheriting from
#pod L<C<WWW::Mechanize>|WWW::Mechanize>; instead it is just
#pod a direct subclass of
#pod L<C<LWP::UserAgent>|LWP::UserAgent>.
#pod
#pod =head2 HTTP/1.1 cache operation
#pod
#pod Full HTTP/1.1 cache compliance is a work in progress. As of version 0.006 we
#pod have limited support for HTTP/1.1 C<ETag>/C<If-None-Match> headers, as well as
#pod C<no-cache> and C<no-store> C<Cache-Control> directives (both on request and
#pod response) and the C<Pragma: no-cache> request header.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<C<LWP::UserAgent>|LWP::UserAgent>
#pod
#pod Parent of this class.
#pod
#pod =item L<C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached>
#pod
#pod Inspiration for this class.
#pod
#pod =back
#pod
#pod =cut

use CHI;
use HTTP::Status qw(HTTP_OK HTTP_MOVED_PERMANENTLY HTTP_NOT_MODIFIED);
use List::Util 1.33 'any';
use Moo 1.004005;
use Types::Standard qw(Bool HasMethods HashRef InstanceOf Maybe);
use namespace::clean;
extends 'LWP::UserAgent';

#pod =attr cache
#pod
#pod Settable at construction, defaults to using
#pod L<C<CHI::Driver::RawMemory>|CHI::Driver::RawMemory> with
#pod an instance-specific hash datastore and a namespace with the current
#pod package name. You can use your own caching object here as long as it has
#pod C<get> and C<set> methods.
#pod
#pod =cut

has cache => (
    is      => 'lazy',
    isa     => HasMethods [qw(get set)],
    default => sub {
        CHI->new(
            serializer => 'Sereal',
            driver     => 'RawMemory',
            datastore  => $_[0]->_cache_datastore,
            namespace  => __PACKAGE__,
        );
    },
);
has _cache_datastore =>
    ( is => 'lazy', isa => HashRef, default => sub { {} } );

#pod =attr is_cached
#pod
#pod Read-only accessor that indicates if the current request is cached or not.
#pod
#pod =cut

has is_cached =>
    ( is => 'rwp', isa => Maybe [Bool], init_arg => undef, default => undef );

#pod =attr cache_undef_content_length
#pod
#pod Settable at construction or anytime thereafter, indicates whether we should
#pod cache content even if the HTTP C<Content-Length> header is missing or
#pod undefined. Defaults to false.
#pod
#pod =cut

has cache_undef_content_length => ( is => 'rw', isa => Bool, default => 0 );

#pod =attr cache_zero_content_length
#pod
#pod Settable at construction or anytime thereafter, indicates whether we should
#pod cache content even if the HTTP C<Content-Length> header is zero. Defaults to
#pod false.
#pod
#pod =cut

has cache_zero_content_length => ( is => 'rw', isa => Bool, default => 0 );

#pod =attr cache_mismatch_content_length
#pod
#pod Settable at construction or anytime thereafter, indicates whether we should
#pod cache content even if the length of the data does not match the HTTP
#pod C<Content-Length> header. Defaults to true.
#pod
#pod =cut

has cache_mismatch_content_length =>
    ( is => 'rw', isa => Bool, default => 1 );

#pod =attr ref_in_cache_key
#pod
#pod Settable at construction or anytime thereafter, indicates whether we should
#pod store the HTTP referrer in the cache key. Defaults to false.
#pod
#pod =cut

has ref_in_cache_key => ( is => 'rw', isa => Bool, default => 0 );

#pod =attr positive_cache
#pod
#pod Settable at construction or anytime thereafter, indicates whether we should
#pod only cache positive responses (HTTP response codes from C<200> to C<300>
#pod inclusive) or cache everything. Defaults to true.
#pod
#pod =cut

has positive_cache => ( is => 'rw', isa => Bool, default => 1 );

#pod =attr ignore_headers
#pod
#pod Settable at construction or anytime thereafter, indicates whether we should
#pod ignore C<Cache-Control: no-cache>, C<Cache-Control: no-store>, and
#pod C<Pragma: no-cache> HTTP headers when deciding whether to cache a response.
#pod Defaults to false.
#pod
#pod B<Important note:> This option is potentially dangerous, as it ignores the
#pod explicit instructions from the server and thus can lead to returning stale
#pod content.
#pod
#pod =cut

has ignore_headers => ( is => 'rw', isa => Bool, default => 0 );

#pod =head1 HANDLERS
#pod
#pod This module works by adding C<request_send>, C<response_done> and
#pod C<response_header> L<handlers|LWP::UserAgent/Handlers>
#pod that run on successful HTTP C<GET> requests.
#pod If you need to modify or remove these handlers you may use LWP::UserAgent's
#pod L<handler-related methods|LWP::UserAgent/Handlers>.
#pod
#pod =for Pod::Coverage BUILD
#pod
#pod =cut

sub BUILD {
    my $self = shift;

    $self->add_handler( request_send => \&_get_cache, ( m_method => 'GET' ) );
    $self->add_handler(
        response_done => \&_set_cache,
        ( m_method => 'GET', m_code => 2 ),
    );
    $self->add_handler(
        response_header => \&_get_not_modified,
        ( m_method => 'GET', m_code => HTTP_NOT_MODIFIED ),
    );

    return;
}

# load from cache on each GET request
sub _get_cache {
    my ( $request, $self ) = @_;
    $self->_set_is_cached(0);

    my $clone = $request->clone;
    if ( not $self->ref_in_cache_key ) { $clone->header( Referer => undef ) }
    return if $self->_no_cache_header_directives($request);

    return if not my $response = $self->cache->get( $clone->as_string );
    return
        if $response->code < HTTP_OK
        or $response->code > HTTP_MOVED_PERMANENTLY;

    if ( $response->header('etag') ) {
        $clone->header( if_none_match => $response->header('etag') );
        $response = $self->request($clone);
    }
    return if $self->_no_cache_header_directives($response);

    $self->_set_is_cached(1);
    return $response;
}

sub _get_not_modified {
    my ( $response, $self ) = @_;
    $self->_set_is_cached(0);

    my $request = $response->request->clone;
    $request->remove_header(qw(if_modified_since if_none_match));

    my $cached_response = $self->cache->get( $request->as_string );
    $response->content( $cached_response->decoded_content );

    $self->_set_is_cached(1);
    return;
}

# save to cache after successful GET
sub _set_cache {
    my ( $response, $self ) = @_;
    return if not $response;

    if (not($response->header('client-transfer-encoding')
            and any { 'chunked' eq $_ }
            $response->header('client-transfer-encoding')
        )
        )
    {
        for ( $response->header('size') ) {
            return
                if not defined and $self->cache_undef_content_length;
            return
                if 0 == $_
                and not $self->cache_zero_content_length;
            return
                if $_ != length $response->content
                and not $self->cache_mismatch_content_length;
        }
    }

    for my $message ( $response, $response->request ) {
        return if $self->_no_cache_header_directives($message);
    }

    $response->decode;
    $self->cache->set( $response->request->as_string => $response );
    return;
}

sub _no_cache_header_directives {
    my ( $self, $message ) = @_;
    return if $self->ignore_headers;

    for my $header_name (qw(pragma cache_control)) {
        if ( my @directives = $message->header($header_name) ) {
            return 1 if any {/\A no- (?: cache | store ) /xms} @directives;
        }
    }
    return;
}

#pod =for Pod::Coverage FOREIGNBUILDARGS
#pod
#pod =cut

## no critic (Subroutines::RequireArgUnpacking)
sub FOREIGNBUILDARGS {
    shift;
    return 'HASH' eq ref $_[0] ? %{ $_[0] } : @_;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner ZipRecruiter cpan testmatrix url bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

LWPx::UserAgent::Cached - Subclass of LWP::UserAgent that caches HTTP GET requests

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use LWPx::UserAgent::Cached;
    use CHI;

    my $ua = LWPx::UserAgent::Cached->new(
        cache => CHI->new(
            driver => 'File', root_dir => '/tmp/cache', expires_in => '1d',
        ),
    );
    $ua->get('http://www.perl.org/');

=head1 DESCRIPTION

This module borrows the caching logic from
L<C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached> but
without inheriting from
L<C<WWW::Mechanize>|WWW::Mechanize>; instead it is just
a direct subclass of
L<C<LWP::UserAgent>|LWP::UserAgent>.

=head2 HTTP/1.1 cache operation

Full HTTP/1.1 cache compliance is a work in progress. As of version 0.006 we
have limited support for HTTP/1.1 C<ETag>/C<If-None-Match> headers, as well as
C<no-cache> and C<no-store> C<Cache-Control> directives (both on request and
response) and the C<Pragma: no-cache> request header.

=head1 ATTRIBUTES

=head2 cache

Settable at construction, defaults to using
L<C<CHI::Driver::RawMemory>|CHI::Driver::RawMemory> with
an instance-specific hash datastore and a namespace with the current
package name. You can use your own caching object here as long as it has
C<get> and C<set> methods.

=head2 is_cached

Read-only accessor that indicates if the current request is cached or not.

=head2 cache_undef_content_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the HTTP C<Content-Length> header is missing or
undefined. Defaults to false.

=head2 cache_zero_content_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the HTTP C<Content-Length> header is zero. Defaults to
false.

=head2 cache_mismatch_content_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the length of the data does not match the HTTP
C<Content-Length> header. Defaults to true.

=head2 ref_in_cache_key

Settable at construction or anytime thereafter, indicates whether we should
store the HTTP referrer in the cache key. Defaults to false.

=head2 positive_cache

Settable at construction or anytime thereafter, indicates whether we should
only cache positive responses (HTTP response codes from C<200> to C<300>
inclusive) or cache everything. Defaults to true.

=head2 ignore_headers

Settable at construction or anytime thereafter, indicates whether we should
ignore C<Cache-Control: no-cache>, C<Cache-Control: no-store>, and
C<Pragma: no-cache> HTTP headers when deciding whether to cache a response.
Defaults to false.

B<Important note:> This option is potentially dangerous, as it ignores the
explicit instructions from the server and thus can lead to returning stale
content.

=head1 REQUIRES

=over 4

=item * L<CHI|CHI>

=item * L<HTTP::Status|HTTP::Status>

=item * L<Moo|Moo>

=item * L<Types::Standard|Types::Standard>

=item * L<namespace::clean|namespace::clean>

=back

=head1 SEE ALSO

=over

=item L<C<LWP::UserAgent>|LWP::UserAgent>

Parent of this class.

=item L<C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached>

Inspiration for this class.

=back

=head1 HANDLERS

This module works by adding C<request_send>, C<response_done> and
C<response_header> L<handlers|LWP::UserAgent/Handlers>
that run on successful HTTP C<GET> requests.
If you need to modify or remove these handlers you may use LWP::UserAgent's
L<handler-related methods|LWP::UserAgent/Handlers>.

=for Pod::Coverage BUILD

=for Pod::Coverage FOREIGNBUILDARGS

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc LWPx::UserAgent::Cached

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/LWPx-UserAgent-Cached>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/LWPx-UserAgent-Cached>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/L/LWPx-UserAgent-Cached>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=LWPx-UserAgent-Cached>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=LWPx::UserAgent::Cached>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
L<https://github.com/mjgardner/LWPx-UserAgent-Cached/issues>.
You will be automatically notified of any progress on the
request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/LWPx-UserAgent-Cached>

  git clone git://github.com/mjgardner/LWPx-UserAgent-Cached.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
