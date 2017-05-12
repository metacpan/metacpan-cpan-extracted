package LWP::Protocol::GHTTP;

use strict;
use warnings;
use 5.008001;

use base 'LWP::Protocol';

use Carp ();
use HTTP::GHTTP qw(METHOD_GET METHOD_HEAD METHOD_POST);
use HTTP::Response ();
use HTTP::Status qw(:constants);
use IO::Handle ();
use Try::Tiny qw(try catch);
use utf8;

our $VERSION = '6.16';

my %METHOD = (GET => METHOD_GET, HEAD => METHOD_HEAD, POST => METHOD_POST,);

sub request {
    my ($self, $request, $proxy, $arg, $size, $timeout) = @_;

    my $method = $request->method;
    unless (exists $METHOD{$method}) {
        return HTTP::Response->new(HTTP_BAD_REQUEST, "Bad method '$method'");
    }

    my $r = HTTP::GHTTP->new($request->uri);

    # XXX what headers for repeated headers here?
    $request->headers->scan(sub { $r->set_header(@_) });

    $r->set_type($METHOD{$method});

    # XXX should also deal with subroutine content.
    my $cref = $request->content_ref;
    $r->set_body($$cref) if length($$cref);

    # XXX is this right
    $r->set_proxy($proxy->as_string) if $proxy;

    $r->process_request;

    my $response = HTTP::Response->new($r->get_status);

    # XXX How can get the headers out of $r??  This way is too stupid.
    my @headers = try {
        return $r->get_headers();    # not always available
    }
    catch {
        return
            qw(Date Connection Server Content-type Accept-Ranges Server Content-Length Last-Modified ETag);
    };
    for my $head (@headers) {
        my $v = $r->get_header($head);
        $response->header($head => $v) if defined $v;
    }

    return $self->collect_once($arg, $response, $r->get_body);
}

1;    # End of LWP::Protocol::GHTTP

=encoding utf8

=head1 NAME

LWP::Protocol::GHTTP - (DEPRECATED) Provide GHTTP support for L<LWP::UserAgent> via L<HTTP::GHTTP>.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use LWP::UserAgent;

    # create a new object
    LWP::Protocol::implementor('http', 'LWP::Protocol::GHTTP');
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get('http://www.example.com');
    # note that we can only support the GET HEAD and POST verbs.

=head1 DESCRIPTION

This module depends on the GNOME libghttp
L<http://ftp.gnome.org/pub/gnome/sources/libghttp> project. That project is no
longer in development.  If you are trying to use this module, you'd likely do
better to just use L<LWP::Protocol::http> or L<LWP::Protocol::https>.

L<LWP::Protocol::GHTTP> is only capable of dispatching requests using the C<GET>,
C<POST>, or C<HEAD> verbs.

You have been warned.

The L<LWP::Protocol::GHTTP> module provides support for using HTTP schemed URLs
with LWP.  This module is a plug-in to the LWP protocol handling, but since it
takes over the HTTP scheme, you have to tell LWP we want to use this plug-in by
calling L<LWP::Protocol>'s C<implementor> function.

This module used to be bundled with L<libwww-perl>, but it was unbundled in
v6.16 in order to be able to declare its dependencies properly for the CPAN
tool-chain. Applications that need GHTTP support can just declare their
dependency on L<LWP::Protocol::GHTTP> and will no longer need to know what
underlying modules to install.

=head1 CAVEATS

WARNING!

This module depends on the GNOME libghttp
L<http://ftp.gnome.org/pub/gnome/sources/libghttp> project. That project is no
longer in development.  If you are trying to use this module, you'd likely do
better to just use L<LWP::Protocol::http> or L<LWP::Protocol::https>.

Also, L<LWP::Protocol::GHTTP> is only capable of dispatching requests using the C<GET>,
C<POST>, or C<HEAD> verbs.

=head1 FUNCTIONS

L<LWP::Protocol::GHTTP> inherits all functions from L<LWP::Protocol> and provides the following
overriding functions.

=head2 request

    my $response = $ua->request($request, $proxy, undef);
    my $response = $ua->request($request, $proxy, '/tmp/sss');
    my $response = $ua->request($request, $proxy, \&callback, 1024);

Dispatches a request over the HTTP protocol and returns a response object.
Refer to L<LWP::UserAgent> for description of the arguments.

=head1 AUTHOR

Gisle Aas <F<gisle@ActiveState.com>>

=head1 CONTRIBUTORS

=over 4

=item *

Chase Whitener <F<capoeirab@cpan.org>>

=back

=head1 BUGS

Please report any bugs or feature requests on GitHub L<https://github.com/genio/lwp-protocol-ghttp/issues>.
We appreciate any and all criticism, bug reports, enhancements, or fixes.

=head1 LICENSE AND COPYRIGHT

Copyright 1997-2011 Gisle Aas.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
