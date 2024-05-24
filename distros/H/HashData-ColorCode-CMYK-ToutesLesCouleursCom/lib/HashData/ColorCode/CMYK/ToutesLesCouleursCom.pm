package HashData::ColorCode::CMYK::ToutesLesCouleursCom;

use strict;
use Role::Tiny::With;
with 'HashDataRole::Source::LinesInDATA';
#with 'Role::TinyCommons::Collection::FindItem::Iterator';         # add find_item() (has_item already added above)
#with 'Role::TinyCommons::Collection::PickItems::RandomSeekLines'; # add pick_items() that uses binary search

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-10'; # DATE
our $DIST = 'HashData-ColorCode-CMYK-ToutesLesCouleursCom'; # DIST
our $VERSION = '0.002'; # VERSION

# STATS

1;
# ABSTRACT: CMYK color names (from ToutesLesCouleursCom)

=pod

=encoding UTF-8

=head1 NAME

HashData::ColorCode::CMYK::ToutesLesCouleursCom - CMYK color names (from ToutesLesCouleursCom)

=head1 VERSION

This document describes version 0.002 of HashData::ColorCode::CMYK::ToutesLesCouleursCom (from Perl distribution HashData-ColorCode-CMYK-ToutesLesCouleursCom), released on 2024-05-10.

=head1 DESCRIPTION

CMKY value are in this format: I<C>,I<M>,I<Y>,I<K>. Where each C/M/Y/K value is
an integer from 0 to 100.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashData-ColorCode-CMYK-ToutesLesCouleursCom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashData-Color-CMYK-ToutesLesCouleursCom>.

=head1 SEE ALSO

Source: L<https://www.toutes-les-couleurs.com/en/CMYK-color-code.php>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashData-ColorCode-CMYK-ToutesLesCouleursCom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__