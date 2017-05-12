Devel-DTrace-Provider version 1.00
==================================

This is Perl bindings for libusdt, which allows you to create DTrace
providers at runtime, from your Perl code.

See: https://github.com/chrisa/libusdt

Installation
------------

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

Example Usage
-------------

  use Devel::DTrace::Provider;

  my $provider = Devel::DTrace::Provider->new('test0', 'test1module');
  my $probe = $provider->probe('test', 'func', 'string', 'integer');
  $provider->enable;
  $probe->fire('foo', 42);

Platform Requirements
---------------------

Requires a libusdt-supported platform. Currently this is
Solaris/Illumos and Mac OS X, i386 and x86_64. 

Copyright and Licence
---------------------

Copyright (C) 2008-2012, Chris Andrews <chris@nodnol.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


