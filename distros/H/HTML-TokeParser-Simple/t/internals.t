
#!/usr/bin/perl -w
use strict;
use warnings;
use Sub::Override;
use Test::More tests => 16; 
my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'HTML::TokeParser::Simple';
    use_ok($CLASS) || die;
}

my $test_html_file = 'data/test.html';
my $parser1 = $CLASS->new(file => $test_html_file);
my $token1;
for (0 .. 16) {
    $token1 = $parser1->get_token;
}
my $parser2 = $CLASS->new(file => $test_html_file);
my $token2  = $parser2->get_tag('body');

can_ok($token1, '_get_text');
can_ok($token2, '_get_text');
is($token1->_get_text, $token2->_get_text,
    '... and _get_text should return the same value regardless of source');

# <body alink="#0000ff" bgcolor="#ffffff">
can_ok($token1, '_get_attrseq');
can_ok($token2, '_get_attrseq');
is_deeply($token1->_get_attrseq, $token2->_get_attrseq,
    '... and _get_attrseq should return the same value regardless of source');

my @attrseq = qw/alink bgcolor/;
is_deeply($token1->_get_attrseq, \@attrseq,
    '... and it should match the correct attribute sequence');

can_ok($token1, '_get_attr');
can_ok($token2, '_get_attr');
is_deeply($token1->_get_attr, $token2->_get_attr,
    '... and _get_attr should return the same value regardless of source');

my %attr = (
    alink   => '#0000ff',
    bgcolor => '#ffffff',
);
is_deeply($token1->_get_attr, \%attr,
    '... and it should match the correct attributes');

can_ok($token1, '_get_tag');
can_ok($token2, '_get_tag');
is_deeply($token1->_get_tag, $token2->_get_tag,
    '... and _get_tag should return the same value regardless of source');

is($token1->_get_tag, 'body',
    '... and it should match the correct tag');
