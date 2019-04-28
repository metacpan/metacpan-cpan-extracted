# NAME

Inline::Pdlapp - Write PDLA Subroutines inline with PDLA::PP

# DESCRIPTION

`Inline::Pdlapp` is a module that allows you to write PDLA subroutines
in the PDLA::PP style. The big benefit compared to plain `PDLA::PP` is
that you can write these definitions inline in any old perl script
(without the normal hassle of creating Makefiles, building, etc).
Since version 0.30 the Inline module supports multiple programming
languages and each language has its own support module. This document
describes how to use Inline with PDLA::PP (or rather, it will once
these docs are complete `;)`.

For more information on Inline in general, see [Inline](https://metacpan.org/pod/Inline).

Some example scripts demonstrating `Inline::Pdlapp` usage can be
found in the `examples` directory.

`Inline::Pdlapp` is a subclass of [Inline::C](https://metacpan.org/pod/Inline::C). Most Kudos goes to Brian I.

# USAGE

You never actually use `Inline::Pdlapp` directly. It is just a support module
for using `Inline.pm` with `PDLA::PP`. So the usage is always:

    use Inline Pdlapp => ...;

or

    bind Inline Pdlapp => ...;

# EXAMPLES

Pending availability of full docs a few quick examples
that illustrate typical usage.

## A simple example

    # example script inlpp.pl
    use PDLA; # must be called before (!) 'use Inline Pdlapp' calls

    use Inline Pdlapp; # the actual code is in the __Pdlapp__ block below

    $a = sequence 10;
    print $a->inc,"\n";
    print $a->inc->dummy(1,10)->tcumul,"\n";

    __DATA__

    __Pdlapp__

    pp_def('inc',
           Pars => 'i();[o] o()',
           Code => '$o() = $i() + 1;',
          );

    pp_def('tcumul',
           Pars => 'in(n);[o] mul()',
           Code => '$mul() = 1;
                    loop(n) %{
                      $mul() *= $in();
                    %}',
    );
    # end example script

If you call this script it should generate output similar to this:

    prompt> perl inlpp.pl
    Inline running PDLA::PP version 2.2...
    [1 2 3 4 5 6 7 8 9 10]
    [3628800 3628800 3628800 3628800 3628800 3628800 3628800 3628800 3628800 3628800]

Usage of `Inline::Pdlapp` in general is similar to `Inline::C`.
In the absence of full docs for `Inline::Pdlapp` you might want to compare
[Inline::C](https://metacpan.org/pod/Inline::C).

## Code that uses external libraries, etc

The script below is somewhat more complicated in that it uses code
from an external library (here from Numerical Recipes). All the
relevant information regarding include files, libraries and boot
code is specified in a config call to `Inline`. For more experienced
Perl hackers it might be helpful to know that the format is
similar to that used with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker). The
keywords are largely equivalent to those used with `Inline::C`. Please
see below for further details on the usage of `INC`,
`LIBS`, `AUTO_INCLUDE` and `BOOT`.

    use PDLA; # this must be called before (!) 'use Inline Pdlapp' calls

    use Inline Pdlapp => Config =>
      INC => "-I$ENV{HOME}/include",
      LIBS => "-L$ENV{HOME}/lib -lnr -lm",
      # code to be included in the generated XS
      AUTO_INCLUDE => <<'EOINC',
    #include <math.h>
    #include "nr.h"    /* for poidev */
    #include "nrutil.h"  /* for err_handler */

    static void nr_barf(char *err_txt)
    {
      fprintf(stderr,"Now calling croak...\n");
      croak("NR runtime error: %s",err_txt);
    }
    EOINC
    # install our error handler when loading the Inline::Pdlapp code
    BOOT => 'set_nr_err_handler(nr_barf);';

    use Inline Pdlapp; # the actual code is in the __Pdlapp__ block below

    $a = zeroes(10) + 30;;
    print $a->poidev(5),"\n";

    __DATA__

    __Pdlapp__

    pp_def('poidev',
            Pars => 'xm(); [o] pd()',
            GenericTypes => [L,F,D],
            OtherPars => 'long idum',
            Code => '$pd() = poidev((float) $xm(), &$COMP(idum));',
    );

# MAKING AN INSTALLABLE MODULE

It is possible, using [Inline::Module](https://metacpan.org/pod/Inline::Module), to create an installable `.pm`
file with inline PDLA code. [PDLA::IO::HDF](https://metacpan.org/pod/PDLA::IO::HDF) is a working example. Here's
how. You make a Perl module as usual, with a package declaration in
the normal way. Then (assume your package is `PDLA::IO::HDF::SD`):

    package PDLA::IO::HDF::SD;
    # ...
    use FindBin;
    use Alien::HDF4::Install::Files;
    use PDLA::IO::HDF::SD::Inline Pdlapp => 'DATA',
      package => __PACKAGE__, # if you have any pp_addxs - else don't bother
      %{ Alien::HDF4::Install::Files->Inline('C') }, # EUD returns empty if !"C"
      typemaps => "$FindBin::Bin/lib/PDLA/IO/HDF/typemap.hdf",
      ;
    # ...
    1;
    __DATA__
    __Pdlapp__
    pp_addhdr(<<'EOH');
    /* ... */
    EOH
    use FindBin;
    use lib "$FindBin::Bin/../../../../../../..";
    require 'buildfunc.noinst';
    # etc

Note that for any files that you need to access for build purposes (they
won't be touched during post-install runtime), [FindBin](https://metacpan.org/pod/FindBin) is useful,
albeit slightly complicated.

In the main `.pm` body, [FindBin](https://metacpan.org/pod/FindBin) will find the build directory, as
illustrated above. However, in the "inline" parts, `FindBin` will be
within the [Inline::Module](https://metacpan.org/pod/Inline::Module) build directory. At the time of writing,
this is under `.inline` within the build directory, in a subdirectory
named after the package. The example shown above has seven `..`: two
for `.inline/build`, and five more for `PDLA/IO/HDF/SD/Inline`.

The rest of the requirements are given in the [Inline::Module](https://metacpan.org/pod/Inline::Module)
documentation.

This technique avoids having to use [PDLA::Core::Dev](https://metacpan.org/pod/PDLA::Core::Dev), create a
`Makefile.PL`, have one directory per `.pd`, etc. It will even build
/ install faster, since unlike a build of an [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)
distribution with multiple directories, it can be built in parallel. This
is because the EUMM build changes into each directory, and waits for each
one to complete. This technique can run concurrently without problems.

# PDLAPP CONFIGURATION OPTIONS

For information on how to specify Inline configuration options, see
[Inline](https://metacpan.org/pod/Inline). This section describes each of the configuration options
available for Pdlapp. Most of the options correspond either to MakeMaker or
XS options of the same name. See [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) and [perlxs](https://metacpan.org/pod/perlxs).

## AUTO\_INCLUDE

Specifies extra statements to automatically included. They will be
added onto the defaults. A newline char will be automatically added.
Does essentially the same as a call to `pp_addhdr`. For short
bits of code `AUTO_INCLUDE` is probably syntactically nicer.

    use Inline Pdlapp => Config => AUTO_INCLUDE => '#include "yourheader.h"';

## BLESS

Same as `pp_bless` command. Specifies the package (i.e. class)
to which your new _pp\_def_ed methods will be added. Defaults
to `PDLA` if omitted.

    use Inline Pdlapp => Config => BLESS => 'PDLA::Complex';

cf ["PACKAGE"](#package), equivalent for ["pp\_addxs" in PDLA::PP](https://metacpan.org/pod/PDLA::PP#pp_addxs).

## BOOT

Specifies C code to be executed in the XS BOOT section. Corresponds to
the XS parameter. Does the same as the `pp_add_boot` command. Often used
to execute code only once at load time of the module, e.g. a library
initialization call.

## CC

Specify which compiler to use.

## CCFLAGS

Specify extra compiler flags.

## INC

Specifies an include path to use. Corresponds to the MakeMaker parameter.

    use Inline Pdlapp => Config => INC => '-I/inc/path';

## LD

Specify which linker to use.

## LDDLFLAGS

Specify which linker flags to use.

NOTE: These flags will completely override the existing flags, instead
of just adding to them. So if you need to use those too, you must
respecify them here.

## LIBS

Specifies external libraries that should be linked into your
code. Corresponds to the MakeMaker parameter.

    use Inline Pdlapp => Config => LIBS => '-lyourlib';

or

    use Inline Pdlapp => Config => LIBS => '-L/your/path -lyourlib';

## MAKE

Specify the name of the 'make' utility to use.

## MYEXTLIB

Specifies a user compiled object that should be linked in. Corresponds
to the MakeMaker parameter.

    use Inline Pdlapp => Config => MYEXTLIB => '/your/path/yourmodule.so';

## OPTIMIZE

This controls the MakeMaker OPTIMIZE setting. By setting this value to
'-g', you can turn on debugging support for your Inline
extensions. This will allow you to be able to set breakpoints in your
C code using a debugger like gdb.

## PACKAGE

Controls into which package the created XSUBs from ["pp\_addxs" in PDLA::PP](https://metacpan.org/pod/PDLA::PP#pp_addxs)
go. E.g.:

    use Inline Pdlapp => 'DATA', => PACKAGE => 'Other::Place';

will put the created routines into `Other::Place`, not the calling
package (which is the default). Note this differs from ["BLESS"](#bless), which
is where ["pp\_def" in PDLA::PP](https://metacpan.org/pod/PDLA::PP#pp_def)s go.

## TYPEMAPS

Specifies extra typemap files to use. Corresponds to the MakeMaker parameter.

    use Inline Pdlapp => Config => TYPEMAPS => '/your/path/typemap';

## NOISY

Show the output of any compilations going on behind the scenes. Turns
on `BUILD_NOISY` in [Inline::C](https://metacpan.org/pod/Inline::C).

# BUGS

## `do`ing inline scripts

Beware that there is a problem when you use
the \_\_DATA\_\_ keyword style of Inline definition and
want to `do` your script containing inlined code. For example

      # myscript.pl contains inlined code
      # in the __DATA__ section
      perl -e 'do "myscript.pl";'
    One or more DATA sections were not processed by Inline.

According to Brian Ingerson (of Inline fame) the workaround is
to include an `Inline->init` call in your script, e.g.

    use PDLA;
    use Inline Pdlapp;
    Inline->init;

    # perl code

    __DATA__
    __Pdlapp__

    # pp code

## `PDLA::NiceSlice` and `Inline::Pdlapp`

There is currently an undesired interaction between
[PDLA::NiceSlice](https://metacpan.org/pod/PDLA::NiceSlice) and `Inline::Pdlapp`.
Since PP code generally contains expressions
of the type `$var()` (to access piddles, etc)
[PDLA::NiceSlice](https://metacpan.org/pod/PDLA::NiceSlice) recognizes those incorrectly as
slice expressions and does its substitutions. For the moment
(until hopefully the parser can deal with that) it is best to
explicitly switch [PDLA::NiceSlice](https://metacpan.org/pod/PDLA::NiceSlice) off before
the section of inlined Pdlapp code. For example:

    use PDLA::NiceSlice;
    use Inline::Pdlapp;

    $a = sequence 10;
    $a(0:3)++;
    $a->inc;

    no PDLA::NiceSlice;

    __DATA__

    __C__

    ppdef (...); # your full pp definition here

# ACKNOWLEDGEMENTS

Brian Ingerson for creating the Inline infrastructure.

# AUTHOR

Christian Soeller <soellermail@excite.com>

# SEE ALSO

- [PDLA](https://metacpan.org/pod/PDLA)
- [PDLA::PP](https://metacpan.org/pod/PDLA::PP)
- [Inline](https://metacpan.org/pod/Inline)
- [Inline::C](https://metacpan.org/pod/Inline::C)
- [Inline::Module](https://metacpan.org/pod/Inline::Module)

# COPYRIGHT

Copyright (c) 2001. Christian Soeller. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as PDLA itself.

See http://pdl.perl.org
