#!perl -T

use strict;
use warnings FATAL => 'all';

    use Test::More tests => 2;
    use JSON::Patch qw(diff patch);

    my $old = {foo => ['bar']};
    my $new = {foo => ['bar', 'baz']};

    my $patch = diff($old, $new);
    is_deeply(
        $patch,
        [
            {op => 'add', path => '/foo/1', value => 'baz'}
        ]
    );

    patch($old, $patch);
    is_deeply($old, $new);
