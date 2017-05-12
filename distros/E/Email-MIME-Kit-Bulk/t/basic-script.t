use strict;
use warnings;

use Test::More tests => 2;

use Email::MIME::Kit::Bulk::Command;
use Email::Sender::Transport::Maildir;
use Path::Tiny qw/ tempdir /;

SKIP: {

my $maildir = tempdir() or skip "couldn't create temp directory" => 2;

# the forking makes using EST::Test difficult
my $transport = Email::Sender::Transport::Maildir->new( dir => $maildir );

# for the dev version
$Email::MIME::Kit::Bulk::VERSION ||= '0.0';

Email::MIME::Kit::Bulk::Command->new(
    kit  => 'examples/eg.mkit',
    from => 'me@here.com',
    transport => $transport,
    quiet => 1,
)->run;

my @msgs = $maildir->child('new')->children;

is @msgs => 2, '2 new emails';

my %email = map { $_->header('To') => $_ }
            map { Email::Simple->new( $_->slurp ) } 
                @msgs;

subtest "email 1 sent" => sub {
    my $email = $email{'someone@somewhere.com'};

    ok $email, "email is there";
    is $email->header('Subject') => 'Fantastic greetings', 'subject';
    like $email->header('X-UserAgent') => qr/Email::MIME::Kit::Bulk v\d+[\d.]+/, "user agent";
}

}
