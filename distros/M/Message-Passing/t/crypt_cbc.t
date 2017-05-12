use strict;
use warnings;
use Test::More;
use Try::Tiny;

plan skip_all => "No Crypt::CBC or no Crypt::Blowfish"
    unless try {
        require Message::Passing::Filter::Decoder::Crypt::CBC;
        require Crypt::Blowfish;
};

use_ok 'Message::Passing::Filter::Decoder::Crypt::CBC';
use_ok 'Message::Passing::Filter::Encoder::Crypt::CBC';
use_ok 'Message::Passing::Output::Test';
use_ok 'Message::Passing::Input::Null';
use_ok 'Message::Passing::Output::Null';

my $cbct = Message::Passing::Output::Test->new;
my $cbc = Message::Passing::Input::Null->new(
    output_to => Message::Passing::Filter::Encoder::Crypt::CBC->new(
        encryption_cipher => 'Blowfish',
        encryption_key => 'test',
        output_to => Message::Passing::Filter::Decoder::Crypt::CBC->new(
            output_to => $cbct,
            encryption_cipher => 'Blowfish',
            encryption_key => 'test',
        ),
    ),
);

$cbc->output_to->consume('test');
is $cbct->message_count, 1;
is_deeply [$cbct->messages], ['test'];

# Simulate dropping a message!
{
    local $cbc->output_to->{output_to} = Message::Passing::Output::Null->new;
    $cbc->output_to->consume('fooo');
}

$cbc->output_to->consume('bar');
is $cbct->message_count, 2;
is_deeply [$cbct->messages], ['test', 'bar'];

done_testing;

