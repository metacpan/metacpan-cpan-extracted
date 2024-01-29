# File::LoadLines

*This is the only module you'll ever need to read data*

![Version](https://img.shields.io/github/v/release/sciurius/perl-File-LoadLines)
![GitHub issues](https://img.shields.io/github/issues/sciurius/perl-File-LoadLines)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)

File::LoadLines provides an easy way to load the contents of a 
disk file or network resource into your program.

It can deliver the contents without touching (as a blob) but its most
useful purpose is to deliver the contents of text data into an array
of lines. Hence the name, File::LoadLines.

It automatically handles data encodings ASCII, Latin and UTF-8 text.
When the file has a BOM, it handles UTF-8, UTF-16 LE and BE, and
UTF-32 LE and BE.

Recognized line terminators are NL (Unix, Linux), CRLF (DOS, Windows)
and CR (Mac)

## SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-File-LoadLines.

You can find documentation for this module with the perldoc command.

    perldoc File::LoadLines

Please report any bugs or feature requests using the issue tracker on
GitHub.

## COPYRIGHT AND LICENCE

Copyright (C) 2018,2020,2023 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

