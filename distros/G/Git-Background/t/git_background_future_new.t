#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2021-2023 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Git::Background::Future;

note('new()');
{
    my $obj = Git::Background::Future->new;
    isa_ok( $obj, 'Git::Background::Future' );

    # This is wrong usage, but new() doesn't catch that. This test is only
    # to ensure this behavior doesn't change.
    ok( !defined $obj->udata('_run'), '... _run is not defined' );
}

note('new()');
{
    my $obj = Git::Background::Future->new('hello world');
    isa_ok( $obj, 'Git::Background::Future' );

    is( $obj->udata('_run'), 'hello world', '_run is set' );
}

#
done_testing();

exit 0;
