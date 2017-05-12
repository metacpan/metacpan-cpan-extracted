# LaTeXML::Plugin::latexmls

[![Build Status](https://secure.travis-ci.org/dginev/LaTeXML-Plugin-latexmls.png?branch=master)](https://travis-ci.org/dginev/LaTeXML-Plugin-latexmls)
[![license](http://img.shields.io/badge/license-Unlicense-blue.svg)](https://raw.githubusercontent.com/dginev/LaTeXML-Plugin-latexmls/master/LICENSE)

A socket server for daemonized LaTeXML processing

## Installation

Just another Perl module:
```
perl Makefile.PL ; make ; make test; sudo make install
```

Or ```cpanm latexmls```.

Make sure that LaTeXML has been installed prior to installing this Plugin, as well as all modules reported missing by Makefile.PL.

## Example use

See the main use pattern by the [latexmlc](https://github.com/brucemiller/LaTeXML/blob/master/bin/latexmlc#L123) executable of LaTeXML.
