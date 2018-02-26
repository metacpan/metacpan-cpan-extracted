package Generic::ColorTheme::Kuler;

our $DATE = '2018-02-25'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our %color_themes = (
    sandy_stone_beach_ocean_diver => {
        colors => {
            color1 => 'E6E2AF',
            color1 => 'A7A37E',
            color1 => 'EFECCA',
            color1 => '046380',
            color1 => '002F2F',
        },
    },
    firenze => {
        colors => {
            color1 => '468966',
            color1 => 'FFF0A5',
            color1 => 'FFB03B',
            color1 => 'B64926',
            color1 => '8E2800',
        },
    },
    natural_blue => {
        colors => {
            color1 => 'FCFFF5',
            color1 => 'D1DBBD',
            color1 => '91AA9D',
            color1 => '3E606F',
            color1 => '193441',
        },
    },
    vitamin_c => {
        colors => {
            color1 => '004358',
            color1 => '1F8A70',
            color1 => 'BEDB39',
            color1 => 'FFE11A',
            color1 => 'FD7400',
        },
    },
    aspirin_c => {
        colors => {
            color1 => '225378',
            color1 => '1695A3',
            color1 => 'ACF0F2',
            color1 => 'F3FFE2',
            color1 => 'EB7F00',
        },
    },
    sea_wolf => {
        colors => {
            color1 => 'DC3522',
            color1 => 'D9CB9E',
            color1 => '374140',
            color1 => '2A2C2B',
            color1 => '1E1E20',
        },
    },
    unlike => {
        colors => {
            color1 => '88A825',
            color1 => '35203B',
            color1 => '911146',
            color1 => 'CF4A30',
            color1 => 'ED8C2B',
        },
    },
    granny_smith_apple => {
        colors => {
            color1 => '85DB18',
            color1 => 'CDE855',
            color1 => 'F5F6D4',
            color1 => 'A7C520',
            color1 => '493F0B',
        },
    },
    red_hot => {
        colors => {
            color1 => '450003',
            color1 => '5C0002',
            color1 => '94090D',
            color1 => 'D40D12',
            color1 => 'FF1D23',
        },
    },
    pink_peppermint => {
        colors => {
            color1 => 'F6B1C3',
            color1 => 'F0788C',
            color1 => 'DE264C',
            color1 => 'BC0D35',
            color1 => 'A20D1E',
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

This document describes version 0.001 of Generic::ColorTheme::Kuler (from Perl distribution Generic-ColorTheme-Kuler), released on 2018-02-25.

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
