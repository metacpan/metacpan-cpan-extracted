package HashData::Array;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-21'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;
with 'HashDataRole::Source::Array';

1;
# ABSTRACT: Get hash data from Perl array

__END__

=pod

=encoding UTF-8

=head1 NAME

HashData::Array - Get hash data from Perl array

=head1 VERSION

This document describes version 0.001 of HashData::Array (from Perl distribution HashDataRoles-Standard), released on 2021-05-21.

=head1 SYNOPSIS

 use HashData::Array;

 my $ary = HashData::Array->new(
     array => [["one","satu"], ["two","dua"], ["three","tiga"]],
 );

=head1 DESCRIPTION

This is an C<HashData::> module to get hash items from a Perl array. Each array
element must in turn be a two-element array C<< [$key, $value] >>. See
L<HashDataRole::Source::Array> for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-HashDataRoles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<HashData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
