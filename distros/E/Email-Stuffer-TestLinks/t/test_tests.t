use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Builder;
use Test::Builder::Tester;
use Email::Stuffer;
use Email::Stuffer::TestLinks;
use Email::Sender::Transport::Test;

my $transport = Email::Sender::Transport::Test->new;

sub make_msg {
    my ($urls, $type) = @_;
    return 'There are no links in this message.' unless $urls;
    return join "\n", map { "This is a <a href=\"$_\">link</a>." } @$urls  if $type eq 'http';
    return join "\n", map { "This is an image: <img src=\"$_\">." } @$urls if $type eq 'image';
}

sub send_it {
    my $msg = shift;
    Email::Stuffer->from('sender@example.com')->to('recipient@example.org')->html_body($msg)->transport($transport)->send_or_die;
}

dies_ok { Email::Stuffer->from('sender@example.com')->send_or_die(); } "send_or_die can still die";

lives_ok { send_it(make_msg()); } "Email with no links";

test_out('ok 1 - http link works (http://www.google.com)');
send_it(make_msg(['http://www.google.com'], 'http'));
test_test('Validates http link');

test_out('ok 1 - http link works (https://www.google.com)');
send_it(make_msg(['https://www.google.com'], 'http'));
test_test('Validates https link');

test_out('whatever');    # can't validate test output because order is unpredictable
send_it(
    make_msg(['https://www.google.com', 'http://www.alibaba.com', 'https://www.cpan.org', 'https://wikipedia.com', 'https://yandex.ru/'], 'http'));
test_test(
    title    => 'Validates 5 mixed links',
    skip_out => 1
);

test_out('not ok 1 - http link xyz is an invalid uri');
test_out('not ok 2 - http link \#anchor is an invalid uri');
test_out('not ok 3 - http link /relative is an invalid uri');
send_it(make_msg(['xyz', '#anchor', '/relative'], 'http'));
test_test(
    title    => 'Fails for invalid uris',
    skip_err => 1
);

my $url_404 = 'https://www.google.com/04f7b5477df64f77b386e3a9aa1b9ff8';
test_out("not ok 1 - http link $url_404 does not work - Response code was 404");
send_it(make_msg([$url_404], 'http'));
test_test(
    title    => 'Fails for 404 url',
    skip_err => 1
);

test_out("not ok 1 - http link http://site.invalid does not work - site.invalid:80 - Name or service not known failed [-2]");
send_it(make_msg(['http://site.invalid'], 'http'));
test_test(
    title    => 'Fails for invalid name or service',
    skip_err => 1
);

test_out('ok 1 - http link works (https://www.google.com)');
send_it(make_msg(['https://www.google.com', 'https://www.google.com'], 'http'));
test_test('Only check duplicate urls once');

my $url_error = 'https://en.m.wikipedia.org/wiki/Error';
test_out("not ok 1 - http link $url_error does not work - Page title contains text 'Error'");
send_it(make_msg([$url_error], 'http'));
test_test(
    title    => "Fails for page with title containing 'error'",
    skip_err => 1
);

test_out("ok 1 - sent email ok");
lives_ok { send_it(make_msg(['mailto:someone@example.com'], 'http')) } "sent email ok";
test_test("mailto links are excluded");

test_out('ok 1 - http link works (https://www.google.com/favicon.ico)');
send_it(make_msg(['https://www.google.com/favicon.ico'], 'http'));
test_test('Validates image');

test_out('not ok 1 - image link https://www.google.com does not work - Unexpected content type: text/html');
send_it(make_msg(['https://www.google.com'], 'image'));
test_test(
    title    => 'Fails when wrong content type for image',
    skip_err => 1
);

done_testing;
