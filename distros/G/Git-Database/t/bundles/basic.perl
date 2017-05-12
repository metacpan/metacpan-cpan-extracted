use strict;
use warnings;
use DateTime;

use Git::Database::Actor;
use Git::Database::DirectoryEntry;

# test data as hash ref
{
    blob => [
        {   desc    => 'hello blob',
            content => 'hello',
            digest  => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0',
        },
    ],
    tree => [
        {   desc              => 'hello tree',
            directory_entries => [
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'hello',
                    digest   => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'
                )
            ],
            content =>
                "100644 hello\0\266\374Lb\13g\331_\225:\\\34\0220\252\253]\265\241\260",
            string =>
                "100644 blob b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0\thello\n",
            digest => 'b52168be5ea341e918a9cbbb76012375170a439f',
        },
        {   desc              => 'tree with subtree',
            directory_entries => [
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'hello',
                    digest   => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'
                ),
                Git::Database::DirectoryEntry->new(
                    mode     => '40000',
                    filename => 'subdir',
                    digest   => 'b52168be5ea341e918a9cbbb76012375170a439f'
                ),
            ],
            content =>
                "100644 hello\0\266\374Lb\13g\331_\225:\\\34\0220\252\253]\265\241\26040000 subdir\0\265!h\276^\243A\351\30\251\313\273v\1#u\27\nC\237",
            string =>
                "100644 blob b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0\thello\n040000 tree b52168be5ea341e918a9cbbb76012375170a439f\tsubdir\n",
            digest => '71ff52fcd190c0a900fffad2ecf2f678554602b6',
        },
        {   desc => 'tree with subtree (unsorted directory_entries)',
            directory_entries => [
                Git::Database::DirectoryEntry->new(
                    mode     => '40000',
                    filename => 'subdir',
                    digest   => 'b52168be5ea341e918a9cbbb76012375170a439f'
                ),
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'hello',
                    digest   => 'b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0'
                ),
            ],
            content =>
                "100644 hello\0\266\374Lb\13g\331_\225:\\\34\0220\252\253]\265\241\26040000 subdir\0\265!h\276^\243A\351\30\251\313\273v\1#u\27\nC\237",
            string =>
                "100644 blob b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0\thello\n040000 tree b52168be5ea341e918a9cbbb76012375170a439f\tsubdir\n",
            digest => '71ff52fcd190c0a900fffad2ecf2f678554602b6',
        },
    ],
    commit => [
        {   desc        => 'hello commit',
            commit_info => {
                tree_digest => 'b52168be5ea341e918a9cbbb76012375170a439f',
                author      => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org'
                ),
                author_date => DateTime->from_epoch(
                    epoch     => 1352762713,
                    time_zone => '+0100'
                ),
                committer => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org'
                ),
                committer_date => DateTime->from_epoch(
                    epoch     => 1352764647,
                    time_zone => '+0100'
                ),
                comment  => 'hello',
                encoding => 'utf-8',
            },
            content => << 'COMMIT',
tree b52168be5ea341e918a9cbbb76012375170a439f
author Philippe Bruhat (BooK) <book@cpan.org> 1352762713 +0100
committer Philippe Bruhat (BooK) <book@cpan.org> 1352764647 +0100

hello
COMMIT
            digest => 'ef25e81ba86b7df16956c974c8a9c1ff2eca1326',
        },
        {   desc        => 'commit with a parent',
            commit_info => {
                tree_digest => '71ff52fcd190c0a900fffad2ecf2f678554602b6',
                parents_digest =>
                    ['ef25e81ba86b7df16956c974c8a9c1ff2eca1326'],
                author => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org'
                ),
                author_date => DateTime->from_epoch(
                    epoch     => 1352766313,
                    time_zone => '+0100'
                ),
                committer => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org'
                ),
                committer_date => DateTime->from_epoch(
                    epoch     => 1352766360,
                    time_zone => '+0100'
                ),
                comment  => 'say hi to parent!',
                encoding => 'utf-8',
            },
            content => << 'COMMIT',
tree 71ff52fcd190c0a900fffad2ecf2f678554602b6
parent ef25e81ba86b7df16956c974c8a9c1ff2eca1326
author Philippe Bruhat (BooK) <book@cpan.org> 1352766313 +0100
committer Philippe Bruhat (BooK) <book@cpan.org> 1352766360 +0100

say hi to parent!
COMMIT
            digest => '3a4098405fa5a807b2306e345dda70d33d229c91',
        },
        {   desc        => 'a merge',
            commit_info => {
                tree_digest    => '71ff52fcd190c0a900fffad2ecf2f678554602b6',
                parents_digest => [
                    '3a4098405fa5a807b2306e345dda70d33d229c91',
                    'ef25e81ba86b7df16956c974c8a9c1ff2eca1326',
                ],
                author => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org'
                ),
                author_date => DateTime->from_epoch(
                    epoch     => 1358247404,
                    time_zone => '+0100'
                ),
                committer => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org'
                ),
                committer_date => DateTime->from_epoch(
                    epoch     => 1358247404,
                    time_zone => '+0100'
                ),
                comment  => 'a merge',
                encoding => 'utf-8',
            },
            content => << 'COMMIT',
tree 71ff52fcd190c0a900fffad2ecf2f678554602b6
parent 3a4098405fa5a807b2306e345dda70d33d229c91
parent ef25e81ba86b7df16956c974c8a9c1ff2eca1326
author Philippe Bruhat (BooK) <book@cpan.org> 1358247404 +0100
committer Philippe Bruhat (BooK) <book@cpan.org> 1358247404 +0100

a merge
COMMIT
            digest => '9d94853f1733007321288974bce2cec5bb07a6df',
        },
    ],
    tag => [
        {   desc     => 'world tag',
            tag_info => {
                object => 'ef25e81ba86b7df16956c974c8a9c1ff2eca1326',
                type   => 'commit',
                tag    => 'world',
                tagger => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org'
                ),
                tagger_date => DateTime->from_epoch(
                    epoch     => 1352846959,
                    time_zone => '+0100'
                ),
                comment  => 'bonjour',
            },
            content => << 'TAG',
object ef25e81ba86b7df16956c974c8a9c1ff2eca1326
type commit
tag world
tagger Philippe Bruhat (BooK) <book@cpan.org> 1352846959 +0100

bonjour
TAG
            digest => 'f5c10c1a841419d3b1db0c3e0c42b554f9e1eeb2',
        }
    ],
    refs => {
        'HEAD' => '9d94853f1733007321288974bce2cec5bb07a6df',
        'refs/heads/master' => '9d94853f1733007321288974bce2cec5bb07a6df',
        'refs/remotes/origin/HEAD' => '9d94853f1733007321288974bce2cec5bb07a6df',
        'refs/remotes/origin/master' => '9d94853f1733007321288974bce2cec5bb07a6df',
        'refs/tags/world' => 'f5c10c1a841419d3b1db0c3e0c42b554f9e1eeb2',
    },
};
