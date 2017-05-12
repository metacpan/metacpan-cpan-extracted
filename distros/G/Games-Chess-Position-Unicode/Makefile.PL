#!/usr/bin/env perl
use strict;
use warnings;

use ExtUtils::MakeMaker;

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME          => 'Games::Chess::Position::Unicode',
    VERSION_FROM  => 'lib/Games/Chess/Position/Unicode.pm',
    ABSTRACT_FROM => 'lib/Games/Chess/Position/Unicode.pm',
    AUTHOR        => 'Sergey Romanov <sromanov@cpan.org>',
    PREREQ_PM     => {
        'Games::Chess' => 0.003,
        'Encode'       => 0,
    },
    ( $mm >= 6.31
        ? ( LICENSE => 'artistic_2' )
        : ()
    ),
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'https://github.com/sergeyromanov/games-chess-position-unicode',
                    bugtracker => 'https://github.com/sergeyromanov/games-chess-position-unicode/issues'
                },
                no_index => {directory => [qw/t/]},
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {},
                test_requires      => {
                    'Test::More'   => '0.47',
                },
            },
        )
    ),
    test => { TESTS => 't/*.t' }
);
