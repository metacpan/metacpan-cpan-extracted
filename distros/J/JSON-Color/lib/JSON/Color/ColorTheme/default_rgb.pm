package JSON::Color::ColorTheme::default_rgb;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'JSON-Color'; # DIST
our $VERSION = '0.131'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';
use Graphics::ColorNamesLite::WWW;

my $t = $Graphics::ColorNamesLite::WWW::NAMES_RGB_TABLE;

our %THEME = (
    v => 2,
    summary => 'The default color theme for JSON::Color, using RGB color codes',
    items => {
        string_quote         => $t->{forestgreen},
        string               => $t->{green},
        string_escape        => $t->{greenyellow},
        number               => $t->{darkmagenta},
        true                 => $t->{cyan},
        false                => $t->{darkcyan},
        null                 => $t->{blue},
        object_key           => $t->{darkmagenta},
        object_key_quote     => $t->{darkmagenta},
        object_key_escape    => $t->{magenta},
        linum                => {bg=>$t->{white}, fg=>$t->{black}},
    },
);

1;
# ABSTRACT: The default color theme for JSON::Color, using RGB color codes

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Color::ColorTheme::default_rgb - The default color theme for JSON::Color, using RGB color codes

=head1 VERSION

This document describes version 0.131 of JSON::Color::ColorTheme::default_rgb (from Perl distribution JSON-Color), released on 2021-05-07.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/JSON-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-JSON-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=JSON-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2016, 2015, 2014, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
