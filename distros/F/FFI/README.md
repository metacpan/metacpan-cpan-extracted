# FFI [![Build Status](https://secure.travis-ci.org/plicease/FFI.png)](http://travis-ci.org/plicease/FFI)

Perl Foreign Function Interface based on GNU ffcall

# SYNOPSIS

```perl
use FFI;
$addr = <address of a C function>
$signature = <function signature>
$ret = FFI::call($addr, $signature, ...);
 
$cb = FFI::callback($signature, sub {...});
$ret = FFI::call($addr, $signature, $cb->addr, ...);
```

# DESCRIPTION

If you are interested in FFI and Perl you should probably consider newer 
projects, such as FFI::Platypus or FFI::Raw instead.  They have more 
features, are usually faster and are actively maintained.

The original README follows.

The FFI and FFI::Library modules implement a foreign function interface 
for Perl.  The foreign function interface allows Perl code to directly 
call C functions exported from shared libraries (DLLs on Windows, .so 
files on Unix). It also allows a Perl subroutine to be packaged as a 
function which can be passed to an external C routine ("callbacks").

There are two modules in the package:

- FFI is a low-level interface, providing two functions, call() and
  callback(). The call() routine expects to be passed a "raw" function
  address, but the module provides no way of creating such an address.
  That is left to other modules.

- FFI::Library encapsulates the concept of a shared library. It offers
  functions to load a library (and to automatically unload it when it is
  no longer required), and to extract functions from the library, in a
  form suitable for calling from Perl.

See the file INSTALL for installation details.
