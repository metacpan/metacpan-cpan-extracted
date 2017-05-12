use strict;
use warnings;

use Test::More tests => 2;
use Test::Fork;

use Media::Type::Simple qw/type_from_ext/;

{
    my $pid = fork_ok(
        1,
        sub {
            is(type_from_ext( 'jpg' ), 'image/jpeg', 'RT 4674');
        });
}



