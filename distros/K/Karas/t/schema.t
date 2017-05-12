use strict;
use warnings;
use utf8;
use Test::More;
use DBD::SQLite;
use Karas;

{
    package My::Member;
    use parent qw/Karas::Row/;
}

subtest 'schema' => sub {
    my $db = Karas->new(
        connect_info => [
            'dbi:SQLite::memory:',
        ],
        row_class_map => {
            member => 'My::Member',
        },
    );
    is($db->get_row_class('member'), 'My::Member');
};

done_testing;

