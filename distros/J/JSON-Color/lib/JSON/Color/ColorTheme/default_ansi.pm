package JSON::Color::ColorTheme::default_ansi;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'JSON-Color'; # DIST
our $VERSION = '0.131'; # VERSION

use parent 'ColorThemeBase::Static::FromStructColors';
use Term::ANSIColor qw(:constants);

our %THEME = (
    v => 2,
    summary => 'The default color theme for JSON::Color, using ANSI codes',
    items => {
        string_quote         => {ansi_fg=>BOLD . BRIGHT_GREEN},
        string               => {ansi_fg=>GREEN},
        string_escape        => {ansi_fg=>BOLD},
        number               => {ansi_fg=>BOLD . BRIGHT_MAGENTA},
        true                 => {ansi_fg=>BOLD . CYAN},
        false                => {ansi_fg=>CYAN},
        bool                 => {ansi_fg=>CYAN},
        null                 => {ansi_fg=>BOLD . BLUE},
        object_key           => {ansi_fg=>MAGENTA},
        object_key_quote     => {ansi_fg=>MAGENTA},
        object_key_escape    => {ansi_fg=>BOLD},
        linum                => {ansi_fg=>REVERSE . WHITE},
    },
);

1;
# ABSTRACT: The default color theme for JSON::Color, using ANSI codes

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Color::ColorTheme::default_ansi - The default color theme for JSON::Color, using ANSI codes

=head1 VERSION

This document describes version 0.131 of JSON::Color::ColorTheme::default_ansi (from Perl distribution JSON-Color), released on 2021-05-07.

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
