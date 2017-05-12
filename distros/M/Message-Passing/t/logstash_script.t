use strict;
use warnings;
use Test::More;

use_ok 'Message::Passing';

my $i = Message::Passing->new(
    input => 'STDIN',
    input_options => '{"foo":"bar"}',
    filter_options => '{"baz":"quux"}',
    output => 'Test',
    output_options => '{"x":"m"}',
);

is_deeply $i->input_options, {"foo" => "bar"};
is_deeply $i->filter_options, {"baz" => "quux"};
is_deeply $i->output_options, {"x" => "m"};

my $chain = $i->build_chain;
my $input = $chain->[0];
my $decoder = $input->output_to;
isa_ok $decoder, 'Message::Passing::Filter::Decoder::JSON';
my $filter = $decoder->output_to;
isa_ok $filter, 'Message::Passing::Filter::Null';
my $encoder = $filter->output_to;
isa_ok $encoder, 'Message::Passing::Filter::Encoder::JSON';
my $output = $encoder->output_to;
isa_ok $output, 'Message::Passing::Output::Test';
$filter->consume({ foo => "bar" });

is_deeply [$output->messages], ['{"foo":"bar"}'];

done_testing;

