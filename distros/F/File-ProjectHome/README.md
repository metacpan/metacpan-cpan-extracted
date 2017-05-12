# NAME

File::ProjectHome - Find home dir of a project

# SYNOPSIS

in /home/Cside/work/Some-Project/lib/Some/Module.pm

    use File::ProjectHome;
    print File::ProjectHome->project_home;  #=> /home/Cside/work/Some-Project

# DESCRIPTION

This module finds a project's home dir: nearest ancestral directory that contains any of these file or directories:

    cpanfile
    .git/
    .gitmodules
    Makefile.PL
    Build.PL

# SEE ALSAO

[Project::Libs](http://search.cpan.org/perldoc?Project::Libs)

# LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroki Honda <cside.story@gmail.com>
