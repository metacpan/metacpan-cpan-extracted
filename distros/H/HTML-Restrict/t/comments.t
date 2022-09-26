#!/usr/bin/env perl

use warnings;
use strict;

use HTML::Restrict ();
use Test::More;

my $hr = HTML::Restrict->new;

my $text = '<!-- comment here -->stuff';
$hr->debug(0);

is $hr->process($text), 'stuff', 'comments allowed';
$hr->allow_comments(1);
is $hr->process($text), $text, 'comments allowd';

$text = 'before<!-- This is a comment -- -- So is this -->after';
$hr->allow_comments(0);

is $hr->process($text), 'beforeafter', 'comment allowed';

$hr->allow_comments(1);
is $hr->process($text), $text, 'comments allowd';

$hr->allow_comments(0);
$text = '<!-- <script> <h1> -->';
is $hr->process($text), undef, 'tags nested in comments removed';

#$hr->set_rules({ script => [], 'h1' => [] });
#is $hr->process( $text ), $text, 'tags nested in comments not removed when explicitly allowed';

done_testing();
