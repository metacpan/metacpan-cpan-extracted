use strict;
use warnings;
use Test::Builder::Tester tests => 12;
use Test::Most;
use Email::Stuffer;
use Email::Stuffer::TestLinks;
use Email::Sender::Transport::Test;

my $transport = Email::Sender::Transport::Test->new;

sub make_msg {
    my @links = @_;
    return @_
        ? join "\n", map { "This is a <a href=\"$_\">link</a>." } @links
        : 'There are no links.';
}

sub make_teststr {
    my @links = @_;
    my $c     = 1;
    return join "\n", map { "ok " . $c++ . " - Link in email works ($_)" } sort @links;
}

sub send_it {
    my $msg = shift;
    Email::Stuffer->from('sender@example.com')->to('recipient@example.org')->html_body($msg)->transport($transport)->send_or_die;
}

my @urls = ();

dies_ok { Email::Stuffer->from('sender@example.com')->send_or_die(); } "send_or_die can still die";

lives_ok { send_it(make_msg(@urls)); } "Email with no links";

@urls = ('http://www.alibaba.com');
test_out(make_teststr(@urls));
send_it(make_msg(@urls));
test_test("Validates http link (@urls)");

@urls = ('https://www.google.com');
test_out(make_teststr(@urls));
send_it(make_msg(@urls));
test_test("Validates https link (@urls)");

@urls = ('https://www.google.com', 'http://www.alibaba.com', 'www.cpan.org', 'wikipedia.com', 'https://yandex.ru/');
test_out(make_teststr(@urls));
send_it(make_msg(@urls));
test_test("Validates 5 mixed links (@urls)");

@urls = ('https://www.google.com/04f7b5477df64f77b386e3a9aa1b9ff8');
test_out("not ok 1 - Link in email works ($urls[0])");
send_it(make_msg(@urls));
test_test(
    title    => "Fails for 404 link (@urls)",
    skip_err => 1
);

@urls = ('http://site.invalid');
test_out("not ok 1 - Link in email works ($urls[0])");
send_it(make_msg(@urls));
test_test(
    title    => "Fails for bad host (@urls)",
    skip_err => 1
);

@urls = ('@!*%/&');
test_out("not ok 1 - Link in email works ($urls[0])");
send_it(make_msg(@urls));
test_test(
    title    => "Fails for garbage url (@urls)",
    skip_err => 1
);

test_out(make_teststr('https://www.google.com'));
send_it(make_msg('https://www.google.com', 'https://www.google.com'));
test_test("Does not re-check duplicate URLs");

@urls = ('https://en.m.wikipedia.org/wiki/Error');
test_out("not ok 1 - Link in email works ($urls[0])");
send_it(make_msg(@urls));
test_test(
    title    => "Fails for page with title containing 'error' (@urls)",
    skip_err => 1
);

test_out("ok 1 - sent email ok");
lives_ok { send_it(make_msg(('mailto:someone@example.com'))) } "sent email ok";
test_test("mailto links are excluded");

@urls = ('#anchor', '/relative');
test_out("not ok 1 - Link in email works (\\\#anchor)");
test_out("not ok 2 - Link in email works (/relative)");
send_it(make_msg(@urls));
test_test(
    title    => "Fails for anchors and relative links (@urls)",
    skip_err => 1
);

