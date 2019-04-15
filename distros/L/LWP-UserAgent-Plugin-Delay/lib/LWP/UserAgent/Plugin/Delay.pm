package LWP::UserAgent::Plugin::Delay;

our $DATE = '2019-04-15'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

sub after_request {
    my ($self, $r) = @_;

    my $secs = $r->{config}{between_request} // 1;
    log_trace "Sleeping %.1f second(s) between LWP::UserAgent request ...", $secs;
    sleep $secs;
    1;
}

1;
# ABSTRACT: Delay/sleep between requests

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Plugin::Delay - Delay/sleep between requests

=head1 VERSION

This document describes version 0.001 of LWP::UserAgent::Plugin::Delay (from Perl distribution LWP-UserAgent-Plugin-Delay), released on 2019-04-15.

=head1 SYNOPSIS

 use LWP::UserAgent::Plugin 'Delay' => {
     between_request => 3, # optional, default 1
 };

 my $ua = LWP::UserAgent::Plugin->new;
 $ua->get("http://www.example.com/");
 $ua->get("http://www.example.com/"); # will sleep 3 seconds first

=head1 DESCRIPTION

This plugin inserts C<sleep()> between requests.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 between_requests

Ufloat. Default: 1.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-UserAgent-Plugin-Delay>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-LWP-UserAgent-Plugin-Delay>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent-Plugin-Delay>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Plugin::Delay>

L<LWP::UserAgent::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
