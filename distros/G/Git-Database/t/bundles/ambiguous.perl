use strict;
use warnings;
use DateTime;

use Git::Database::Actor;
use Git::Database::DirectoryEntry;

# test data as hash ref
{

    blob => [
        {
            desc    => 'First 577ecc blob (from git.git)',
            digest  => '577ecc210a55a5da10552a4415c4cbb5e321039b',
            content => "#!/bin/sh\n#\n# Copyright (c) 2005 Junio C Hamano\n#\n\ntest_description='git mailinfo and git mailsplit test'\n\n. ./test-lib.sh\n\ntest_expect_success 'split sample box' \\\n\t'git mailsplit -o. ../t5100/sample.mbox >last &&\n\tlast=`cat last` &&\n\techo total is \$last &&\n\ttest `cat last` = 9'\n\nfor mail in `echo 00*`\ndo\n\ttest_expect_success \"mailinfo \$mail\" \\\n\t\t\"git mailinfo -u msg\$mail patch\$mail <\$mail >info\$mail &&\n\t\techo msg &&\n\t\tdiff ../t5100/msg\$mail msg\$mail &&\n\t\techo patch &&\n\t\tdiff ../t5100/patch\$mail patch\$mail &&\n\t\techo info &&\n\t\tdiff ../t5100/info\$mail info\$mail\"\ndone\n\ntest_expect_success 'respect NULs' '\n\n\tgit mailsplit -d3 -o. ../t5100/nul-plain &&\n\tcmp ../t5100/nul-plain 001 &&\n\t(cat 001 | git mailinfo msg patch) &&\n\ttest 4 = \$(wc -l < patch)\n\n'\n\ntest_expect_success 'Preserve NULs out of MIME encoded message' '\n\n\tgit mailsplit -d5 -o. ../t5100/nul-b64.in &&\n\tcmp ../t5100/nul-b64.in 00001 &&\n\tgit mailinfo msg patch <00001 &&\n\tcmp ../t5100/nul-b64.expect patch\n\n'\n\ntest_done\n",
        },
        {
            desc    => 'Second 577ecc blob (from git.git)',
            digest  => '577eccaacd6343158463f9eaefa19dec78358437',
            content => "Git v1.7.11.1 Release Notes\n===========================\n\nFixes since v1.7.11\n-------------------\n\n * The cross links in the HTML version of manual pages were broken.\n\nAlso contains minor typofixes and documentation updates.\n",
        },
    ],
    tree => [
        {
            digest  => '65237d4ff8bddefebb2d4801e796f94fa9a9bbeb',
            content => "100644 file1\0W~\314!\nU\245\332\20U*D\25\304\313\265\343!\3\233100644 file2\0W~\314\252\315cC\25\204c\371\352\357\241\235\354x5\2047",
            directory_entries => [
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'file1',
                    digest   => '577ecc210a55a5da10552a4415c4cbb5e321039b',
                ),
                Git::Database::DirectoryEntry->new(
                    mode     => '100644',
                    filename => 'file2',
                    digest   => '577eccaacd6343158463f9eaefa19dec78358437',
                ),
            ],
            string  => "100644 blob 577ecc210a55a5da10552a4415c4cbb5e321039b\tfile1\n100644 blob 577eccaacd6343158463f9eaefa19dec78358437\tfile2\n",
        },
    ],
    commit => [
        {
            digest  => '9f0363e979a368db9748fb93278ab91a2152aa71',
            commit_info => {
                tree_digest => '65237d4ff8bddefebb2d4801e796f94fa9a9bbeb',
                parents_digest => [
                ],
                author => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org',
                ),
                author_date => DateTime->from_epoch(
                    epoch     => 1472317761,
                    time_zone => '+0200',
                ),
                committer => Git::Database::Actor->new(
                    name  => 'Philippe Bruhat (BooK)',
                    email => 'book@cpan.org',
                ),
                committer_date => DateTime->from_epoch(
                    epoch     => 1472317761,
                    time_zone => '+0200',
                ),
                comment  => "The tree attached to this commit points to two blobs will ambiguous short SHA1",
                encoding => 'utf-8',
            },
            content => << 'COMMIT',
tree 65237d4ff8bddefebb2d4801e796f94fa9a9bbeb
author Philippe Bruhat (BooK) <book@cpan.org> 1472317761 +0200
committer Philippe Bruhat (BooK) <book@cpan.org> 1472317761 +0200

The tree attached to this commit points to two blobs will ambiguous short SHA1
COMMIT
        },
    ],
    refs => {
        'HEAD' => '9f0363e979a368db9748fb93278ab91a2152aa71',
        'refs/heads/master' => '9f0363e979a368db9748fb93278ab91a2152aa71',
        'refs/remotes/origin/HEAD' => '9f0363e979a368db9748fb93278ab91a2152aa71',
        'refs/remotes/origin/master' => '9f0363e979a368db9748fb93278ab91a2152aa71',
    },
}
