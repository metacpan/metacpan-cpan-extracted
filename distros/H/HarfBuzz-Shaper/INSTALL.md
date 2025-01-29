# Introduction

HarfBuzz::Shaper is a Perl module that interfaces with the native
harfbuzz library. It uses the XS facility to bridge between Perl and
native C code.

To build this module, you must therefore have a C-compiler and the
harfbuzz libraries installed.

# Linux

For best results install the following packages:

    harfbuzz

Often the development parts of the harfbuzz library are in a separate
package. So if there is a package named harfbuzz-devel you need to
install that as well.

If there is no harfbuzz library available on your distribution,
HarfBuzz::Shaper will build its own version of the harfbuzz library.

Note that this requires a suitable C++-compiler, e.g. GNU g++.

# Microsoft Windows

The preferred Perl software for MSWindows is Strawberry Perl. It can
be downloaded from https://strawberryperl.com. It includes C-compiler
and other development tools.

As of version 5.30, this package also contains the harfbuzz library.
So if you install this, or a newer, version of Strawberry Perl you are
all set to go.

For older (and maybe other) Perl installs HarfBuzz::Shaper will try to
build its own version of the harfbuzz library.

Note that this requires a suitable C++-compiler, e.g. GNU g++.
