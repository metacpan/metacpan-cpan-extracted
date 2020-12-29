# LaTeXML::Plugin::latexmls

[![Build Status](https://github.com/dginev/LaTeXML-Plugin-latexmls/workflows/CI/badge.svg)](https://github.com/dginev/LaTeXML-Plugin-latexmls/actions?query=workflow%3ACI)
[![license](http://img.shields.io/badge/license-Unlicense-blue.svg)](https://raw.githubusercontent.com/dginev/LaTeXML-Plugin-latexmls/master/LICENSE)
[![CPAN version](https://badge.fury.io/pl/LaTeXML-Plugin-latexmls.svg)](https://badge.fury.io/pl/LaTeXML-Plugin-latexmls)

A socket server for daemonized LaTeXML processing

## Installation

Just another Perl module:
```
perl Makefile.PL ; make ; make test; sudo make install
```

Or ```cpanm .```.

Make sure that LaTeXML has been installed prior to installing this Plugin, as well as all modules reported missing by Makefile.PL.

## Example use

See the main use pattern by the [latexmlc](https://github.com/brucemiller/LaTeXML/blob/master/bin/latexmlc#L123) executable of LaTeXML.
