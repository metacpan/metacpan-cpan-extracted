INSTALLATION
------------

First, you need libfluent-bit.so   Alien::FluentBit helps you with this by building
one from source.  The binary dist from github.com/fluent/fluent-bit currently does
not work with perl without adding the library to LD_PRELOAD which is not a great
solution.

    apt-get install cmake flex bison m4   # not required, but speeds things up
    cpanm Alien::FluentBit

Now you can install the module:

    cpanm Fluent-LibFluentBit-0.02.tar.gz

or:

    tar -xf Fluent-LibFluentBit-0.02.tar.gz
    cd Fluent-LibFluentBit-0.02
    perl Makefile.PL
    make
    make test
    make install

DEVELOPMENT
-----------

Download or checkout the source code, then:

    dzil --authordeps | cpanm
    dzil test

To build and run single unit tests, use the 'dtest' script:

    ./dtest t/10-output-to-datadog.t

To build and install a trial version, use

    V=0.02_01 dzil build
    cpanm Fluent-LibFluentBit-0.02_01.tar.gz
