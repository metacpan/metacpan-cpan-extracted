package HTTP::Tiny::Plugin::Retry;

our $DATE = '2019-04-12'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Time::HiRes qw(sleep);

sub after_request {
    my ($self, $r) = @_;

    $r->{config}{max_attempts} //=
        $ENV{HTTP_TINY_PLUGIN_RETRY_MAX_ATTEMPTS} // 3;
    $r->{config}{delay}        //=
        $ENV{HTTP_TINY_PLUGIN_RETRY_DELAY}        // 2;

    return -1 if $r->{response}{status} !~ /\A[5]/;
    $r->{retries} //= 0;
    return 0 if $r->{config}{max_attempts} &&
        $r->{retries} >= $r->{config}{max_attempts};
    $r->{retries}++;
    my ($ht, $method, $url, $options) = @{ $r->{argv} };
    log_trace "Failed requesting %s (%s - %s), retrying in %.1f second(s) (%d of %d) ...",
        $url,
        $r->{response}{status},
        $r->{response}{reason},
        $r->{config}{delay},
        $r->{retries},
        $r->{config}{max_attempts};
    sleep $r->{config}{delay};
    98; # repeat request()
}

1;
# ABSTRACT: Retry failed request

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Plugin::Retry - Retry failed request

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::Plugin::Retry (from Perl distribution HTTP-Tiny-Plugin-Retry), released on 2019-04-12.

=head1 SYNOPSIS

 use HTTP::Tiny::Plugin 'Retry' => {
     max_attempts => 3, # optional, default 3
     delay        => 2, # optional, default 2
     retry_if     => qr/^[45]/, # optional, default is only 5xx errors are retried
 };

 my $res  = HTTP::Tiny::Plugin->new->get("http://www.example.com/");

=head1 DESCRIPTION

This plugin retries failed response. By default only retries 5xx failures, as
4xx are considered to be client's fault (but you can configure it with
L</retry_if>).

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 max_attempts

Int.

=head2 delay

Float.

=head2 retry_if

Regex or code. If regex, then will be matched against response status. If code,
will be called with arguments: C<< ($self, $response) >>.

=head1 ENVIRONMENT

=head2 HTTP_TINY_PLUGIN_RETRY_MAX_ATTEMPTS

Int.

=head2 HTTP_TINY_PLUGIN_RETRY_DELAY

Int.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Plugin-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Plugin-Retry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Plugin-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
