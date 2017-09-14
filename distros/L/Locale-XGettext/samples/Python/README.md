# Message Extractor Example in Python

## Installation

You have to install the Perl mdoule `Inline::Python`.

If your package manager does not have a package for `Inline::Python` you
have the following options:

### CPAN Module

Try first:

```
sudo cpan install Inline::Python
```

If the command `cpan` cannot be found, try instead:

```
perl -MCPAN -e 'install Inline::Python'
```

### From Sources

When you build the module, you should try to not mix binaries from
different sources.  On the Mac, for example, you should use the
Python interpreter from MacPorts (and not the one that ships with Mac OS X)
if you use Perl from MacPorts.

In general, installing Perl Inline modules from source is often a
challenging tasks because build systems from two programming languages
have to be configured correctly.

#### From CPAN

Go to [http://search.cpan.org/~nine/Inline-Python/](http://search.cpan.org/~nine/Inline-Python/)
and click the link "Download".

Then follow the usual Perl installation plethora:

```
tar xzf Inline-Python-VERSION.tar.gz
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
git clone http://github.com/niner/inline-python-pm.git
cd Inline-Python
perl Makefile.PL
make
make test
sudo make install
```

Note that dependencies are not automatically installed! Please read
the output of ```perlMakefile.PL``` carefully!

## Usage

The [README.md for all samples](../README.md) contains exhaustive
documentation for the Python example.

The source code is also well-commented!
