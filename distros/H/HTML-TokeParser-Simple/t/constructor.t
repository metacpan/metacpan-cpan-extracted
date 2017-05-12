#!/usr/bin/perl -w
use strict;
use warnings;
use Sub::Override;
use Test::More tests => 15; 
my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'HTML::TokeParser::Simple';
    use_ok($CLASS) || die;
}

can_ok($CLASS, 'new');

eval { $CLASS->new(unknown_source_type => 'asdf') };
like(
    $@,
    qr/^Unknown source type \(unknown_source_type\)/,
    '... and calling it with an unknown source type should croak()');

my $test_html_file = 'data/test.html';
ok(my $parser = $CLASS->new(file => $test_html_file),
    '... we should be able to specify a filename with the constructor');
isa_ok($parser, $CLASS);

my $token = $parser->get_tag('body');
is_deeply( 
    $token->get_attr,
    { alink => "#0000ff",  bgcolor => "#ffffff" },
    '... and it should be able to parse the file');

undef $parser;

open FILE, '<', $test_html_file
    or die "Cannot open ($test_html_file) for reading: $!";
ok($parser = $CLASS->new(handle => \*FILE),
    '... we should be able to specify a filehandle with the constructor');
isa_ok($parser, $CLASS);

$token = $parser->get_tag('body');
is_deeply( 
    $token->get_attr,
    { alink => "#0000ff",  bgcolor => "#ffffff" },
    '... and it should be able to parse the file');

my $html = '<p><a href="foo.html"></p>';
ok($parser = $CLASS->new(string => $html),
    '... we should be able to specify a string with the constructor');
isa_ok($parser, $CLASS);

$token = $parser->get_tag('a');
is_deeply( 
    $token->get_attr,
    { href => "foo.html" },
    '... and it should be able to parse the file');

eval "require LWP::Simple";

SKIP: {
    skip "Cannot load LWP::Simple", 3 if $@;
    my $override = Sub::Override->new(
        'LWP::Simple::get' => sub($) { return '<p><a href="bar.html"></p>' }
    );
    ok($parser = $CLASS->new(url => 'http://bogus.url'),
        '... we should be able to specify a URL with the constructor');
    $token = $parser->get_tag('a');
    is_deeply( 
        $token->get_attr,
        { href => "bar.html" },
        '... and it should be able to parse the file');
    $override->restore;
    $override = Sub::Override->new(
        'LWP::Simple::get' => sub($) { undef }
    );
    eval { $CLASS->new(url => 'http://bogus.url') };
    like(
        $@,
        qr{\QCould not fetch content from (http://bogus.url)\E},
        '... but the URL constructor should croak if we cannot fetch the content');
}
