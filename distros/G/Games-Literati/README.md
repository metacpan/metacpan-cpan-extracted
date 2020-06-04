# NAME

Games::Literati - For word games like Literati (or Scrabble, or Words With Friends), find the best-scoring solution(s) for a board and hand of tiles.

# SYNOPSIS

    use Games::Literati qw/:allGames/;
    literati();
    wordswithfriends();
    scrabble();
    superscrabble();

Example Windows-based one-liner:

    perl -MGames::Literati=literati -e "$Games::Literati::WordList = './mydict.txt'; literati();"

Example linux-based one-liner:

    perl -MGames::Literati=literati -e "$Games::Literati::WordList = '/usr/dict/words'; literati();"

# DESCRIPTION

**Games::Literati** helps you find out _all_ solutions for a given
board and tiles.  It can be used to play
[Scrabble](https://en.wikipedia.org/wiki/Scrabble) (the original 15x15 grid),
[Super Scrabble](https://en.wikipedia.org/wiki/Super_Scrabble) (the official 21x21 extended grid),
[Literati](http://internetgames.about.com/library/weekly/aa120802a.htm) (an old Yahoo! Games 15x15 grid, from which **Games::Literati** derives its name), and
[Words With Friends](https://www.zynga.com/games/words-friends) (a newer 15x15 grid).
By overriding or extending the package, one could implement other similar letter-tile grids,
with customizable bonus placements.

To use this module to play the games, a one-liner such as the
following can be used:

        perl -MGames::Literati=literati -e "literati();"

(This will only work if \``./wordlist`' is in the current directory.  Otherwise,
see ["PUBLIC VARIABLES"](#public-variables), below.)

Enter the data prompted then the best 10 solutions will be displayed.

# AUTHOR

Chicheng Zhang `<chichengzhang AT hotmail.com>` wrote the original code.

Peter C. Jones `<petercj AT cpan.org>` is the current maintainer, and
has added various features and made bug fixes.

<div>
    <a href="https://metacpan.org/pod/Games::Literati"><img src="https://img.shields.io/cpan/v/Games-Literati.svg?colorB=00CC00" alt="" title="metacpan"></a>
    <a href="http://matrix.cpantesters.org/?dist=Games-Literati"><img src="http://cpants.cpanauthors.org/dist/Games-Literati.png" alt="" title="cpan testers"></a>
    <a href="https://github.com/pryrt/Games-Literati/releases"><img src="https://img.shields.io/github/release/pryrt/Games-Literati.svg" alt="" title="github release"></a>
    <a href="https://github.com/pryrt/Games-Literati/issues"><img src="https://img.shields.io/github/issues/pryrt/Games-Literati.svg" alt="" title="issues"></a>
    <a href="https://ci.appveyor.com/project/pryrt/Games-Literati"><img src="https://ci.appveyor.com/api/projects/status/6gv0lnwj1t6yaykp/branch/master?svg=true" alt="" title="test coverage"></a>
    <a href="https://travis-ci.org/pryrt/Games-Literati"><img src="https://travis-ci.org/pryrt/Games-Literati.svg?branch=master" alt="travis build status" title="travis build status"></a>
    <a href='https://coveralls.io/github/pryrt/Games-Literati?branch=master'><img src='https://coveralls.io/repos/github/pryrt/Games-Literati/badge.svg?branch=master' alt='Coverage Status' title='Coverage Status' /></a>
</div>

# LICENSE AND COPYRIGHT

Copyright (c) 2003, Chicheng Zhang.  Copyright (C) 2016,2019,2020 by Peter C. Jones

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
