package HashData::ColorCode::CMYK::ToutesLesCouleursCom::Red;

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
# ABSTRACT: Red CMYK color names (from ToutesLesCouleursCom)

=pod

=encoding UTF-8

=head1 NAME

HashData::ColorCode::CMYK::ToutesLesCouleursCom::Red - Red CMYK color names (from ToutesLesCouleursCom)

=head1 VERSION

This document describes version 0.002 of HashData::ColorCode::CMYK::ToutesLesCouleursCom::Red (from Perl distribution HashData-ColorCode-CMYK-ToutesLesCouleursCom), released on 2024-05-10.

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
red:0,100,100,0
amarante:0,72,59,43
bordeaux:0,94,76,57
brick:0,65,80,48
cherry:0,94,94,27
reef:0,73,100,9
scarlet:0,100,100,7
strawberry:0,75,75,25
strawberry crushed:0,78,78,36
raspberry:0,78,64,22
fuchsia:0,75,42,1
grenadine:0,76,73,9
garnet:0,90,82,57
watermelon:0,41,37,0
crimson:0,56,51,0
magenta:0,100,0,0
dark magenta:0,100,0,50
magenta fuchsia:0,100,47,14
purple:0,46,0,17
nacarat:0,63,63,1
red ochre:0,31,58,13
pass velvet:0,72,59,43
purple:0,91,59,38
prune:0,84,36,49
hot pink:0,100,50,0
alizarin red:0,96,100,22
english red:0,86,95,3
red bismarck:0,77,94,35
red burgundy:0,88,88,58
red nasturtium:0,63,70,0
cardinal red:0,83,91,28
carmine red:0,100,84,41
red cinnabar:0,89,99,14
red cinnabar:0,72,85,1
red poppy:0,96,100,22
crimson:0,100,84,41
crimson:0,91,73,14
red adrianople:0,90,99,34
red aniline:0,100,100,8
red gong:0,81,81,50
march rouge:0,86,95,3
red crayfish:0,83,99,26
red fire:0,89,100,0
red fire:0,71,100,0
red madder:0,93,93,7
red currant:0,95,86,19
red culvert:0,96,100,22
ruby red:0,92,58,12
red blood:0,95,95,48
red tomato:0,82,90,13
red tomette:0,57,70,32
turkish red:0,90,99,34
red vermilion:0,89,99,14
red vermilion:0,72,85,1
red-violet:0,89,33,22
rust:0,43,85,40
beef blood:0,93,100,55
senois:0,55,74,45
terracotta:0,62,55,20
vermeil:0,96,87,13
zizolin:9,98,0,53
