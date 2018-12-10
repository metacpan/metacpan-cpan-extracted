package HTTP::Tiny::Retry;

our $DATE = '2018-12-09'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use parent 'HTTP::Tiny';

sub request {
    my ($self, $method, $url, $options) = @_;

    my $config_retries = $self->{retries} // $ENV{HTTP_TINY_RETRIES} // 3;
    my $config_retry_delay = $self->{retry_delay} // $ENV{HTTP_TINY_RETRY_DELAY} // 2;

    my $retries = 0;
    my $res;
    while (1) {
        my $res = $self->SUPER::request($method, $url, $options);
        return $res if $res->{status} !~ /\A[5]/;
        last if $retries >= $config_retries;
        $retries++;
        log_trace "Failed requesting $url ($res->{status} - $res->{reason}), retrying" .
            ($config_retry_delay ? " in $config_retry_delay second(s)" : "") .
            " ($retries of $config_retries) ...";
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

This document describes version 0.001 of HTTP::Tiny::Retry (from Perl distribution HTTP-Tiny-Retry), released on 2018-12-09.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
