package Hash::Iter;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-04'; # DATE
our $DIST = 'Hash-Iter'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(hash_iter pair_iter);

sub hash_iter {
    my $hash = shift;
    my $i = 0;

    my @ary = keys %$hash;
    sub {
        if ($i < @ary) {
            my $key = $ary[$i++];
            return ($key, $hash->{$key});
        } else {
            return ();
        }
    };
}

sub pair_iter {
    hash_iter({@_});
}

1;
# ABSTRACT: Generate a coderef iterator for a hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Iter - Generate a coderef iterator for a hash

=head1 VERSION

This document describes version 0.001 of Hash::Iter (from Perl distribution Hash-Iter), released on 2024-11-04.

=head1 SYNOPSIS

  use Hash::Iter qw(hash_iter pair_iter);

  my $iter = hash_iter({1,2,3,4,5,6});
  while (my ($key,$val) = $iter->()) { ... }

  $iter = pair_iter(1,2,3,4,5,6);
  while (my ($key,$val) = $iter->()) { ... }

=head1 DESCRIPTION

This module provides a simple iterator which is a coderef that you can call
repeatedly to get pairs of a hash/hashref. When the pairs are exhausted, the
coderef will return undef. No class/object involved.

The principle is very simple and you can do it yourself with:

 my $iter = do {
     my $hash = shift;
     my $i = 0;

     my @ary = keys %$hash;
     sub {
         if ($i < @ary) {
             my $key = $ary[$i++];
             return ($key, $hash->{$key});
         } else {
             return undef;
         }
     };
  }

Caveat: if list/array contains an C<undef> element, it cannot be distinguished
with an exhausted iterator.

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 hash_iter($hashref) => coderef

=head2 pair_iter(@pairs) => coderef

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Hash-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Hash-Iter>.

=head1 SEE ALSO

Array iterator modules, particularly L<Array::Iter>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
