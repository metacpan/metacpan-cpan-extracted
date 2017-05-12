use Test::More tests => 8;
use strict;

use Email::Send;
use Email::Send::Test::DataDumper;
use Email::Simple;
use File::Spec::Functions;
use File::Temp qw(tempdir);

{   
    my $file = catfile(tempdir(DIR => 't', CLEANUP => 1), 'sentmail');
    my $message = Email::Simple->new(<<'__MESSAGE__');
To: me@myhost.com
From: you@yourhost.com
Subject: Test

Testing this thing out.
__MESSAGE__

    local $Email::Send::Test::DataDumper::FILENAME = $file;
    for (0 .. 1) {
        Email::Send->new({mailer => 'Test::DataDumper', mailer_args => [$file, 1, 2]})
        ->send($message);

        my ($deliveries) = Email::Send::Test::DataDumper->deliveries;
        my $test_message = $deliveries->[1];
        is_deeply(
            $deliveries->[2],
            [$file, 1, 2],
            "args passed in properly",
        );
        isa_ok $test_message, 'Email::Simple';

        is $test_message->as_string, $message->as_string, 'sent properly';
        Email::Send::Test::DataDumper->clear;
        my @emails = Email::Send::Test::DataDumper->emails;
        is scalar @emails, 0;
    }
}
