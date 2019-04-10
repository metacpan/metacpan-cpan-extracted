package HTTP::Tiny::CustomRetry;

our $DATE = '2019-04-10'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Time::HiRes qw(sleep);

use parent 'HTTP::Tiny';

sub new {
    my ($class, %attrs) = @_;

    my %our_attrs;
    for (keys %attrs) {
        next unless /^retry_/;
        $our_attrs{$_} = delete $attrs{$_};
    }

    my $self = $class->SUPER::new(%attrs);
    $self->{$_} = $our_attrs{$_} for keys %our_attrs;
    $self;
}

sub request {
    my ($self, $method, $url, $options) = @_;

    # initiate retry strategy
    unless ($self->{_retry}) {

        my $strategy = $self->{retry_strategy} //
            $ENV{HTTP_TINY_CUSTOMRETRY_STRATEGY};
        die "Please specify retry_strategy" unless $strategy;
        my $pkg = "Algorithm::Retry::$strategy";
        (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
        require $pkg_pm;

        my %ar_attrs;
        for (keys %ENV) {
            next unless /^HTTP_TINY_CUSTOMRETRY_(.+)/;
            next if $1 eq 'strategy';
            my $name = lc $1;
            $ar_attrs{$name} = $ENV{$_};
        }
        for (keys %$self) {
            if (/^retry_(.+)/) {
                next if $1 eq 'strategy';
                $ar_attrs{$1} = $self->{$_};
            }
        }

        $self->{_retry} = $pkg->new(%ar_attrs);
    }

    my $res;
    while (1) {
        $res = $self->SUPER::request($method, $url, $options);
        if ($res->{status} !~ /\A[5]/) {
            $self->{_retry}->success;
            return $res;
        }
        my $secs = $self->{_retry}->failure;
        if ($secs == -1) {
            log_trace "Failed requesting %s (%s - %s), giving up",
                $url,
                $res->{status},
                $res->{reason};
            return $res;
        }
        log_trace "Failed requesting %s (%s - %s), retrying in %.1f second(s) (attempt #%d) ...",
            $url,
            $res->{status},
            $res->{reason},
            $secs,
            $self->{_retry}{_attempts};
        sleep $secs;
    }
    $res;
}

1;
# ABSTRACT: Retry failed HTTP::Tiny requests

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::CustomRetry - Retry failed HTTP::Tiny requests

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::CustomRetry (from Perl distribution HTTP-Tiny-CustomRetry), released on 2019-04-10.

=head1 SYNOPSIS

 use HTTP::Tiny::CustomRetry;

 my $res  = HTTP::Tiny::CustomRetry->new(
     retry_strategy => 'ExponentialBackoff', # required, pick a strategy (which is name of submodule under Algorithm::Retry::*)

     # the following attributes are available to customize the
     # ExponentialBackoff strategy, which are attributes from
     # Algorithm::Retry::ExponentialBackoff with retry_ prefix.

     # retry_max_attempts     => ...,
     # retry_jitter_factor    => ...,
     # retry_initial_delay    => ...,
     # retry_max_delay        => ...,
     # retry_exponent_base    => ...,
     # retry_delay_on_success => ...,

 )->get("http://www.example.com/");

=head1 DESCRIPTION

This class is a subclass of L<HTTP::Tiny> that retry fail responses (a.k.a.
responses with 5xx statuses; 4xx are considered the client's fault so we don't
retry those).

It's a more elaborate version of L<HTTP::Tiny::Retry> which offers a simple
retry strategy: using a constant delay between attempts. HTTP::Tiny::CustomRetry
uses L<Algorithm::Retry> to offer several retry/backoff strategies.

=head1 ENVIRONMENT

=head2 HTTP_TINY_CUSTOMRETRY_STRATEGY

String. Used to set default for the L</retry_strategy> attribute.

Other C<retry_ATTRNAME> attributes can also be set via environment
HTTP_TINY_CUSTOMRETRY_I<ATTRNAME>, for example C<retry_max_attempts> can be set
via HTTP_TINY_CUSTOMRETRY_MAX_ATTEMPTS.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-CustomRetry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-CustomRetry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-CustomRetry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Algorithm::Retry> and C<Algorithm::Retry::*> strategy modules.

L<HTTP::Tiny>

L<HTTP::Tiny::Retry> and L<HTTP::Tiny::Patch::Retry>, simpler retry strategy
(constant delay).

L<HTTP::Tiny::Patch::CustomRetry>, patch version of this module.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
