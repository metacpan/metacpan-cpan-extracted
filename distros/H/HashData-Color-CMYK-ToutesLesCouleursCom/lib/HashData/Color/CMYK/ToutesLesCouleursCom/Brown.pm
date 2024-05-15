package HashData::Color::CMYK::ToutesLesCouleursCom::Brown;

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
# ABSTRACT: Brown CMYK color names (from ToutesLesCouleursCom)

=pod

=encoding UTF-8

=head1 NAME

HashData::Color::CMYK::ToutesLesCouleursCom::Brown - Brown CMYK color names (from ToutesLesCouleursCom)

=head1 VERSION

This document describes version 0.001 of HashData::Color::CMYK::ToutesLesCouleursCom::Brown (from Perl distribution HashData-Color-CMYK-ToutesLesCouleursCom), released on 2024-05-06.

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
brown:0,34,81,64
mahogany:0,51,79,47
chestnut:0,38,77,35
amber:0,19,100,6
auburn:0,61,92,38
suntan:0,22,53,45
beige:0,14,37,22
light beige:0,0,10,40
beigeasse:0,5,30,31
bistre:0,30,49,76
bistre:0,18,42,48
bitumen:0,22,49,69
blet:0,34,81,64
brick:0,65,80,48
bronze:0,20,73,62
walnut brou:0,46,94,75
office:0,19,54,58
cocoa:0,23,40,62
cachou:0,43,74,82
café:0,34,99,73
latte:0,22,61,53
cannelle:0,30,58,51
caramel:0,60,100,51
chestnut:0,15,30,50
light:0,22,53,45
cauldron:0,38,89,48
chocolate:0,36,62,65
pumpkin:0,45,80,13
fauve:0,54,95,32
sheet-dead:0,47,72,40
grège:0,7,19,27
moorish grey:0,10,36,59
lavallière:0,38,76,44
brown:0,53,100,65
mordoré:0,34,81,47
hazel:0,42,73,42
burnt orange:0,58,100,20
chip:0,72,88,69
red bismarck:0,77,94,35
red tomette:0,57,70,32
rust:0,43,85,40
beef blood:0,93,100,55
senois:0,55,74,45
sepia:0,17,29,34
sepia:0,21,43,32
tobacco:0,47,81,38
sienna:0,41,63,44
umber:0,7,27,62
umber:0,25,73,43
vanilla:0,8,32,12
