# Mesoderm

Generate DBIx::Class classes using Moose

Mesoderm creates a scaffold of code for [DBIx::Class](http://search.cpan.org/perldoc?DBIx::Class) using a schema
object from [SQL::Translator](http://github.com/arcanez/SQL-Translator).

Currently the version of SQL::Translator required is not available on CPAN and must be
fetched directly from github http://github.com/arcanez/SQL-Translator

There are many other scaffold generators around. Mesoderm attempts
to bring some of the best features from those along with some new features.

## Features

  * All generated code is in a single file
  * Generated code is in a predicatable order, so diffs are easily readable
  * Separation between generated code and user written code
  * User code is written as [Moose::Role](http://search.cpan.org/perldoc?Moose::Role) classes
  * Complete control over class and relationship names
  * Ability to have class model exclude any table, column or relationship

## License

This software is copyright (c) 2010-2011 by Graham Barr <gbarr@pobox.com>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


