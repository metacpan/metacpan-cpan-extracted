package HTTP::Tiny::Plugin::NewestFirefox;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-08'; # DATE
our $DIST = 'HTTP-Tiny-Plugin-NewestFirefox'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

sub after_instantiate {
    require HTTP::UserAgentStr::Util::ByNickname;

    my ($class, $r) = @_;
    $r->{http}{agent} = HTTP::UserAgentStr::Util::ByNickname::newest_firefox();
    1;
}

1;
# ABSTRACT: Set User-Agent to newest Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Plugin::NewestFirefox - Set User-Agent to newest Firefox

=head1 VERSION

This document describes version 0.001 of HTTP::Tiny::Plugin::NewestFirefox (from Perl distribution HTTP-Tiny-Plugin-NewestFirefox), released on 2021-06-08.

=head1 SYNOPSIS

 use HTTP::Tiny::Plugin 'NewestFirefox';

 my $http = HTTP::Tiny::Plugin->new; # agent is preset to newest Firefox

=head1 DESCRIPTION

=for Pod::Coverage .+

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Plugin-NewestFirefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Plugin-NewestFirefox>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Plugin-NewestFirefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::UserAgentStr::Util::ByNickname>

L<HTTP::Tiny::NewestFirefox>, a non-plugin version.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
