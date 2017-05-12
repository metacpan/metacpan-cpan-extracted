package LWP::UserAgent::Patch::LogResponse;

our $DATE = '2016-10-07'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.17 qw();
use base qw(Module::Patch);

our %config;

my $p_simple_request = sub {
    require Log::Any::IfLOG;

    my $ctx  = shift;
    my $orig = $ctx->{orig};
    my $resp = $orig->(@_);

    my $log = Log::Any::IfLOG->get_logger;
    if ($log->is_trace) {

        # there is no equivalent of caller_depth in Log::Any, so we do this only
        # for Log4perl
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1
            if $Log::{"Log4perl::"};

        if ($config{-log_response_header}) {
            $log->tracef("HTTP response header:\n%s",
                         $resp->status_line."\r\n".$resp->headers->as_string);
        }
        if ($config{-log_response_body}) {
            # XXX or 4, if we're calling request() which calls simple_request()
            my @caller = caller(3);
            my $log_b = Log::Any::IfLOG->get_logger(
                category => "LWP_Response_Body::".$caller[0]);
            my $content;
            if ($config{-decode_response_body}) {
                $content = $resp->decoded_content;
            } else {
                $content = $resp->content;
            }
            $log_b->trace($content);
        }

    }

    $resp;
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'wrap',
                mod_version => qr/^6\..*/,
                sub_name    => 'simple_request',
                code        => $p_simple_request,
            },
        ],
        config => {
            -log_response_header  => { default => 1 },
            -log_response_body    => { default => 0 },
            -decode_response_body => { default => 1 },
        }
    };
}

1;
# ABSTRACT: Log raw HTTP responses

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Patch::LogResponse - Log raw HTTP responses

=head1 VERSION

This document describes version 0.10 of LWP::UserAgent::Patch::LogResponse (from Perl distribution LWP-UserAgent-Patch-LogResponse), released on 2016-10-07.

=head1 SYNOPSIS

 use LWP::UserAgent::Patch::LogResponse
     -log_response_header  => 1, # default 1
     -log_response_body    => 1, # default 0
     -decode_response_body => 1, # default 1, turn off, e.g. to get raw gzipped content
 ;

 # now all your LWP HTTP responses are logged

Sample script and output:

 % TRACE=1 perl -MLog::Any::App -MLWP::UserAgent::Patch::LogResponse \
   -MLWP::Simple -e'get "http://localhost:5000/"'
 [261] HTTP response header:
 200 OK
 Date: Mon, 20 Aug 2012 07:47:46 GMT
 Server: HTTP::Server::PSGI
 Content-Length: 13
 Content-Type: text/plain
 Client-Date: Mon, 20 Aug 2012 07:47:46 GMT
 Client-Peer: 127.0.0.1:5000
 Client-Response-Num: 1

=head1 DESCRIPTION

This module patches LWP::UserAgent (which is used by LWP::Simple,
WWW::Mechanize, among others) so that HTTP responses are logged using
L<Log::Any>.

Response body is logged in category C<LWP_Response_Body.*> so it can be
separated. For example, to dump response body dumps to directory instead of
file:

 use Log::Any::App '$log',
    -category_level => {LWP_Response_Body => 'off'},
    -dir            => {
        path           => "/path/to/dir",
        level          => 'off',
        category_level => {LWP_Response_Body => 'trace'},
    };

=for Pod::Coverage ^(patch_data)$

=head1 FAQ

=head2 Why not subclass?

By patching, you do not need to replace all the client code which uses LWP (or
WWW::Mechanize, etc).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Patch-LogResponse>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-Patch-LogResponse>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Patch-LogResponse>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Use L<Net::HTTP::Methods::Patch::LogRequest> to log raw HTTP requests being sent
to servers.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
