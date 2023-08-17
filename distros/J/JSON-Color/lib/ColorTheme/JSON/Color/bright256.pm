package ColorTheme::JSON::Color::bright256;

use strict;
use parent 'ColorThemeBase::Static::FromStructColors';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-02'; # DATE
our $DIST = 'JSON-Color'; # DIST
our $VERSION = '0.134'; # VERSION

sub _ansi256fg {
    my $code = shift;
    return {ansi_fg=>"\e[38;5;${code}m"};
}

our %THEME = (
    v => 2,
    summary => 'A brighter color theme for 256-color terminal, adapted from the Data::Dump::Color::Default256 theme',
    items => {
        string_quote         => _ansi256fg(226),
        string               => _ansi256fg(226),
        string_escape        => _ansi256fg(214),
        number               => _ansi256fg( 27),
        true                 => _ansi256fg( 21),
        false                => _ansi256fg( 21),
        null                 => _ansi256fg(124),
        object_key           => _ansi256fg(202),
        object_key_quote     => _ansi256fg(202),
        object_key_escape    => _ansi256fg(214),
        linum                => _ansi256fg( 10),
    },
);

1;
# ABSTRACT: A brighter color theme for 256-color terminal, adapted from the Data::Dump::Color::Default256 theme

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::JSON::Color::bright256 - A brighter color theme for 256-color terminal, adapted from the Data::Dump::Color::Default256 theme

=head1 VERSION

This document describes version 0.134 of ColorTheme::JSON::Color::bright256 (from Perl distribution JSON-Color), released on 2023-07-02.

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
