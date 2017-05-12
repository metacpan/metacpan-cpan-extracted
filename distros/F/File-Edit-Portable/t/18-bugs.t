#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use File::Edit::Portable;

{ # bug 35: recsep() with empty file handle

    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift; };

    my $rw = File::Edit::Portable->new;

    my $fh = $rw->read( 't/base/nothing.txt' );

    is ( $warn, undef,
        "recsep() does the right thing if file is empty on read()" );
}

done_testing();

