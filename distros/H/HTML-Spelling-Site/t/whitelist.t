#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use HTML::Spelling::Site::Whitelist;

{
    my $obj = HTML::Spelling::Site::Whitelist->new(
        {
            filename => './t/data/whitelist-with-duplicates.txt',
        }
    );

    # TEST
    is_deeply($obj->get_sorted_text,
        <<'EOF',
==== GLOBAL:

Shlomi
Yonathan
EOF
        'Duplicates are removed',
    );
}

