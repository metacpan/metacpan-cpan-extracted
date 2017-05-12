use strict;
use warnings;
use Test::More 0.88;

use Message::Passing::Input::STDIN;

my $i = Message::Passing::Input::STDIN->new(
    output_to => {
        class => 'Message::Passing::Output::Test',
    },
);

ok $i;
isa_ok($i->output_to, 'Message::Passing::Output::Test');

done_testing;

