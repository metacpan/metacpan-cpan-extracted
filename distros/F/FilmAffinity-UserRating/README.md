FilmAffinity::UserRating
========================

[![Build Status](https://travis-ci.org/williambelle/filmaffinity-userrating.svg?branch=master)](https://travis-ci.org/williambelle/filmaffinity-userrating)
[![Coverage Status](https://coveralls.io/repos/williambelle/filmaffinity-userrating/badge.svg?branch=master&service=github)](https://coveralls.io/github/williambelle/filmaffinity-userrating?branch=master)
[![CPAN Version](https://img.shields.io/cpan/v/FilmAffinity-UserRating.svg)](https://metacpan.org/release/FilmAffinity-UserRating)

Perl interface to FilmAffinity

Install
-------

Via CPAN with:

```bash
cpan install FilmAffinity::UserRating
```

Usage
-----

### Command Line

##### `filmaffinity-get-ratings.pl`

```console
filmaffinity-get-ratings.pl
Usage:
    filmaffinity-get-rating.pl --userid=123456

    filmaffinity-get-rating.pl --userid=123456 --delay=2

    filmaffinity-get-rating.pl --userid=123456 --output=/home/william/myvote.list

Options:
  --delay=3
    delay between requests

  --output=/home/william/rating.list
    output file
```

##### `filmaffinity-get-movie-info.pl`

```console
filmaffinity-get-movie-info.pl
Usage:
    filmaffinity-get-movie-info.pl --id=123456

    filmaffinity-get-movie-info.pl --id=123456 --delay=2

    filmaffinity-get-movie-info.pl --id=932476 --output=/home/william/matrix.json

Options:
  --delay=3
    delay between requests

  --output=/home/william/matrix.json
    output json file
```

##### `filmaffinity-get-all-info.pl`

```console
filmaffinity-get-all-info.pl
Usage:
    filmaffinity-get-all-info.pl --userid=123456 --destination=path/to/my/folder

    filmaffinity-get-all-info.pl --userid=123456 --destination=path/to/my/folder --delay=2

    filmaffinity-get-all-info.pl --userid=123456 --destination=path/to/my/folder --force

Options:
  --delay=3
    delay between requests

  --force
    force to retrieve all movies
```

### Module

```perl
use FilmAffinity::UserRating;

my $parser = FilmAffinity::UserRating->new( userID => '123456' );
my $ref_movies = $parser->parse();
```

Retrieve information about a filmaffinity movie

```perl
use FilmAffinity::Movie;

my $movie = FilmAffinity::Movie->new( id => '348488' );
$movie->parse();

my $title = $movie->title;
```

Contributing
------------

Contributions are always welcome.

See [Contributing](CONTRIBUTING.md).

Developer
---------

  * [William Belle](https://github.com/williambelle)

License
-------

Copyright (C) 2013-2018 William Belle

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
