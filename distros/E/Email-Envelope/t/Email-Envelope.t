use Test::More tests => 54;
use strict;
use warnings;
use Email::Simple;

BEGIN { use_ok('Email::Envelope') };
sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }

my $mailnofold = Email::Simple->new(read_file("t/mail/josey-nofold"))->as_string; 
my $mailfold   = Email::Simple->new(read_file("t/mail/josey-fold"))->as_string; 

# Test setting values with hashref
my $emailenv = Email::Envelope->new({
    remote_host => '127.0.0.1',
    remote_port => 8888,
    local_host  => '127.0.0.1',
    local_port  => 9999,
    secure      => 1,
    rcpt_to     => "Example User <user\@example.com>",
    mail_from   => "Another User <another\@example.com>",
    helo        => "HELO mx.example.com",
    data        => read_file("t/mail/josey-nofold"),
    mta_msg_id  => "foobar1234567890",
    recieved_timestamp => 1107115785
});

can_ok("Email::Envelope", qw(
    new remote_host remote_port local_host local_port
    secure rcpt_to mail_from helo data simple to_address
    from_address mta_msg_id recieved_timestamp
));
isa_ok($emailenv, "Email::Envelope");

is($emailenv->remote_host, '127.0.0.1', "remote_host set hashref");
is($emailenv->remote_port, 8888, "remote_port set hashref");

is($emailenv->local_host, '127.0.0.1', "local_host set hashref");
is($emailenv->local_port, 9999, "local_port set hashref");

is($emailenv->secure, 1, "secure set hashref");

is($emailenv->rcpt_to, "Example User <user\@example.com>", "rcpt_to set hashref");
is($emailenv->mail_from, "Another User <another\@example.com>", "mail_from set hashref");
is($emailenv->helo, "HELO mx.example.com", "helo set hashref");
is($emailenv->data, $mailnofold, "data set hashref");

is($emailenv->mta_msg_id, "foobar1234567890", "mta_msg_id set hashref");
is($emailenv->recieved_timestamp, 1107115785, "recieved_timestamp set hashref");

# Test setting values with accessors
is($emailenv->remote_host('mx.example.org'), 'mx.example.org', "remote_host set accessor");
is($emailenv->remote_host, 'mx.example.org', "remote_host get accessor");
is($emailenv->remote_port(7777), 7777, "remote_port set accessor");
is($emailenv->remote_port, 7777, "remote_port get accessor");

is($emailenv->local_host('mx.example.net'), 'mx.example.net', "local_host set accessor");
is($emailenv->local_host, 'mx.example.net', "local_host get accessor");
is($emailenv->local_port(6666), 6666, "local_port set accessor");
is($emailenv->local_port, 6666, "local_port get accessor");

is($emailenv->secure(0), 0, "secure set accessor");
is($emailenv->secure, 0, "secure get accessor");

is($emailenv->rcpt_to("Example Foo <foo\@example.com>"), "Example Foo <foo\@example.com>", "rcpt_to set accessor");
is($emailenv->rcpt_to, "Example Foo <foo\@example.com>", "rcpt_to get accessor");
is($emailenv->mail_from("Example Bar <bar\@example.com>"), "Example Bar <bar\@example.com>", "mail_from set accessor");
is($emailenv->mail_from, "Example Bar <bar\@example.com>", "mail_from get accessor");
is($emailenv->helo("HELO mx.example.net"), "HELO mx.example.net", "helo set accessor");
is($emailenv->helo, "HELO mx.example.net", "helo get accessor");
is($emailenv->data(read_file('t/mail/josey-fold')), $mailfold, "data set accessor");
is($emailenv->data, $mailfold, "data get accessor");

is($emailenv->mta_msg_id("foobar0987654321"), "foobar0987654321", "mta_msg_id set accessor");
is($emailenv->mta_msg_id, "foobar0987654321", "mta_msg_id get accessor");
is($emailenv->recieved_timestamp(1107115985), 1107115985, "recieved_timestamp set accessor");
is($emailenv->recieved_timestamp, 1107115985, "recieved_timestamp get accessor");

# Test for Email::Address and Email::Simple objects
isa_ok($emailenv->simple, "Email::Simple");
isa_ok($emailenv->to_address, "Email::Address");
isa_ok($emailenv->from_address, "Email::Address");

# check for correct values
eval { $emailenv->remote_host('2idks8u3kjd'); };
like($@, qr/Incorrect IP address or FQDN .*/, "check for remote_host bad value");

eval { $emailenv->remote_port('wjdfhsakjdh'); };
like($@, qr/Incorrect port number .*/, "check for remote_port bad value (non-int)");
eval { $emailenv->remote_port(-25); };
like($@, qr/Incorrect port number .*/, "check for remote_port bad value (low range)");
eval { $emailenv->remote_port(9999999999); };
like($@, qr/Incorrect port number .*/, "check for remote_port bad value (high range)");

eval { $emailenv->local_host('2idks8u3kjd'); };
like($@, qr/Incorrect IP address or FQDN .*/, "check for local_host bad value");

eval { $emailenv->local_port('kasjdhskaj'); };
like($@, qr/Incorrect port number .*/, "check for local_port bad value (non-int)");
eval { $emailenv->local_port(-25); };
like($@, qr/Incorrect port number .*/, "check for local_port bad value (low range)");
eval { $emailenv->local_port(9999999999); };
like($@, qr/Incorrect port number .*/, "check for local_port bad value (high range)");

eval { $emailenv->recieved_timestamp('jhdfkjhdkjsdbf'); };
like($@, qr/Incorrect timestamp .*/, "check for recieved_timestamp bad value");


# check for correct usage of Email::Address
$emailenv->mail_from("Example Nut <foo\@example.com>, Another Nut <nuts\@example.com");
is($emailenv->mail_from, "Example Nut <foo\@example.com>", "only one address per MAIL_FROM");

$emailenv->rcpt_to("Example Person <person\@example.com>, Perl Nut <perl\@example.com>, Baka <baka\@example.com>");
my @foobarbaz = $emailenv->to_address;
is(scalar(@foobarbaz), 3, "3 addresses");
foreach($emailenv->to_address){
    isa_ok($_, "Email::Address");
}

isa_ok($emailenv->to_address, "Email::Address");

