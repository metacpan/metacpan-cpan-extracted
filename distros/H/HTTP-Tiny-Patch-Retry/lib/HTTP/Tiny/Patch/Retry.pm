package HTTP::Tiny::Patch::Retry;

our $DATE = '2018-10-06'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Module::Patch qw();
use base qw(Module::Patch);

our %config;

my $p_request = sub {
    my $ctx = shift;
    my $orig = $ctx->{orig};

    my ($self, $method, $url) = @_;

    my $retries = 0;
    my $res;
    while (1) {
        $res = $orig->(@_);
        return $res if $res->{status} !~ /\A[5]/;
        last if $retries >= $config{-retries};
        $retries++;
        log_trace "Failed requesting $url ($res->{status} - $res->{reason}), retrying" .
            ($config{-delay} ? " in $config{-delay} second(s)" : "") .
            " ($retries of $config{-retries}) ...";
        sleep $config{-delay};
    }
    $res;
};

sub patch_data {
    return {
        v => 3,
        config => {
            -delay => {
                summary => 'Number of seconds to wait between retries',
                schema  => 'nonnegint*',
                default => 2,
            },
            -retries => {
                summary => 'Maximum number of retries to perform consecutively on a request (0=disable retry)',
                schema  => 'nonnegint*',
                default => 3,
            },
        },
        patches => [
            {
                action      => 'wrap',
                mod_version => qr/^0\.*/,
                sub_name    => 'request',
                code        => $p_request,
            },
        ],
    };
}

1;
# ABSTRACT: Retry failed HTTP::Tiny requests

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Patch::Retry - Retry failed HTTP::Tiny requests

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::Patch::Retry (from Perl distribution HTTP-Tiny-Patch-Retry), released on 2018-10-06.

=head1 SYNOPSIS

From Perl:

 use HTTP::Tiny::Patch::Retry
     # -retries => 4, # optional, default is 3
     # -delay   => 5, # optional, default is 2
 ;

 my $res  = HTTP::Tiny->new->get("http://www.example.com/");

=head1 DESCRIPTION

This module patches L<HTTP::Tiny> to retry fail responses (a.k.a. responses with
5xx statuses; 4xx are considered the client's fault so we don't retry those).

=for Pod::Coverage ^(patch_data)$

=head1 CONFIGURATION

=head2 -retries

Int, default 3. Maximum number of consecutive retries for a request. 0 will
disable retrying.

=head2 -delay

Int, default 2. Number of seconds to wait between retries.

=head1 FAQ

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Patch-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Patch-Retry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Patch-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny>

L<HTTP::Retry> wraps L<HTTP::Tiny> and offers the same feature, but you have to
use a new interface.

L<HTTP::Tiny::Patch::Cache> which can be combined with this patch to give both
retry and caching ability.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
