# NAME

Luv::CLI - command-line dependency manager for love2d projects

# SYNOPSIS

    use Luv::CLI;
    Luv::CLI->run;

# DESCRIPTION

Top-level [App::Cmd](https://metacpan.org/pod/App%3A%3ACmd) application class for `luv`, a package manager
for LÖVE (love2d) game projects. Fetches libraries from git repositories,
tracks them in a project manifest, and packages projects into `.love`
files.

# AUTHOR

Nobunaga <nobunaga@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
