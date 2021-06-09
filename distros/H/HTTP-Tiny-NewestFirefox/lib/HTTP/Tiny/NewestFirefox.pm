package HTTP::Tiny::NewestFirefox;

our $DATE = '2021-06-08'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use HTTP::UserAgentStr::Util::ByNickname qw(newest_firefox);
use HTTP::Tiny::Patch::SetUserAgent (-agent => newest_firefox());

use parent 'HTTP::Tiny';

1;
# ABSTRACT: HTTP::Tiny + set User-Agent to newest Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::NewestFirefox - HTTP::Tiny + set User-Agent to newest Firefox

=head1 VERSION

This document describes version 0.002 of HTTP::Tiny::NewestFirefox (from Perl distribution HTTP-Tiny-NewestFirefox), released on 2021-06-08.

=head1 SYNOPSIS

 use HTTP::Tiny::NewestFirefox;

 my $res  = HTTP::Tiny->new->get("http://www.example.com/");

=head1 DESCRIPTION

A convenient bundling of L<HTTP::Tiny>, L<HTTP::Tiny::Patch::SetUserAgent>, and
L<HTTP::UserAgentStr::Util::ByNickname>.

=head1 TODO

Avoid changing User-Agent globally.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-NewestFirefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-NewestFirefox>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-NewestFirefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Plugin::NewestFirefox>, plugin version.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
