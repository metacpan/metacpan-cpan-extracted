#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use JSON::PP;

my @tests = (
    <<'...', {},
{
}
...
    <<'...', ['hogehoge'],
[r'hogehoge']
...
    <<'...', ['hogehoge', "h\\uh"],
[
    r'hogehoge',
    r'h\uh' # a
]
...
    <<'...', 'hogehoge',
r'hogehoge'
...
    <<'...', 'hoge',
base64("aG9nZQ==")
...
    <<'...', [1,1],
[
    r"1", r"1",
]
...
    <<'...', { b => 2 },
{
    b => 2,

}
...
    <<'...', "I'm here",
<<-HERE
I'm here
HERE
...
    <<'...', { foo => "I'm here" },
{
    foo => <<-HERE,
    I'm here
    HERE
}
...
    <<'...', "x\ny",
  <<-HERE
  x
  y
  HERE
...
    <<'...', JSON::PP::true(),
true
...
    <<'...', [undef],
[null]
...
    <<'...', "hoge'fuga",
"hoge'fuga"
...
    <<'...', 'hoge"fuga',
'hoge"fuga'
...
    <<'...', ['hoge', JSON::PP::true()],
[<<-EOS, true]
hoge
EOS
...
    <<'...', {f => 'hoge'},
{f => <<-EOS}
hoge
EOS
...
);

my $json = JSON::PP->new->pretty(1)->encode(\@tests);
open my $fh, '>', 't/data.json';
print {$fh} $json;
close $fh;

