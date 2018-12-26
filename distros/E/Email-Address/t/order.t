use strict;
use warnings;

use Test::More;
use Email::Address;

my @emails = ( q{"foo" <foo@example.com>}, q{bar@example.com}, q{"baz" <baz@example.com>}, q{baz@example.com} );
my @addr = Email::Address->parse( join ', ', @emails );

is( scalar @addr, scalar @emails, "correct number of emails" );
is_deeply( \@addr, \@emails, 'correct order of emails' );

done_testing;
