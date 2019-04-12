package HTTP::Tiny::Cache_CustomRetry;

our $DATE = '2019-04-12'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use HTTP::Tiny::Cache ();
use HTTP::Tiny::CustomRetry ();

our @ISA = qw(HTTP::Tiny::CustomRetry);
@HTTP::Tiny::CustomRetry::ISA = qw(HTTP::Tiny::Cache);

1;
# ABSTRACT: Cache response + retry failed request

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Cache_CustomRetry - Cache response + retry failed request

=head1 VERSION

This document describes version 0.003 of HTTP::Tiny::Cache_CustomRetry (from Perl distribution HTTP-Tiny-Cache_CustomRetry), released on 2019-04-12.

=head1 SYNOPSIS

 use HTTP::Tiny::Cache_CustomRetry;

=head1 DESCRIPTION

EXPERIMENTAL / PROOF-OF-CONCEPT ONLY.

This class combines the functionalities of L<HTTP::Tiny::Cache> (HT:Cache) and
L<HTTP::Tiny::CustomRetry> (HT:CustomRetry). Since both HT:Cache and
HT:CustomRetry both extend L<HTTP::Tiny> (HT), this module modifies
HT:CustomRetry's C<@ISA> to point to HT:Retry instead. This is a hack and
probably only serves to show the limitation of subclassing mechanism for adding
functionalities, like we see in the L<WWW::Mechanize> land. For an alternative
solution, see L<HTTP::Tiny::Plugin> which is a plugin-enabled variant of
HTTP::Tiny.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-Tiny-Cache_CustomRetry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-Tiny-Cache_CustomRetry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Tiny-Cache_CustomRetry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HTTP::Tiny::Cache>, L<HTTP::Tiny::CustomRetry>

L<HTTP::Tiny::Plugin>

L<HTTP::Tiny>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
