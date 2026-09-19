# NAME

Luv::CLI - command-line package manager for love2d projects

# SYNOPSIS

    luv init [--name NAME] [--force|-f]
    luv add <repo-url|library-name> [...] [--ref REF]
    luv remove <library-name> [...] [--all|-a]
    luv list
    luv build
    luv search <term> [--all|-a] [--update]
    luv update

# DESCRIPTION

Top-level [App::Cmd](https://metacpan.org/pod/App%3A%3ACmd) application class for `luv`, a package manager
for LÖVE (love2d) game projects. Fetches libraries from git
repositories, tracks them in a project manifest, and packages projects
into `.love` files.

# AUTHOR

Nobunaga <nobunaga@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
