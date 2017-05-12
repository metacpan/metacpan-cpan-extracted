package LWP::UserAgent::Patch::LogRequestContent;

our $DATE = '2016-10-07'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.16 qw();
use base qw(Module::Patch);

our %config;

my $p_simple_request = sub {
    require Log::Any::IfLOG;
    my $log = Log::Any::IfLOG->get_logger;

    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my $self    = shift;
    my $request = shift;

    if ($log->is_trace && $request && ref($request) && $request->can('method')) {

        # there is no equivalent of caller_depth in Log::Any, so we do this only
        # for Log4perl
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1
            if $Log::{"Log4perl::"};

        my $content = $request->content;
        $log->tracef("HTTP request body (len=%d):\n%s\n\n",
                     length($content), $content);

    }

    $orig->($self, $request, @_);
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
    };
}

1;
# ABSTRACT: Log HTTP request content (body)

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Patch::LogRequestContent - Log HTTP request content (body)

=head1 VERSION

This document describes version 0.03 of LWP::UserAgent::Patch::LogRequestContent (from Perl distribution LWP-UserAgent-Patch-LogRequestContent), released on 2016-10-07.

=head1 SYNOPSIS

 use LWP::UserAgent::Patch::LogRequestContent;

 # now all your LWP HTTP request content are logged

Sample script and output:

 % TRACE=1 perl -MLog::Any::App
   -MNet::HTTP::Methods::Patch::LogRequest \
   -MLWP::UserAgent::Patch::LogRequestContent \
   -MLWP::UserAgent \
   -e'$ua = LWP::UserAgent->new;
      $ua->post("http://localhost:5000/", {a=>1, b=>2});'

 [cat LWP.UserAgent.Patch.LogRequestContent]HTTP request body (len=7):
 a=1&b=2

 [cat Net.HTTP.Methods.Patch.LogRequest]HTTP request (proto=http, len=186):
 POST / HTTP/1.1
 TE: deflate,gzip;q=0.3
 Connection: TE, close
 Host: localhost:5000
 User-Agent: libwww-perl/6.04
 Content-Length: 7
 Content-Type: application/x-www-form-urlencoded

Or you can also use via L<Log::Any::For::LWP>.

=head1 DESCRIPTION

This module patches LWP::UserAgent (which is used by LWP::Simple,
WWW::Mechanize, among others) so that HTTP request contents are logged using
L<Log::Any>.

=for Pod::Coverage ^(patch_data)$

=head1 FAQ

=head2 Why not subclass?

By patching, you do not need to replace all the client code which uses LWP (or
WWW::Mechanize, etc).

=head2 Why is the request content logged before request headers (when using with Net::HTTP::Methods::Patch::LogRequest)?

Yup, it's ugly. I'm working on that.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Patch-LogRequestContent>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-Patch-LogRequestContent>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Patch-LogRequestContent>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Use L<Net::HTTP::Methods::Patch::LogRequest> to log raw HTTP request headers
being sent to servers.

Use L<LWP::UserAgent::Patch::LogResponse> to log HTTP responses.

L<Log::Any::For::LWP> bundles all three mentioned patches in a single convenient
package.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
