package HTTP::Tiny::Plugin::Retry;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-14'; # DATE
our $DIST = 'HTTP-Tiny-Plugin-Retry'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Time::HiRes qw(sleep);

sub after_request {
    my ($class, $r) = @_;

    $r->{config}{max_attempts} //=
        $ENV{HTTP_TINY_PLUGIN_RETRY_MAX_ATTEMPTS} // 4;
    $r->{config}{delay}        //=
        $ENV{HTTP_TINY_PLUGIN_RETRY_DELAY}        // 2;
    if (defined $r->{config}{strategy}) {
        require Module::Load::Util;
        $r->{http}{_backoff_obj} //=
            Module::Load::Util::instantiate_class_with_optional_args(
                {ns_prefix => 'Algorithm::Backoff'}, $r->{config}{strategy});
    }

    my $is_success;
    if (defined $r->{config}{retry_if}) {
        my $ref = ref $r->{config}{retry_if};
        if ($ref eq 'Regexp' or !$ref) {
            $is_success++ unless $r->{response}{status} =~ $r->{config}{retry_if};
        } elsif ($ref eq 'ARRAY') {
            $is_success++ unless grep { $_ == $r->{response}{status} } @{ $r->{config}{retry_if} };
        } elsif ($ref eq 'CODE') {
            $is_success++ unless $r->{config}{retry_if}->($class, $r);
        } else {
            die "Please supply a scalar/Regexp/arrayref/coderef retry_if";
        }
    } else {
        $is_success++ if $r->{response}{status} !~ /\A[5]/;
    }

  SUCCESS: {
        last unless $is_success;
        if ($r->{http}{_backoff_obj}) {
            my $delay_on_success = $r->{http}{_backoff_obj}->success;
            if ($delay_on_success > 0) {
                log_trace "Delaying for %.1f second(s) after successful request", $delay_on_success;
                sleep $delay_on_success;
            }
        }
        return -1;
    }

    # FAILURE

    $r->{retries} //= 0;
    my $max_attempts;
    my $delay;
    my $should_give_up;
    if ($r->{http}{_backoff_obj}) {
        $delay = $r->{http}{_backoff_obj}->failure;
        $should_give_up++ if $delay < 0;
        $max_attempts = $r->{http}{_backoff_obj}{max_attempts};
    } else {
        $should_give_up++ if $r->{config}{max_attempts} &&
            1+$r->{retries} >= $r->{config}{max_attempts};
        $max_attempts = $r->{config}{max_attempts};
        $delay = $r->{config}{delay};
    }

    my ($http, $method, $url, $options) = @{ $r->{argv} };

  GIVE_UP: {
        last unless $should_give_up;
        log_trace "Failed requesting %s %s (%s - %s), giving up",
        $method,
        $url,
        $r->{response}{status},
        $r->{response}{reason};
        return 0;
    }

    $r->{retries}++;

    log_trace "Failed requesting %s %s (%s - %s), retrying in %.1f second(s) (attempt %d of %d) ...",
        $method,
        $url,
        $r->{response}{status},
        $r->{response}{reason},
        $delay,
        1+$r->{retries},
        $max_attempts;
    sleep $delay;
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

This document describes version 0.004 of HTTP::Tiny::Plugin::Retry (from Perl distribution HTTP-Tiny-Plugin-Retry), released on 2020-08-14.

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

Int. Default 4.

=head2 delay

Float.

=head2 retry_if

Regex (or scalra), or arrayref, or coderef. If regex or scalar, then will be
matched against response status. If array, then will be assumed to be status
codes to trigger retry. If coderef, will be called with arguments: C<< ($class,
$response) >> (C<$class> is the plugin class name) and a true return value will
trigger retry.

=head2 strategy

L<Algorithm::Backoff>::* module name, without the prefix and with optional
arguments (see L<Module::Load::Util/instantiate_class_with_optional_args>), e.g.
C<"Constant">, C<< ["Exponential" => {initial_delay=>2, max_delay=>100}] >>,
C<"Exponential=initial_delay,2,max_delay,100">.

If set, will use delay and maximum attempt values from specified
Algorithm::Backoff backoff strategry instead of C<max_attempts> and C<delay>.

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

Equivalent plugin for L<LWP::UserAgent::Plugin>:
L<LWP::UserAgent::Plugin::Retry>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
