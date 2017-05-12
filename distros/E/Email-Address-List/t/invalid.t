use strict; use warnings;
use Test::More tests => 4;
use_ok 'Email::Address::List';

run_test('root', [{type => 'unknown', value => 'root'}]);
run_test(
    'boo@boo, root, foo@foo',
    [
        {type => 'mailbox', value => 'boo@boo', obsolete => 0, not_ascii => 0},
        {type => 'unknown', value => 'root'},
        {type => 'mailbox', value => 'foo@foo', obsolete => 0, not_ascii => 0},
    ],
);
run_test(
    '"Doe, John" foo@foo, root',
    [
        {type => 'unknown', value => '"Doe, John" foo@foo' },
        {type => 'unknown', value => 'root'},
    ],
);

sub run_test {
    my $line = shift;
    my @list = Email::Address::List->parse($line);
    $_->{'value'} .= '' foreach grep defined $_->{'value'}, @list;
    is_deeply( \@list, shift );
}

