# NAME

Do

# ABSTRACT

Modern Perl

# SYNOPSIS

    package main;

    use Do;

    fun greeting($name) {
      "Hello $name";
    }

    say greeting("world");

    1;

# DESCRIPTION

This package aims to provide a modern Perl development framework and
foundational set of types, functions, classes, patterns, and interfaces for
jump-starting application development. This package inherits all behavior from
[Data::Object](https://metacpan.org/pod/Data::Object); Please see that documentation to learn more. Also, you can
read the [overview](https://github.com/iamalnewkirk/do/blob/master/OVERVIEW.md)
and project [wiki](https://github.com/iamalnewkirk/do/wiki).

# INSTALLATION

If you have cpanm, you only need one line:

    $ cpanm -qn Do

If you don't have cpanm, get it! It takes less than a minute, otherwise:

    $ curl -L https://cpanmin.us | perl - -qn Do

Add `Do` to the list of dependencies in `cpanfile`:

    requires "Do" => "1.87"; # 1.87 or newer

If cpanm doesn't have permission to install modules in the current Perl
installation, it will automatically set up and install to a local::lib in your
home directory.  See the [local::lib](https://metacpan.org/pod/local::lib) documentation for details on
enabling it in your environment. We recommend using a
[Perlbrew](https://github.com/gugod/app-perlbrew) or
[Plenv](https://github.com/tokuhirom/plenv) environment. These tools will help
you manage multiple Perl installations in your `$HOME` directory. They are
completely isolated Perl installations.

# CREDITS

Al Newkirk, `+319`

Anthony Brummett, `+10`

Adam Hopkins, `+2`

José Joaquín Atria, `+1`

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

# PROJECT

[Wiki](https://github.com/iamalnewkirk/do/wiki)

[Project](https://github.com/iamalnewkirk/do)

[Initiatives](https://github.com/iamalnewkirk/do/projects)

[Milestones](https://github.com/iamalnewkirk/do/milestones)

[Contributing](https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn)

[Issues](https://github.com/iamalnewkirk/do/issues)

# SEE ALSO

To get the most out of this distribution, consider reading the following:

[Do](https://metacpan.org/pod/Do)

[Data::Object](https://metacpan.org/pod/Data::Object)

[Data::Object::Class](https://metacpan.org/pod/Data::Object::Class)

[Data::Object::ClassHas](https://metacpan.org/pod/Data::Object::ClassHas)

[Data::Object::Role](https://metacpan.org/pod/Data::Object::Role)

[Data::Object::RoleHas](https://metacpan.org/pod/Data::Object::RoleHas)

[Data::Object::Library](https://metacpan.org/pod/Data::Object::Library)
