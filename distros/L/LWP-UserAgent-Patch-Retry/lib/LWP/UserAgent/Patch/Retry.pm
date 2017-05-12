package LWP::UserAgent::Patch::Retry;

our $DATE = '2015-08-17'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
no warnings;
use Log::Any::IfLOG '$log';

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our %config;

my $p_send_request = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my ($self, $request, $arg, $size) = @_;

    my $retries = 0;
    my $resp;
    while (1) {
        $resp = $orig->(@_);
        if (($config{-criteria} && $config{-criteria}->($self, $resp)) ||
                 !$resp->is_success) {
            $retries++;
            if ($retries > $config{-n}) {
                $log->tracef("Reached retry limit for LWP request (%s %s)",
                             $request->method, $request->uri);
                last;
            } else {
                sleep $config{-delay};
                $log->tracef("Retrying LWP request (%s %s) (#%d)",
                             $request->method, $request->uri, $retries);
                next;
            }
        }
    }
    return $resp;
};

sub patch_data {
    return {
        v => 3,
        config => {
            -n => {
                schema  => 'int*',
                default => 2,
            },
            -delay => {
                schema  => 'int*',
                default => 3,
            },
            -criteria => {
                schema => 'code*',
            },
        },
        patches => [
            {
                action => 'wrap',
                mod_version => qr/^6\.0.+/,
                sub_name => 'send_request',
                code => $p_send_request,
            },
        ],
    };
}

1;
# ABSTRACT: Add retries

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Patch::Retry - Add retries

=head1 VERSION

This document describes version 0.03 of LWP::UserAgent::Patch::Retry (from Perl distribution LWP-UserAgent-Patch-Retry), released on 2015-08-17.

=head1 SYNOPSIS

 use LWP::UserAgent::Patch::Retry -n => 2, -delay => 3;

=head1 DESCRIPTION

This patch adds retries to L<LWP::UserAgent> when response from request is not a
success.

Can be used with L<WWW::Mechanize> because that module uses LWP::UserAgent.

=head1 CONFIGURATION

=head2 -n => INT (default: 2)

Number of retries. Default is 2, which means it will retry twice (so the total
number of requests is 3).

=head2 -delay => INT (default: 3)

Delay between retries, in seconds.

=head2 -criteria => CODE

Specify custom criteria of whether to retry. Will be passed C<< ($self,
$response) >> and should return 1 if retry should be performed. For example if
you do not want to retry on 404 errors:

 use LWP::UserAgent::Patch::Retry
     -criteria => sub {
         my ($self, $resp) = @_;
         return 1 if !$resp->is_success && $resp->code != 404;
     };

=head1 FAQ

=head2 Why not subclass?

By patching, you do not need to replace all the client code which uses
LWP::UserAgent (or WWW::Mechanize, and so on).

=head1 SEE ALSO

L<LWP::UserAgent::Determined>, L<LWP::UserAgent::ExponentialBackoff>

Retry in general: L<Retry>, L<Sub::Retry>, L<Perinci::Sub::Property::retry>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Patch-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-LWP-UserAgent-Patch-Retry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Patch-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
