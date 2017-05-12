use strict;
use warnings;

use Import::Box -as => 'ttt', 'Test2::Tools::Basic' => [qw/ok done_testing note/];
use Import::Box -as => 'ttt', 'Test2::Tools::Compare' => [qw/like is/];
use Import::Box(
    -as => 'ttt',
    'Test2::Tools::Exception' => [qw/dies/],
    'Test2::Tools::Warnings' => [qw/warns/],
);

ttt->ok(1, "ok works");

ttt is => ('a', 'a', 'is works');

ttt like => (
    'foo bar baz',
    qr/bar/,
    "like works"
);

ttt->ok(
    !ttt->warns(sub {
        ttt->like(
            ttt->dies(sub {die "this is an error xxx"}),
            qr/this is an error xxx/,
            "Called tool that takes code block prototype"
        ),
    }),
    "No warnings"
);

ttt note => "done_testing is next";
ttt->done_testing;
