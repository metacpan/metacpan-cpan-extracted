# Message Extractor Example in Ruby

## Installation

***Important!*** **At the time of this writing, you have to install `Inline::Ruby`
from the forked Github repository
[https://github.com/gflohr/Inline-Ruby](https://github.com/gflohr/Inline-Ruby)!
if you are using ruby 1.9 or newer or if you are using MacPorts!**

You have to install the Perl mdoule `Inline::Ruby`.

If your package manager does not have a package for `Inline::Ruby` you
have the following options:

### CPAN Module

Try first:

```
sudo cpan install Inline::Ruby
```

If the command `cpan` cannot be found, try instead:

```
perl -MCPAN -e 'install Inline::Ruby'
```

### From Sources

When you build the module, you should try to not mix binaries from
different sources.  On the Mac, for example, you should use the
Ruby interpreter from MacPorts (and not the one that ships with Mac OS X)
if you use Perl from MacPorts.

In general, installing Perl Inline modules from source is often a
challenging tasks because build systems from two programming languages
have to be configured correctly.

#### From CPAN

Go to [http://search.cpan.org/~shlomif/Inline-Ruby/](http://search.cpan.org/~shlomif/Inline-Ruby/)
and click the link "Download".

Then follow the usual Perl installation plethora:

```
tar xzf Inline-Ruby-VERSION.tar.gz
cd Inline-Ruby
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
git clone https://github.com/shlomif/Inline-Ruby
cd Inline-Ruby
perl Makefile.PL
make
make test
sudo make install
```

Note that dependencies are not automatically installed! Please read
the output of ```perlMakefile.PL``` carefully!

***Important!*** **At the time of this writing, you have to install 
from the forked Github repository
[https://github.com/gflohr/Inline-Ruby](https://github.com/gflohr/Inline-Ruby)!
if you are using ruby 1.9 or newer or if you are using MacPorts!**

## Usage

The [README.md for all samples](../README.md) contains exhaustive
documentation for the Python example.  The Ruby example is very
similar.

The source code is also well-commented!

Unlike `Inline::Python`, `Inline::Ruby` does not support calling
Perl methods from Ruby code.  But Perl closures can be exposed
to Ruby as `Proc` objects.

The wrapper  `xgettext-lines.pl` contains some
magic that makes all methods from the original API directly callable.
See the source code in `RubyXGettext.rb` for more details if you
are interested.

As a result, the Ruby class behaves as if it was a direct subclass
of the Perl module `Locale::XGettext` and can call all methods from
the superclass just like a Perl subclass could do.
