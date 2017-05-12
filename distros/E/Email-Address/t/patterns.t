use Test::More;
use strict;
use warnings FATAL => 'all';

=for comment

 $Email::Address::addr_spec
     This regular expression defined what an email address is allowed to
     look like.

 $Email::Address::angle_addr
     This regular expression defines an $addr_spec wrapped in angle
     brackets.

 $Email::Address::name_addr
     This regular expression defines what an email address can look like
     with an optional preceeding display name, also known as the
     "phrase".

 $Email::Address::mailbox
     This is the complete regular expression defining an RFC 2822 emial
     address with an optional preceeding display name and optional
     following comment.

=cut

# tests (string, truth value)

my %tests = (
    mailbox => [
        [qw( foo                        0 )],
        [qw( foo@bar.com                1 )],
        [qw( bob@test.com.au            1 )],
        [qw( foo.bob@test.com.au        1 )],
        [qw( foo-bob@test-com.au        1 )],
        [qw( foo-bob@test.uk            1 )],
        [ 'Richard Sonnen <sonnen@frii.com>',               1 ],
        [ '<sonnen@frii.com>',                              1 ],
        [ '"Richard Sonnen" <sonnen@frii.com>',             1 ],
        [ '"Richard Sonnen" <sonnen@frii.com> (comments)',  1 ],
        [ '',                           0 ],
        [ 'foo',                        0 ],
        [ 'foo bar@bar.com',            0 ],
        [ '<foo bar>@bar.com',          0 ],
    ],
);

my $num_tests = scalar( map @{$_}, values %tests );

plan tests => $num_tests + 1;

use_ok 'Email::Address';

my %pats = map {
    my $pat;
    eval '$pat = $Email::Address::'.$_;
    ($_ => $pat);
} qw( addr_spec angle_addr name_addr mailbox );

for my $pattern_name (keys %tests) {
    for my $test (@{ $tests{$pattern_name} }) {
        my ($string, $expect_bool) = @{$test};
        my $result = $string =~ /^$pats{$pattern_name}$/;
        ok( $expect_bool ? $result : !$result , "pat $pattern_name: $string" );
    }
}
