# Hook::AfterRuntime

[![Build status](https://ci.appveyor.com/api/projects/status/xpp5rpg9v1gqlh5k/branch/master?svg=true)](https://ci.appveyor.com/project/paultcochrane/hook-afterruntime-m8v6m/branch/master)

Run code at the end of the compiling scope's runtime.

Useful for creating modules that need a behavior to be added when a module
that uses them completes its runtime. Like `B::Hooks::EndOfScope` except it
triggers for run-time instead of compile-time.

## Usage

Here is an example where it might be handy:

```
#!/usr/bin/perl
use strict;
use warnings;
use Moose;

...

# It would be nice not to need this....
__PACKAGE__->make_immutable;
```

## Installation

The easiest way to install this module is with `cpanm`:

```
$ cpanm Hook::AfterRuntime
```

Alternatively, you can install from the source code by either cloning the
repository

```
$ git clone https://github.com/exodist/Hook-AfterRuntime.git
```

or by downloading and unpacking the source tarball from CPAN:

```
$ wget https://cpan.metacpan.org/authors/id/E/EX/EXODIST/Hook-AfterRuntime-<version>.tar.gz
$ tar -xvzf Hook-AfterRuntime-<version>.tar.gz
```

Now enter the newly-created directory and install via `Module::Build`:

```
$ cd Hook-AfterRuntime
$ perl Build.PL
$ ./Build test
$ ./Build install
```

## Documentation

Full documentation for this module can be displayed by using `perldoc`:

```
$ perldoc Hook::AfterRuntime
```

## Authors

  - Chad Granum <exodist7@gmail.com>
  - Paul Cochrane <paul@liekut.de> (maintainer)

## Copyright and License

Copyright (C) 2010-2018 Chad Granum

Hook-AfterRuntime is free software, you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
