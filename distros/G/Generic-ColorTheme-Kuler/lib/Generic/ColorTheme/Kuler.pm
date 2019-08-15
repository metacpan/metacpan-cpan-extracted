package Generic::ColorTheme::Kuler;

our $DATE = '2018-02-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %color_themes = (
    sandy_stone_beach_ocean_diver => {
        colors => {
            color1 => 'E6E2AF',
            color2 => 'A7A37E',
            color3 => 'EFECCA',
            color4 => '046380',
            color5 => '002F2F',
        },
    },
    firenze => {
        colors => {
            color1 => '468966',
            color2 => 'FFF0A5',
            color3 => 'FFB03B',
            color4 => 'B64926',
            color5 => '8E2800',
        },
    },
    natural_blue => {
        colors => {
            color1 => 'FCFFF5',
            color2 => 'D1DBBD',
            color3 => '91AA9D',
            color4 => '3E606F',
            color5 => '193441',
        },
    },
    vitamin_c => {
        colors => {
            color1 => '004358',
            color2 => '1F8A70',
            color3 => 'BEDB39',
            color4 => 'FFE11A',
            color5 => 'FD7400',
        },
    },
    aspirin_c => {
        colors => {
            color1 => '225378',
            color2 => '1695A3',
            color3 => 'ACF0F2',
            color4 => 'F3FFE2',
            color5 => 'EB7F00',
        },
    },
    sea_wolf => {
        colors => {
            color1 => 'DC3522',
            color2 => 'D9CB9E',
            color3 => '374140',
            color4 => '2A2C2B',
            color5 => '1E1E20',
        },
    },
    unlike => {
        colors => {
            color1 => '88A825',
            color2 => '35203B',
            color3 => '911146',
            color4 => 'CF4A30',
            color5 => 'ED8C2B',
        },
    },
    granny_smith_apple => {
        colors => {
            color1 => '85DB18',
            color2 => 'CDE855',
            color3 => 'F5F6D4',
            color4 => 'A7C520',
            color5 => '493F0B',
        },
    },
    red_hot => {
        colors => {
            color1 => '450003',
            color2 => '5C0002',
            color3 => '94090D',
            color4 => 'D40D12',
            color5 => 'FF1D23',
        },
    },
    pink_peppermint => {
        colors => {
            color1 => 'F6B1C3',
            color2 => 'F0788C',
            color3 => 'DE264C',
            color4 => 'BC0D35',
            color5 => 'A20D1E',
        },
    },
);

1;
# ABSTRACT: Color themes from Adobe Kuler

__END__

=pod

=encoding UTF-8

=head1 NAME

Generic::ColorTheme::Kuler - Color themes from Adobe Kuler

=head1 VERSION

This document describes version 0.002 of Generic::ColorTheme::Kuler (from Perl distribution Generic-ColorTheme-Kuler), released on 2018-02-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Generic-ColorTheme-Kuler>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Generic-ColorTheme-Kuler>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Generic-ColorTheme-Kuler>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
