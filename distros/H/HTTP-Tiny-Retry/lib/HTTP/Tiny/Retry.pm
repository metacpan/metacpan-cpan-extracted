package HTTP::Tiny::Retry;

our $DATE = '2019-04-10'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Time::HiRes qw(sleep);

use parent 'HTTP::Tiny';

sub new {
    my ($class, %attrs) = @_;

    my %our_attrs;
    for ("retries", "retry_delay") {
        $our_attrs{$_} = delete $attrs{$_}
            if exists $attrs{$_};
    }

    my $self = $class->SUPER::new(%attrs);
    $self->{$_} = $our_attrs{$_} for keys %our_attrs;
    $self;
}

sub request {
    my ($self, $method, $url, $options) = @_;

    $self->{retries} //= $ENV{HTTP_TINY_RETRIES} // 3;
    $self->{retry_delay} //= $ENV{HTTP_TINY_RETRY_DELAY} // 2;

    my $retries = 0;
    my $res;
    while (1) {
        $res = $self->SUPER::request($method, $url, $options);
        return $res if $res->{status} !~ /\A[5]/;
        last if $retries >= $self->{retries};
        $retries++;
        log_trace "Failed requesting %s (%s - %s), retrying in %.1f second(s) (%d of %d) ...",
            $url,
            $res->{status},
            $res->{reason},
            $self->{retry_delay},
            $retries,
            $self->{retries};
        sleep $self->{retry_delay};
    }
    $res;
}

1;
# ABSTRACT: Retry failed HTTP::Tiny requests

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Retry - Retry failed HTTP::Tiny requests

=head1 VERSION

This document describes version 0.004 of HTTP::Tiny::Retry (from Perl distribution HTTP-Tiny-Retry), released on 2019-04-10.

=head1 SYNOPSIS

 use HTTP::Tiny::Retry;

 my $res  = HTTP::Tiny::Retry->new(
     # retries     => 4, # optional, default 3
     # retry_delay => 5, # optional, default is 2
     # ...
 )->get("http://www.example.com/");

=head1 DESCRIPTION

This class is a subclass of L<HTTP::Tiny> that retry fail responses (a.k.a.
responses with 5xx statuses; 4xx are considered the client's fault so we don't
retry those).

=head1 ENVIRONMENT

=head2 HTTP_TINY_RETRIES

Int. Used to set default for the L</retries> attribute.

=head2 HTTP_TINY_RETRY_DELAY

Int. Used to set default for the L</retry_delay> attribute.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Retry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny>

L<HTTP::Tiny::Patch::Retry>, patch version of this module.

L<HTTP::Tiny::CustomRetry> and L<HTTP::Tiny::Patch::CustomRetry> for
customizable retry/backoff strategies.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
