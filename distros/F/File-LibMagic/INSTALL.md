# Installing File-LibMagic

Installing File-LibMagic requires that you have the *libmagic.so* library and
the *magic.h* header file installed. Once those are installed, this module is
installed like any other Perl distributions.

## Installing libmagic

On Debian/Ubuntu run:

    sudo apt-get install libmagic-dev

On Mac you can use homebrew (https://brew.sh/):

    brew install libmagic

## Installation with cpanm

If you have cpanm, you only need one line:

    % cpanm File::LibMagic

If you are installing into a system-wide directory, you may need to pass the
"-S" flag to cpanm, which uses sudo to install the module:

    % cpanm -S File::LibMagic

## Installing with the CPAN shell

Alternatively, if your CPAN shell is set up, you should just be able to do:

    % cpan File::LibMagic

## Manual installation

As a last resort, you can manually install it. Download the tarball, untar it,
then build it:

    % perl Makefile.PL
    % make && make test

Then install it:

    % make install

If you are installing into a system-wide directory, you may need to run:

    % sudo make install

## Specifying additional lib and include directories

On some systems, you may need to pass additional lib and include directories
to the Makefile.PL. You can do this with the `--lib` and `--include`
parameters:

    perl Makefile.PL --lib /usr/local/include --include /usr/local/include

You can pass these parameters multiple times to specify more than one
location.

## Documentation

File-LibMagic documentation is available as POD.
You can run perldoc from a shell to read the documentation:

    % perldoc File::LibMagic
