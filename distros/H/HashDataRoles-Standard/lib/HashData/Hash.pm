package HashData::Hash;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-21'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;
with 'HashDataRole::Source::Hash';

1;
# ABSTRACT: Get hash data from Perl hash

__END__

=pod

=encoding UTF-8

=head1 NAME

HashData::Hash - Get hash data from Perl hash

=head1 VERSION

This document describes version 0.001 of HashData::Hash (from Perl distribution HashDataRoles-Standard), released on 2021-05-21.

=head1 SYNOPSIS

 use HashData::Hash;

 my $hd = HashData::Hash->new(
     hash => {one=>"satu", two=>"dua", three=>"tiga"},
 );

=head1 DESCRIPTION

This is an C<HashData::> module to get hash items from a Perl hash. See
L<HashDataRole::Source::Hash> for more details.

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
