use strict;
use warnings;

use Test::More 0.88;

use_ok 'Message::Passing::Filter::Encoder::JSON';
use_ok 'Message::Passing::Filter::Decoder::JSON';
use_ok 'Message::Passing::Output::Test';

{
    my $test = Message::Passing::Output::Test->new;
    my $test_e = Message::Passing::Output::Test->new;
    my $encoder = Message::Passing::Filter::Encoder::JSON->new(
        output_to => $test,
        error => $test_e,
    );
    $encoder->consume({ foo => bless {}, 'Bar' });
    is $test->message_count, 0;
    is $test_e->message_count, 1;
    my ($m) = $test_e->messages;
    #{"exception":"encountered object 'Bar=HASH(0x7fab21236f30)', but neither allow_blessed nor convert_blessed settings are enabled at /Users/t0m/perl5/perlbrew/perls/perl-5.16.0/lib/site_perl/5.16.0/JSON.pm line 154.\n","class":"Message::Passing::Exception::Encoding","stringified_data":"$VAR1 = {\n          'foo' => bless( {}, 'Bar' )\n        };\n"}
    $m = $m->as_hash;
    is ref($m), 'HASH';
    is $m->{'class'}, 'Message::Passing::Exception::Encoding';
    ok exists $m->{'exception'};
    ok exists $m->{'stringified_data'};
}
{
    my $test = Message::Passing::Output::Test->new;
    my $test_e = Message::Passing::Output::Test->new;
    my $decoder = Message::Passing::Filter::Decoder::JSON->new(
        output_to => $test,
        error => $test_e,
    );
    $decoder->consume("{}");
    is $test->message_count, 1;
    is $test_e->message_count, 0;
    $decoder->consume("{}sjdjd");
    is $test->message_count, 1;
    is $test_e->message_count, 1;
    my ($m) = $test_e->messages;
    $m = $m->as_hash;
    like $m->{exception}, qr/garbage after/;
    is $m->{packed_data}, '{}sjdjd';
    is $m->{class}, 'Message::Passing::Exception::Decoding';
}

done_testing;

