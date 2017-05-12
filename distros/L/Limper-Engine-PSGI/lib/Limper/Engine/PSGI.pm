package Limper::Engine::PSGI;
$Limper::Engine::PSGI::VERSION = '0.003';
use base 'Limper';
use 5.10.0;
use strict;
use warnings;

package		# newline because Dist::Zilla::Plugin::PkgVersion and PAUSE indexer
  Limper;

sub get_psgi {
    my ($env) = @_;

    delete response->{$_} for keys %{&response};
    response->{headers} = {};

    delete request->{$_} for keys %{&request};
    request->{method}      = $env->{REQUEST_METHOD};
    request->{uri}         = $env->{REQUEST_URI};
    request->{version}     = $env->{SERVER_PROTOCOL};
    request->{remote_host} = $env->{REMOTE_HOST};
    (request->{scheme}, request->{authority}, request->{path}, request->{query}, request->{fragment}) =
        request->{uri} =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;	# from https://metacpan.org/pod/URI
    request->{headers}    = {};

    request->{headers}{'content-length'} = $env->{CONTENT_LENGTH} if exists $env->{CONTENT_LENGTH};
    request->{headers}{'content-type'} = $env->{CONTENT_TYPE} if exists $env->{CONTENT_TYPE};
    for my $header (grep { /^HTTP_/ } keys %$env) {
        my $name = lc $header;
        $name =~ s/^http_//;
        $name =~ s/_/-/g;
        my @values = split /, /, $env->{$header};
        request->{headers}{$name} = @values > 1 ? \@values : $values[0];
    }
    # this covers both requests with Content-Length: <INT> and Tranfer-Encoding: chunked
    $env->{'psgi.input'}->read(request->{body}, $env->{CONTENT_LENGTH}) if exists $env->{CONTENT_LENGTH};
}

hook request_handler => sub {
    eval {
        get_psgi @_;
        $_ = handle_request;
    };
    return $_ unless $@;
    warning $@;
    status 500;
    response->{body} = options->{debug} // 0 ? $@ : 'Internal Server Error';
    send_response;
};

hook response_handler => sub {
    [
        response->{status},
        [ headers ],
        defined response->{body} ? (ref response->{body} ? response->{body} : [response->{body}]) : [],
    ];
};

1;

=for Pod::Coverage get_psgi

=head1 NAME

Limper::Engine::PSGI - PSGI engine for Limper

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Limper::Engine::PSGI; # all you need to do is add this line
  use Limper;               # this must come after all extensions

  # routes and whatnot

  limp;

=head1 DESCRIPTION

B<Limper::Engine::PSGI> extends L<Limper> to use L<PSGI> instead of the built-in web
server.

All you need to do in order to use L<PSGI> is add C<use Limper::Engine::PSGI;>
somewhere before C<use Limper;> in your app.

This package sets a B<request_handler> and B<response_handler> for
L<Limper>, as well as defining a non-exportable sub that turns a PSGI
request into one that B<Limper> understands.

Note that unlike other hooks, only the first B<request_handler> and
B<response_handler> is used, so care should be taken to load this first and
not load another B<Limper::Engine::> that also expects to make use of these
hooks.

=head1 EXPORTS

Nothing additional is exported.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Limper>

L<Limper::SendFile>

L<Limper::SendJSON>

L<PSGI>

L<Plack>

L<Starman>

L<The uWSGI project|https://uwsgi-docs.readthedocs.org/en/latest/>

=cut
