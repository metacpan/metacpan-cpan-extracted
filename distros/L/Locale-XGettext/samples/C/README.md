# Message Extractor Example in C

## Installation

You have to install the Perl mdoule `Inline::C`.

If your package manager does not have a package for `Inline::C` you
have the following options:

### CPAN Module

Try first:

```
sudo cpan install Inline::C
```

If the command `cpan` cannot be found, try instead:

```
perl -MCPAN -e 'install Inline::C'
```

### From Sources

When you build the module, you should try to use the same C compiler
that was used for compiling the Perl interpreter.  You can use the
command ```perl -V``` in order to find out how the Perl interpreter
was built.

#### From CPAN

Go to [http://search.cpan.org/~tinita/Inline-C/](http://search.cpan.org/~tinita/Inline-C/)
and click the link "Download".

Then follow the usual Perl installation plethora:

```
tar xzf Inline-C-VERSION.tar.gz
cd Inline-Python
perl Makefile.PL
make
make test
sudo make install
```

Note that dependencies are not automatically installed! Please read
the output of ```perl Makefile.PL``` carefully!

#### From Git

Alternatively, you can use the latest sources from Git:

```
git clone https://github.com/ingydotnet/inline-c-pm 
cd Inline-C
perl Makefile.PL
make
make test
sudo make install
```

Note that dependencies are not automatically installed! Please read
the output of ```perl Makefile.PL``` carefully!

## Usage

The [README.md for all samples](../README.md) contains exhaustive
documentation for the Python example.
