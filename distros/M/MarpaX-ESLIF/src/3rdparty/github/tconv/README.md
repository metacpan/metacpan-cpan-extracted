[![Build Status](https://travis-ci.org/jddurand/c-tconv.svg?branch=master)](https://travis-ci.org/jddurand/c-tconv) [![GitHub version](https://badge.fury.io/gh/jddurand%2Fc-tconv.svg)](https://badge.fury.io/gh/jddurand%2Fc-tconv) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](http://opensource.org/licenses/MIT)

# NAME

tconv - iconv-like interface with automatic charset detection

# DESCRIPTION

tconv is a generic interface on charset detection and character conversion implementations. It is not necessary anymore to know in advance the charset: if you do NOT specify, tconv will guess.

Built-in charset detection engines are: cchardet, ICU.
Built-in character conversion engines are: iconv (even on Windows, via win-iconv), ICU.

# SEE ALSO

[iconv(3)](http://man.he.net/man3/iconv), [cchardet](https://pypi.python.org/pypi/cchardet/), [win-iconv](https://github.com/win-iconv/win-iconv), [ICU](http://icu-project.org/)
