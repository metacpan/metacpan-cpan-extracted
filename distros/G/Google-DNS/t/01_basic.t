use strict;
use warnings;
use Test::More;

use Google::DNS;

can_ok 'Google::DNS', qw/new/;

if ($ENV{AUTHOR_TEST}) {
    my $resolver = Google::DNS->new;
    my $result = $resolver->data('google.com');
    note $result;
}

ok 1;

done_testing;
