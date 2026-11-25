## HOW TO CONTRIBUTE

Thank you for considering contributing to this distribution. This file contains
instructions that will help you work with the source code.

The distribution is managed with Dist::Zilla. This means than many of the usual
files you might expect are not in the repository. Instead they are generated at
build/release time.  
You do not need Dist::Zilla to contribute patches. Which is why some generated
files are kept in the repository as a convenience (e.g. Makefile.PL or
cpanfile).

### Getting dependencies

If you have App::cpanminus 1.6 or later installed, you can use `cpanm` to
satisfy dependencies like this:

    $ cpanm --installdeps .

### Running tests

You can run tests directly using the `prove` tool:

    $ prove -l
    $ prove -lv t/some_test_file.t

### Code style and tidying

Please try to match any existing coding style. If there is a `.perltidyrc`
file, please install Perl::Tidy and use perltidy before submitting patches.

There isn't a hard enforcement on coding style and tidying. While there are
some preferences, the code of the patch is more important than how it's styled.
All that said, if you really want to follow the project standards, you could
always grab the latest version of my personal perltidyrc which I use in any
project that doesn't contain a `.perltidyrc`.

[https://gitlab.com/waterkip/dotty/-/blob/master/perl/.perltidyrc?ref_type=heads](https://gitlab.com/waterkip/dotty/-/blob/master/perl/.perltidyrc?ref_type=heads).

### Installing and using Dist::Zilla

Dist::Zilla is a very powerful authoring tool, optimized for maintaining a
large number of distributions with a high degree of automation, but it has a
large dependency chain, a bit of a learning curve and requires a number of
author-specific plugins.

To install it from CPAN, use your prefered method of installation. You are
probably the quickest if you install
`Dist::Zilla::PluginBundle::Author::WATERKIP` as it pulls in all the
dependencies.

You can learn more about Dist::Zilla at [https://dzil.org](https://dzil.org).
