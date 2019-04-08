package HTTP::Tiny::Patch::Delay;

our $DATE = '2019-04-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Module::Patch qw();
use base qw(Module::Patch);

use Time::HiRes qw(sleep);

our %config;

my $seen;
my $p_request = sub {
    my $ctx = shift;
    my $orig = $ctx->{orig};

    if ($seen++) {
        my $secs = $config{-between_request} // 1;
        log_trace "Sleeping %.1f second(s) between LWP::UserAgent request ...",
            $secs;
        sleep $secs;
    }
    $ctx->{orig}->(@_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            -between_request => {
                schema  => 'nonnegnum*',
                default => 1,
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
# ABSTRACT: Add sleep() between requests to slow down

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Patch::Delay - Add sleep() between requests to slow down

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::Patch::Delay (from Perl distribution HTTP-Tiny-Patch-Delay), released on 2019-04-07.

=head1 SYNOPSIS

From Perl:

 use HTTP::Tiny::Patch::Delay
     # -between_requests => 1.5, # optional, default is 1
 ;

 my $res  = HTTP::Tiny->new->get("http://www.example.com/");

=head1 DESCRIPTION

This patch adds sleep() between L<HTTP::Tiny> requests.

=for Pod::Coverage ^(patch_data)$

=head1 CONFIGURATION

=head2 -between_request

Float. Default is 1. Number of seconds to sleep() after each request. Uses
L<Time::HiRes> so you can include fractions of a second, e.g. 0.1 or 1.5.

=head1 FAQ

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Patch-Delay>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Patch-Delay>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Patch-Delay>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<LWP::UserAgent::Patch::Delay>

L<HTTP::Tiny>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
