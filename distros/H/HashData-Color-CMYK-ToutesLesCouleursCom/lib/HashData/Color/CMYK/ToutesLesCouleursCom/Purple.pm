package HashData::Color::CMYK::ToutesLesCouleursCom::Purple;

use strict;
use Role::Tiny::With;
with 'HashDataRole::Source::LinesInDATA';
#with 'Role::TinyCommons::Collection::FindItem::Iterator';         # add find_item() (has_item already added above)
#with 'Role::TinyCommons::Collection::PickItems::RandomSeekLines'; # add pick_items() that uses binary search

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'HashData-Color-CMYK-ToutesLesCouleursCom'; # DIST
our $VERSION = '0.001'; # VERSION

# STATS

1;
# ABSTRACT: Purple CMYK color names (from ToutesLesCouleursCom)

=pod

=encoding UTF-8

=head1 NAME

HashData::Color::CMYK::ToutesLesCouleursCom::Purple - Purple CMYK color names (from ToutesLesCouleursCom)

=head1 VERSION

This document describes version 0.001 of HashData::Color::CMYK::ToutesLesCouleursCom::Purple (from Perl distribution HashData-Color-CMYK-ToutesLesCouleursCom), released on 2024-05-06.

=head1 DESCRIPTION

CMKY value are in this format: I<C>,I<M>,I<Y>,I<K>. Where each C/M/Y/K value is
an integer from 0 to 100.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashData-Color-CMYK-ToutesLesCouleursCom>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashData-Color-CMYK-ToutesLesCouleursCom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
purple:33,100,0,40
amethyst:19,54,0,35
aubergine:0,100,27,78
persian blue:60,100,0,0
byzantine:0,73,13,26
byzantium:0,63,12,56
cherry:0,78,55,13
colombin:0,35,12,58
fuchsia:0,75,42,1
glycine:9,27,0,14
flax grey:11,14,0,7
heliotrope:13,55,0,0
indigo:51,89,0,3
indigo:57,100,0,58
indigo web:42,100,0,49
lavender:36,44,0,7
wine lie:0,83,60,33
lilas:13,51,0,18
magenta:0,100,0,0
dark magenta:0,100,0,50
magenta fuchsia:0,100,47,14
purple:0,46,0,17
orchid:0,49,2,15
parma:11,31,0,9
purple:0,91,59,38
prune:0,84,36,49
candy pink:0,74,37,2
hot pink:0,100,50,0
red-violet:0,89,33,22
bishop violet:0,46,12,55
violine:0,96,18,37
zizolin:9,98,0,53
