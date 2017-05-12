use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Message::Passing::Input::Null;
use Message::Passing::Output::Test;

plan skip_all => "No IO::Compress"
    unless try { require Message::Passing::Filter::Decoder::Bzip2; require Message::Passing::Filter::Encoder::Gzip };

use_ok 'Message::Passing::Filter::Decoder::Bzip2';
use_ok 'Message::Passing::Filter::Encoder::Bzip2';
use_ok 'Message::Passing::Filter::Encoder::Gzip';
use_ok 'Message::Passing::Filter::Decoder::Gzip';

my $gzt = Message::Passing::Output::Test->new;
my $gz = Message::Passing::Input::Null->new(
    output_to => Message::Passing::Filter::Encoder::Gzip->new(
        output_to => Message::Passing::Filter::Decoder::Gzip->new(
            output_to => $gzt,
        ),
    ),
);

$gz->output_to->consume('test');
is $gzt->message_count, 1;
is_deeply [$gzt->messages], ['test'];

my $bzt = Message::Passing::Output::Test->new;
my $bz = Message::Passing::Input::Null->new(
    output_to => Message::Passing::Filter::Encoder::Gzip->new(
        output_to => Message::Passing::Filter::Decoder::Gzip->new(
            output_to => $bzt,
        ),
    ),
);

$bz->output_to->consume('test');
is $bzt->message_count, 1;
is_deeply [$bzt->messages], ['test'];

done_testing;

