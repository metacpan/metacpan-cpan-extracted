use strict;
use warnings;

use Test::More;
use Test::Exception;
use Try::Tiny;
use FindBin qw($Bin);
use Path::Tiny;

BEGIN {
    use_ok('Email::Folder::Search');
}

my $folder_path = '/tmp/default.mailbox';

my $mailbox = Email::Folder::Search->new($folder_path, timeout => 0);
$mailbox->init;
my $address = 'test@test.com';
my $subject = "test mail sender";
my $body    = "hello, this is just for test";

send_email();
#test arguments
throws_ok { $mailbox->search() } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->search(email => $address) } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->search(email => $address, subject => $subject) } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->search(subject => qr/$subject/) } qr/Need email address and subject regexp/, 'test arguments';
my @msgs;
lives_ok { @msgs = $mailbox->search(email => 'nosuch@email.com', subject => qr/hello/) } 'get email';
ok { !@msgs, "get a blank message" };

lives_ok { @msgs = $mailbox->search(email => $address, subject => qr/$subject/) } 'get email';
like($msgs[0]{body}, qr/$body/, 'get correct email');
$mailbox->clear();
ok(-z $folder_path, "mailbox truncated");

{
    $mailbox->{timeout} = 3;
    local $SIG{ALRM} = sub { send_email(); send_email(); };
    alarm(2);
    lives_ok { @msgs = $mailbox->search(email => $address, subject => qr/$subject/) } 'will wait "timeout" secouds for new email';
    is(scalar(@msgs), 2, "got 2 mails");
}

done_testing;

sub send_email {
    path($folder_path)->append_utf8(path("$Bin/test.mailbox")->lines_utf8);
}
