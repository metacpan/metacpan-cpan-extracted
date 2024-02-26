package Graphics::ColorNames::FoodColor;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-05'; # DATE
our $DIST = 'Graphics-ColorNames-FoodColor'; # DIST
our $VERSION = '0.002'; # VERSION

sub NamesRgbTable() {
    use integer;
    return {
        allura_red => 0xff0000,
        ci_16035 => 0xff0000,
        fdc_red_40 => 0xff0000,
        ci_food_red_17 => 0xff0000,
        e129 => 0xff0000,

        amaranth => 0x993366,
        ci_16185 => 0x993366,
        fdc_red_2 => 0x993366,
        ci_food_red_9 => 0x993366,
        e123 => 0x993366,

        black_pn => 0x660033,
        ci_food_black_1 => 0x660033,
        ci_28440 => 0x660033,
        e151 => 0x660033,

        brilliant_blue_fcf => 0x0000ff,
        ci_42090 => 0x0000ff,
        fdc_blue_1 => 0x0000ff,
        ci_food_blue_2 => 0x0000ff,
        e133 => 0x0000ff,

        carmoisine => 0xcc3300,
        ci_14720 => 0xcc3300,
        ci_food_red_3 => 0xcc3300,
        azorubine => 0xcc3300,
        e122 => 0xcc3300,

        chocolate_brown_ht => 0x996600,
        ci_20285 => 0x996600,
        ci_food_brown_3 => 0x996600,
        e155 => 0x996600,

        erythrosine => 0xff0080,
        ci_45430 => 0xff0080,
        fdc_red_3 => 0xff0080,
        ci_food_red_14 => 0xff0080,
        e127 => 0xff0080,

        fast_green_fcf => 0x99ff33,
        ci_42053 => 0x99ff33,
        fdc_green_3 => 0x99ff33,
        ci_food_green_3 => 0x99ff33,

        fast_red_e => 0xcc3300,
        ci_16045 => 0xcc3300,
        ci_food_red_4 => 0xcc3300,

        green_s => 0x008000,
        ci_44090 => 0x008000,
        ci_food_green_4 => 0x008000,
        e142 => 0x008000,

        indigo_carmine => 0x666699,
        ci_73015 => 0x666699,
        fdc_blue_2 => 0x666699,
        ci_food_blue_1 => 0x666699,
        e132 => 0x666699,

        patent_blue_v => 0x9999ff,
        ci_42051 => 0x9999ff,
        ci_food_blue_5 => 0x9999ff,
        e131 => 0x9999ff,

        ponceau_4r => 0xff0000,
        ci_16255 => 0xff0000,
        ci_food_red_7 => 0xff0000,
        e124 => 0xff0000,

        quinoline_yellow => 0xffff00,
        ci_47005 => 0xffff00,
        dc_yellow_10 => 0xffff00,
        ci_food_yellow_13 => 0xffff00,
        e104 => 0xffff00,

        red_2g => 0xff3300,
        ci_18050 => 0xff3300,
        ci_food_red_10 => 0xff3300,
        e128 => 0xff3300,

        sunset_yellow_fcf => 0xf7fe6d,
        ci_15985 => 0xf7fe6d,
        fdc_yellow_6 => 0xf7fe6d,
        ci_food_yellow_3 => 0xf7fe6d,
        e110 => 0xf7fe6d,

        tartrazine => 0xffcc66,
        ci_19140 => 0xffcc66,
        fdc_yellow_5 => 0xffcc66,
        ci_food_yellow_4 => 0xffcc66,
        e102 => 0xffcc66,
    };
}

1;
# ABSTRACT: Food colors

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNames::FoodColor - Food colors

=head1 VERSION

This document describes version 0.002 of Graphics::ColorNames::FoodColor (from Perl distribution Graphics-ColorNames-FoodColor), released on 2023-12-05.

=head1 SYNOPSIS

  require Graphics::ColorNames::FoodColor;

  $NameTable = Graphics::ColorNames::FoodColor->NamesRgbTable();
  $allura_red  = $NameTable->{"allura_red"};

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Graphics-ColorNames-FoodColor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Graphics-ColorNames-FoodColor>.

=head1 SEE ALSO

Source: L<http://www.standardcon.com/foodcolours.htm>

L<Graphics::ColorNames>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNames-FoodColor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
