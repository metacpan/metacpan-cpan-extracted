[![Build Status](https://secure.travis-ci.org/joaocosta/Finance-FXCM-Simple.png?branch=master)](https://travis-ci.org/joaocosta/Finance-FXCM-Simple)

This module provides methods to trade FXCM accounts in perl, by wrapping around FXCM's ForexConnect library ( http://fxcodebase.com/wiki/index.php/What_is_ForexConnect_API%3F )

[Full documentation available as perldoc](http://search.cpan.org/perldoc?Finance%3A%3AFXCM%3A%3ASimple)

# Build time dependencies

This module depends on the ForexConnect library, which is available in binary format only, eg:

    curl http://fxcodebase.com/bin/forexconnect/1.3.2/ForexConnectAPI-1.3.2-Linux-x86_64.tar.gz | tar zxf - -C ~
    export FXCONNECT_HOME=~/ForexConnectAPI-1.3.2-Linux-x86_64
    perl Makefile.PL
    make

# Running the tests

The default test simply tests that the module can load. To actually test trading API functions, you will need to set environment variables with details of your FXCM demo account, eg:

    export FXCM_USER=XXXXXXXXXXXX
    export FXCM_PASSWORD=XXXX
    make test
