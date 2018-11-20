# Games::Maze

## version 1.09

Create Mazes as Objects.

```perl
use Games::Maze;

my $m1 = Games::Maze->new(dimensions => [12,7,3]);
my $m2 = Games::Maze->new(dimensions => [8,5,2], cell => 'Hex');

$m1->make();

print scalar($m1->to_ascii());

$m1->solve();

print "\n\nThe Solution:\n\n", scalar($m1->to_ascii());
```

## INSTALLATION
The usual way.  Unpack the archive, then:

```sh
perl Build.PL
./Build
./Build test
./Build install
```

## COPYRIGHT AND LICENSE

Copyright (c) 2018 John M. Gamble.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

