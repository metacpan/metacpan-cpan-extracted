use strict;
use warnings;
use Test::More tests => 4;

use Log::Handler::Output::Sendmail;

ok(1, "use ok");

$Log::Handler::Output::Sendmail::TEST = 1;

my $email = Log::Handler::Output::Sendmail->new(
    from    => 'bar@foo.example',
    to      => 'foo@bar.example',
    subject => 'foo',
);

$email->log(message => "b");
$email->log(message => "a");
$email->log(message => "r");

ok($email->{subject} eq "foo", "checking subject ($email->{subject})");
ok($email->{message} eq "bar", "checking buffer ($email->{message})");

$email->reload(
    {
        from    => 'bar@foo.example',
        to      => 'foo@bar.example',
        subject => 'baz',
    }
);

ok($email->{subject} eq "baz", "checking reload ($email->{subject})");
