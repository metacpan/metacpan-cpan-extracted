# GQRX::Remote

This module provides a Perl interface for the [Gqrx remote control protocol](http://gqrx.dk/doc/remote-control).

GQRX::Remote only uses core Perl modules, and so has no dependencies. It should run anywhere Perl can run.

GQRX::Remote is on [CPAN](http://search.cpan.org/~dhaber/GQRX-Remote-1.0.1/Remote.pm).

The [Gqrx](http://gqrx.dk/) application itself officially runs on Linux, MacOS and Raspberry Pi. An unoffical version exists for Windows. For more information, see the [Gqrx download page](http://gqrx.dk/download).


# Example Usage

```perl
use GQRX::Remote;

# Initialize a $remote and connect to the local server
my $remote = GQRX::Remote->new();

$remote->connect();

# Set up some options
$remote->set_demodulator_mode('AM');
$remote->set_frequency(44000000);  # 44,000 kHz

# Retrieve the signal strength
my $strength = $remote->get_signal_strength();
```

For detailed usage information and examples, please see the [POD documentation](http://search.cpan.org/~dhaber/GQRX-Remote-1.0.1/Remote.pm).

An example script using GQRX::Remote to plot signal strength by frequency is [provided in the distribution](https://github.com/DougHaber/gqrx-remote/tree/master/example/).

Another example can be found in [gqrx-ghostbox](https://github.com/DougHaber/gqrx-ghostbox).  It is a utility that uses GQRX::Remote to make Gqrx behave like a ghost box.


# Installation

GQRX::Remote is on [CPAN](http://search.cpan.org/~dhaber/GQRX-Remote-1.0.1/Remote.pm), and may be installed using that.

To install this module from source:

```bash
perl Makefile.PL
make
make test
make install
```

By default, the tests will create and use a mock server, unless port 7356 is use, in which case it will assume a real Gqrx instance is running, and test against that.  The default location for a server can overriden by passing the environment variables `GQRX_REMOTE_TEST_HOST` and `GQRX_REMOTE_TEST_PORT` to the tests.


# Setting up Gqrx

In order to use the Gqrx Remote Protocol, the Gqrx application must be running with the remote turned on. To enable this, click on `Tools->Remote Control` in the menubar. This will need to be done each time Gqrx runs.

Earlier versions of Gqrx didn't have proper settings for allowing remote connections out of the box. Depending on your version, or if you need to allow connections from a host other than the localhost, you may need to modify the settings. To do this, go to `Tools->Remote Control Settings`. Make sure Gqrx is configured to allow connections from the host you plan on running the script on.


# Copyright and License

```
Copyright (C) 2016 by Douglas Haber

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.
```
