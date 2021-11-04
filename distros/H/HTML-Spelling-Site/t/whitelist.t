#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use HTML::Spelling::Site::Whitelist ();

{
    my $obj = HTML::Spelling::Site::Whitelist->new(
        {
            filename => './t/data/whitelist-with-duplicates.txt',
        }
    );

    # TEST
    is_deeply(
        $obj->get_sorted_text,
        <<'EOF',
==== GLOBAL:

Shlomi
Yonathan
EOF
        'Duplicates are removed',
    );
}

{
    # TEST
    is(
        scalar(
            HTML::Spelling::Site::Whitelist::_rec_sorter(
                [qw# a/b.html a/c.html #], [qw# a/b.html a/c.html #], 0,
            )
        ),
        0,
        "Comparator returns 0 upon tie.",
    );
}

{
    my $obj = HTML::Spelling::Site::Whitelist->new(
        {
            filename => './t/data/whitelist-with-dup-records.txt',
        }
    );

    # TEST
    is_deeply(
        $obj->get_sorted_text,
        <<'EOF',
==== GLOBAL:

Shlomi
Yonathan

==== In: dest/a.html , dest/b.html

worde

==== In: dest/a.html , dest/b.html , dest/c.html

worda
wordb
wordc
wordd
EOF
        'Duplicates are removed',
    );
}
