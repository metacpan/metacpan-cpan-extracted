# File-LoadLines

File-LoadLines provides an easy way to load the contents of a text
file into an array of lines.

It automatically handles ASCII, Latin and UTF-8 text.
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

Copyright (C) 2018,2020 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

