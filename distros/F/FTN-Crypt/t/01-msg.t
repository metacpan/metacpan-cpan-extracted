#!perl -T
use v5.10.1;
use strict;
use warnings;
use Test::Data qw/Array/;
use Test::LongString lcss => 0;
use Test::More;

plan tests => 23;

use FTN::Crypt::Msg;

my $msg_file = 't/data/msg.txt';
open my $fin, $msg_file or BAIL_OUT("Cannot open message file `$msg_file': $!");
binmode $fin;
my $msg = <$fin>;
close $fin;

# Test #1
my $ftn_address1 = '99:8877/1.0';
my $ftn_address2 = '99:8877/2.0';
my $obj = new_ok('FTN::Crypt::Msg', [
    Address => $ftn_address1,
    Message => $msg,
], 'Create FTN::Crypt::Msg object') or BAIL_OUT(FTN::Crypt::Msg->error);

# Test #2
can_ok($obj, qw/get_address set_address add_kludge remove_kludge get_kludges get_text set_text get_message set_message/)
    or BAIL_OUT('Required methods are unsupported by FTN::Crypt::Msg');

# Test #3
is($obj->get_address, $ftn_address1, 'Get FTN address #1') or diag($obj->error);

# Test #4
ok($obj->set_address($ftn_address2), 'Set FTN address') or diag($obj->error);

# Test #5
is($obj->get_address, $ftn_address2, 'Get FTN address #2') or diag($obj->error);

# Test #6
ok($obj->add_kludge('ENC: PGP5'), 'Add kludge') or diag($obj->error);

# Test #7
my $kludges1 = $obj->get_kludges;
isnt($kludges1, undef, 'Get kludges #1') or diag($obj->error);

# Test #8
is(ref $kludges1, 'ARRAY', 'Kludges list #1 is an array');

# Test #9
my @kludges_list_1 = ();
subtest 'Explore kludges list #1' => sub {
    plan tests => scalar(@{$kludges1});

    my $i = 1;
    foreach my $kl (@{$kludges1}) {
        is(ref $kl, 'ARRAY', "Sublist #$i from kludges list #1 is an array");
        push @kludges_list_1, @{$kl};
        $i++;
    }
    done_testing();
};

# Test #10
array_once_ok('ENC: PGP5', @kludges_list_1, 'Encryption kludge added');

# Test #11
ok($obj->remove_kludge('ENC'), 'Remove kludge') or diag($obj->error);

# Test #12
my $kludges2 = $obj->get_kludges;
isnt($kludges2, undef, 'Get kludges #2') or diag($obj->error);

# Test #13
is(ref $kludges2, 'ARRAY', 'Kludges list #2 is an array');

# Test #14
my @kludges_list_2 = ();
subtest 'Explore kludges list #2' => sub {
    plan tests => scalar(@{$kludges2});

    my $i = 1;
    foreach my $kl (@{$kludges2}) {
        is(ref $kl, 'ARRAY', "Sublist #$i from kludges list #2 is an array");
        push @kludges_list_2, @{$kl};
        $i++;
    }
    done_testing();
};

# Test #15
array_none_ok('ENC: PGP5', @kludges_list_2, 'Encryption kludge removed');

# Test #16
my $text1 = <<TEXT1;
First line
Second line
--- No Editor/0.0.1
 * Origin: Some origin (99:8877/1)
TEXT1
chomp $text1;
my $rcv_text1 = $obj->get_text;
isnt($rcv_text1, undef, 'Get text #1') or diag($obj->error);

# Test #17
is_string($rcv_text1, $text1, 'Text #1 is valid');

# Test #18
my $text2 = <<TEXT2;
First line
Second line
Thrid line
--- No Editor/0.0.1
 * Origin: Some origin (99:8877/1)
TEXT2
chomp $text2;
ok($obj->set_text($text2), 'Set text #2') or diag($obj->error);

# Test #19
my $rcv_text2 = $obj->get_text;
isnt($rcv_text2, undef, 'Get text #2') or diag($obj->error);

# Test #20
is_string($rcv_text2, $text2, 'Text #2 is valid');

# Test #21
ok($obj->set_message($msg), 'Set message') or diag($obj->error);

# Test #22
my $rcv_msg = $obj->get_message;
isnt($rcv_msg, undef, 'Get message') or diag($obj->error);

# Test #23
is_string($rcv_msg, $msg, 'Message is valid');
