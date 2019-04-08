package LWP::UserAgent::Patch::Delay;

our $DATE = '2019-04-07'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
no warnings;
use Log::ger;

use Module::Patch ();
use base qw(Module::Patch);

use Time::HiRes qw(sleep);

our %config;

my $seen;
my $p_send_request = sub {
    my $ctx  = shift;
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
                action => 'wrap',
                mod_version => qr/^6\./,
                sub_name => 'send_request',
                code => $p_send_request,
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

LWP::UserAgent::Patch::Delay - Add sleep() between requests to slow down

=head1 VERSION

This document describes version 0.003 of LWP::UserAgent::Patch::Delay (from Perl distribution LWP-UserAgent-Patch-Delay), released on 2019-04-07.

=head1 SYNOPSIS

 use LWP::UserAgent::Patch::Delay;

=head1 DESCRIPTION

This patch adds sleep() between L<LWP::UserAgent>'s requests.

=head1 CONFIGURATION

=head2 -between_request

Float. Default is 1. Number of seconds to sleep() after each request. Uses
L<Time::HiRes> so you can include fractions of a second, e.g. 0.1 or 1.5.

=head1 FAQ

=head2 Why not subclass?

By patching, you do not need to replace all the client code which uses
L<LWP::UserAgent> (or WWW::Mechanize, and so on).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Patch-Delay>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-Patch-Delay>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Patch-Delay>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
