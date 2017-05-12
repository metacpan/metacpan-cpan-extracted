use strict;
use Test::More;

use Email::Address::Loose;

my @ok = (
    ['miyagawa', 'miyagawa@cpan.org' ],
    ['rfc822.', 'rfc822.@docomo.ne.jp'],
    ['-everyone..-_-..annoyed-', '-everyone..-_-..annoyed-@docomo.ne.jp'],
    ['-aaaa', '-aaaa@foobar.ezweb.ne.jp'],
);

plan tests => @ok * 5;

for my $test (@ok) {
    my ($local, $address) = @$test;
    my @emails = Email::Address::Loose->parse($address);
    ok(@emails == 1, $address);
    
    my $email = shift @emails;
    isa_ok($email, 'Email::Address::Loose', "$address is a Email::Address::Loose");
    isa_ok($email, 'Email::Address',        "$address is a Email::Address");
    is($email->address, $address, "address()");
    is($email->user, $local, "user()");
}
