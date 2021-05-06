#!/usr/bin/env perl

use warnings;
use strict;

use lib './';

use Test::More;
use MikroTik::Client::Response;
use MikroTik::Client::Sentence qw(encode_sentence);

my $r = MikroTik::Client::Response->new();

my $packed = encode_sentence('!re', {a => 1, b => 2});
$packed .= encode_sentence('!re', {c => 3, d => 4, e => 5}, undef, 3);
$packed .= encode_sentence('!done');

my $data = $r->parse(\$packed);
is_deeply $data,
  [
  {a      => '1', b       => '2', '.tag' => '', '.type' => '!re'},
  {e      => '5', d       => '4', c => '3', '.tag' => '3', '.type' => '!re'},
  {'.tag' => '',  '.type' => '!done'}
  ],
  'right response';

# reassemble partial buffer
my ($attr, @parts);
$attr->{$_} = $_ x 200 for 1 .. 4;

$packed = encode_sentence('!re', $attr);
$packed .= $packed . $packed . $packed;
push @parts, (substr $packed, 0, $_, '') for (900, 700, 880, 820);

$attr->{'.tag'}  = '';
$attr->{'.type'} = '!re';

my $buf = $parts[0];
my $w   = $r->parse(\$buf);
is_deeply $w, [$attr], 'right result';
ok $r->sentence->is_incomplete, 'incomplete is set';
$buf .= $parts[1];
$w = $r->parse(\$buf);
is_deeply $w, [], 'right result';
ok $r->sentence->is_incomplete, 'incomplete is set';
$buf .= $parts[2];
$w = $r->parse(\$buf);
is_deeply $w, [($attr) x 2], 'right result';
ok $r->sentence->is_incomplete, 'incomplete is set';
$buf .= $parts[3];
$w = $r->parse(\$buf);
is_deeply $w, [$attr], 'right result';
ok !$r->sentence->is_incomplete, 'incomplete is not set';

# newline in response
$packed
  = encode_sentence('!re', {multiline => "This is\nmulti line\nattribute!"});
$data = $r->parse(\$packed);
is_deeply $data,
  [{multiline => "This is\nmulti line\nattribute!", '.tag' => '', '.type' => '!re'
  }], 'right results';

done_testing();
