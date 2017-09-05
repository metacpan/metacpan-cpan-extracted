# Libssh::Session - Secure Shell protocol interface

Libssh::Session is a perl interface to the libssh library : https://www.libssh.org/
It supports the authentification on a SSH server and command execution. 

It's still in working progress.

### MODULE DEPENDENCIES

To install Libssh::Session, you need following perl module:

* ExtUtils-MakeMaker

For the module execution, no need of perl module dependencies.

### DEPENDENCIES

This module also requires these libraries:

* [libssh](https://www.libssh.org/) (recommended to use version 0.7.0 or later)
* OpenSSL

### INSTALLATION

To compile libssh dependency on centos 6:

```
# mkdir build
# cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DLIB_SUFFIX=64 -DLIB_INSTALL_DIR=/usr/lib64 ..
# make
# make install
```

To install Libssh::Session type the following:

```
# perl Makefile.PL
# make
# make install
```

### INFORMATION

By default, the OpenSSH daemon authorize 10 sessions in parrallel for one connection. You can increase that number with option
MaxSessions.

### BUGS/FEATURE REQUESTS

Please report bugs and request features on the github : https://github.com/garnier-quentin/perl-libssh

All helps are welcomed!
