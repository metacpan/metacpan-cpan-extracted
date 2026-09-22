package Luv::CLI;

# ABSTRACT: command-line package manager for love2d projects

use v5.38;

use App::Cmd::Setup -app;

our $VERSION = '0.004';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI - command-line package manager for love2d projects

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    luv init [--name NAME] [--force|-f]
    luv add <repo-url|library-name> [...] [--ref REF]
    luv remove <library-name> [...] [--all|-a]
    luv list
    luv build
    luv search <term> [--all|-a] [--update]
    luv update

=head1 DESCRIPTION

Top-level L<App::Cmd> application class for C<luv>, a package manager
for LÖVE (love2d) game projects. Fetches libraries from git
repositories, tracks them in a project manifest, and packages projects
into C<.love> files.

=head1 NAME

Luv::CLI - command-line package manager for love2d projects

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ogun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
