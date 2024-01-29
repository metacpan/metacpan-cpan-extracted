# Math::Int64

Manipulate 64 bits integers in Perl

## CPAN releases

The versions of the module released to CPAN can be compiled and
installed with the usual sequence of commands:

    perl Makefile.PL
    make
    make test
    make install


## Development version

The source code for the development version of **Math::Int64** is
available from [GitHub](https://github.com/salva/p5-Math-Int64).

It is managed with [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).

Briedfly, you can compile it running the following command:

```
dzil build
```

test it:

```
dzil test
```

and release it (though, you need permissions for that):

```
dzil release
```

In order to generate the C API support files, the module
[Module::CAPIMaker](https://metacpan.org/pod/Module::CAPIMaker) is
required.

## Copyright and License

Copyright &copy; 2007, 2009, 2011-2015 by Salvador Fandi&ntilde;o
(sfandino@yahoo.com)

Copyright &copy; 2014,  2015 by Dave Rolsky (autarch@urth.org)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
