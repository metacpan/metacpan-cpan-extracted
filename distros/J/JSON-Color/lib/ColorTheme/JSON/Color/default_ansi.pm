package ColorTheme::JSON::Color::default_ansi;

use strict;
use parent 'ColorThemeBase::Static::FromStructColors';
use Term::ANSIColor qw(:constants);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-02'; # DATE
our $DIST = 'JSON-Color'; # DIST
our $VERSION = '0.134'; # VERSION

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

ColorTheme::JSON::Color::default_ansi - The default color theme for JSON::Color, using ANSI codes

=head1 VERSION

This document describes version 0.134 of ColorTheme::JSON::Color::default_ansi (from Perl distribution JSON-Color), released on 2023-07-02.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/JSON-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-JSON-Color>.

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

This software is copyright (c) 2023, 2021, 2016, 2015, 2014, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=JSON-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
