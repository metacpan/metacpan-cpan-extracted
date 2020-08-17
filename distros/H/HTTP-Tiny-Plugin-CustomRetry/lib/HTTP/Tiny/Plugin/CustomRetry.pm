package HTTP::Tiny::Plugin::CustomRetry;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-15'; # DATE
our $DIST = 'HTTP-Tiny-Plugin-CustomRetry'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Time::HiRes qw(sleep);

sub after_request {
    my ($self, $r) = @_;

    $r->{config}{retry_if} //= qr/^5/;
    $r->{config}{strategy} or die "Please set configuration: 'stategy'";

    $r->{_backoff} //= do {
        my $pkg = "Algorithm::Backoff::$r->{config}{strategy}";
        (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
        require $pkg_pm;
        $pkg->new(%{$r->{config}{strategy_options} // {}});
    };

    my ($http, $method, $url, $options) = @{ $r->{argv} };

    my $fail;
    if (ref $r->{config}{retry_if} eq 'Regexp') {
        $fail = $r->{response}{status} =~ $r->{config}{retry_if};
    } else {
        $fail = $r->{config}{retry_if}->($self, $r->{response});
    }
    if ($fail) {
        my $secs = $r->{_backoff}->failure;
        if ($secs == -1) {
            log_trace "Failed requesting %s (%s - %s), giving up",
                $url,
                $r->{response}{status},
                $r->{response}{reason};
            return 0;
        }
        log_trace "Failed requesting %s (%s - %s), retrying in %.1f second(s) (attempt #%d) ...",
            $url,
            $r->{response}{status},
            $r->{response}{reason},
            $secs,
            $r->{_backoff}{_attempts}+1;
        sleep $secs;
        return 98; # repeat request()
    } else {
        $r->{_backoff}->success;
    }
    1; # ok
}

1;
# ABSTRACT: (DEPRECATED) Retry failed request

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Plugin::CustomRetry - (DEPRECATED) Retry failed request

=head1 VERSION

This document describes version 0.003 of HTTP::Tiny::Plugin::CustomRetry (from Perl distribution HTTP-Tiny-Plugin-CustomRetry), released on 2020-08-15.

=head1 SYNOPSIS

 use HTTP::Tiny::Plugin 'CustomRetry' => {
     strategy         => 'Exponential',
     strategy_options => {initial_delay=>2, max_delay=>100},
     retry_if         => qr/^[45]/, # optional, default is only 5xx errors are retried
 };

 my $res  = HTTP::Tiny::Plugin->new->get("http://www.example.com/");

=head1 DESCRIPTION

B<DEPRECATION NOTICE:> This plugin is now deprecated, in favor of
L<HTTP::Tiny::Plugin::Retry> which now supports L<Algorithm::Backoff> too.

This plugin retries failed response using one of available backoff strategy in
C<Algorithm::Backoff::*> (e.g. L<Algorithm::Backoff::Exponential>).

By default only retries 5xx failures, as 4xx are considered to be client's fault
(but you can configure it with L</retry_if>).

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 strategy

Str. Name of backoff strategy, which corresponds to
Algorithm::Backoff::<strategy>.

=head2 strategy_options

Hashref. Will be passed to Algorithm::Backoff::* constructor.

=head2 retry_if

Regex or code. If regex, then will be matched against response status. If code,
will be called with arguments: C<< ($self, $response) >>.

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Plugin-CustomRetry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Plugin-CustomRetry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Plugin-CustomRetry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Plugin>

L<HTTP::Tiny::Plugin::Retry>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
