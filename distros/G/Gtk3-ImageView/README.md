# Gtk3::ImageView

Gtk3 imager viewer widget modelled after the GtkImageView C widget by Björn
Lindqvist <bjourne@gmail.com>

To discuss Gtk3::ImageView or gtk3-perl, ask questions and flame/praise the
authors, join [mailing list](mailto:gtk-perl-list@gnome.org) at lists.gnome.org.

## INSTALLATION

This module is available from [CPAN](https://metacpan.org/pod/Gtk3::ImageView).

To install it from source instead install [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla), then type the following:

```shell
dzil install
```

To avoid installing to a system directory, you can change the installation
prefix at Makefile.PL time with

```shell
dzil install --install-command='cpanm -l /tmp/foo .'
```

Or you can use `dzil build` to get the directory of the release in current dir, cd there, and build/install it with via generated Makefile.PL manually.

`dzil help`, [dzil.org](http://dzil.org) and [Dist::Zilla::Tutorial](https://metacpan.org/pod/Dist::Zilla::Tutorial#BUILDING-YOUR-DIST) have more details.

This will install the module to the subdirectory lib/perl5 under the given
prefix. If this is not already in perl's include path, you'll need to tell
perl how to get to this library directory so you can use it; there are three
ways:

- in your environment (the easiest):

```shell
PERL5LIB=/some/other/place/lib/perl5/site_perl
export PERL5LIB
```

- on the perl command line:

```shell
perl -I /some/other/place/lib/perl5/site_perl yourscript
```

- in the code of your perl script:

```shell
use lib '/some/other/place/lib/perl5/site_perl';
```

## DEPENDENCIES

This module requires these other modules and libraries:

- perl >= 5.8.0
- Glib >= 1.163 (Perl module)
- GTK+ 3.x (C library)
- Gtk3 (Perl module)
- Readonly (Perl module)

## BUG REPORTS

Please submit bug reports [here](https://github.com/carygravel/gtk3-imageview/issues)

## COPYRIGHT AND LICENSE

Copyright (C) 2018--2020 by Jeffrey Ratcliffe
Copyright (C) 2020 Google LLC, contributed by Alexey Sokolov

Modelled after the GtkImageView C widget by Björn Lindqvist <bjourne@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.
