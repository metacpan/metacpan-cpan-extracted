use Test::More tests => 2 + 7*2;
BEGIN { $^W = 1 }
use strict;

my $module;
BEGIN {
    $module = 'List::Extract';

    require_ok($module);
    use_ok($module, 'extract');
}

###############################################################################

{
    my @list;
    my @extracted = extract { $_ & 1 } @list;
    is_deeply([ @extracted ], []);
    is_deeply([ @list ], []);
}
{
    my @list = 1;
    my @extracted = extract { $_ & 1 } @list;
    is_deeply([ @extracted ], [ 1 ]);
    is_deeply([ @list ], []);
}
{
    my @list = 2;
    my @extracted = extract { $_ & 1 } @list;
    is_deeply([ @extracted ], []);
    is_deeply([ @list ], [ 2 ]);
}
{
    my @list = 1 .. 10;
    my @extracted = extract { $_ & 1 } @list;
    is_deeply([ @extracted ], [ 1, 3, 5, 7, 9 ]);
    is_deeply([ @list ], [ 2, 4, 6, 8, 10 ]);
}
{
    my @list = 1 .. 10;
    my @extracted = extract { not $_ & 1 } @list;
    is_deeply([ @extracted ], [ 2, 4, 6, 8, 10 ]);
    is_deeply([ @list ], [ 1, 3, 5, 7, 9 ]);
}
{
    my @list = 1 .. 10;
    my @extracted = extract { 1 } @list;
    is_deeply([ @extracted ], [ 1 .. 10 ]);
    is_deeply([ @list ], []);
}

{
    my @list = qw/ $foo bar $baz /;
    my @extracted = extract { s/^\$// } @list;
    is_deeply([ @extracted ], [qw/ foo baz /]);
    is_deeply([ @list ], [qw/ bar /]);
}
