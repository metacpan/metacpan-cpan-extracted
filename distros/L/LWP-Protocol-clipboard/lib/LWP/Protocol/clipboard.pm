package LWP::Protocol::clipboard;

use strict;
use warnings;

use parent 'LWP::Protocol';
use HTTP::Response;
use HTTP::Status;
#use URI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-10'; # DATE
our $DIST = 'LWP-Protocol-clipboard'; # DIST
our $VERSION = '0.001'; # VERSION

sub request {
    my ($self, $request, $proxy, $arg, $size) = @_;

    if ($proxy) {
        return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
                                   'You can not proxy with clipboard');
    }
    my $method = $request->method;
    unless ($method eq 'GET' || $method eq 'PUT') { # XXX support HEAD
        return HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST,
                                   'Library does not allow method ' .
                                   "$method for 'cpan:' URLs");
    }

    if ($method eq 'GET') {
        require Clipboard::Any;
        my $res = Clipboard::Any::get_clipboard_content();
        my $response = HTTP::Response->new($res->[0], $res->[1]);
        $response->content($res->[2]);
        return $response;
    }

    if ($method eq 'PUT') {
        require Clipboard::Any;
        my $res = Clipboard::Any::add_clipboard_content(content => $request->content);
        my $response = HTTP::Response->new($res->[0], $res->[1]);
        return $response;
    }
}

1;
# ABSTRACT: Get/set clipboard content through LWP

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Protocol::clipboard - Get/set clipboard content through LWP

=head1 VERSION

This document describes version 0.001 of LWP::Protocol::clipboard (from Perl distribution LWP-Protocol-clipboard), released on 2022-10-10.

=head1 SYNOPSIS

 use LWP::UserAgent;
 my $ua = LWP::UserAgent->new;

 # get clipboard content
 my $resp = $ua->get("clipboard:");
 if ($resp->is_success) {
     print "Clipboard content is ", $resp->content;
 }

 # set clipboard content
 my $resp = $ua->put("clipboard:", Content => "new content");
 if ($resp->is_success) {
     print "Clipboard content set";
 }

=head1 DESCRIPTION

This module uses L<Clipboard::Any> to get/set clipboard content.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-Protocol-clipboard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-Protocol-clipboard>.

=head1 SEE ALSO

L<LWP::Protocol>

L<Clipboard::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-Protocol-clipboard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
