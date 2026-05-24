######################################################################
#
# 0010-escape.t -- HTML auto-escape and safe filter tests
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if @INC && $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HP::Handy;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c?($PASS++,print "ok $T - $n\n"):($FAIL++,print "not ok $T - $n\n") }
sub is { my($g,$e,$n)=@_; $T++;
    defined($g) && "$g" eq "$e"
        ? ($PASS++, print "ok $T - $n\n")
        : ($FAIL++, print "not ok $T - $n  (got='".( defined $g?$g:'undef')."', exp='$e')\n") }

sub ae  { HP::Handy->new(auto_escape => 1)->render_string($_[0], $_[1]||{}) }
sub noae{ HP::Handy->new(auto_escape => 0)->render_string($_[0], $_[1]||{}) }

my @tests = (

    # --- auto_escape on (default) ---
    sub { is(ae('{{ x }}', {x=>'<b>hi</b>'}),     '&lt;b&gt;hi&lt;/b&gt;', 'ae: < > escaped') },
    sub { is(ae('{{ x }}', {x=>'"hello"'}),         '&quot;hello&quot;',    'ae: " escaped') },
    sub { is(ae('{{ x }}', {x=>"it's"}),            'it&#39;s',             'ae: apostrophe escaped') },
    sub { is(ae('{{ x }}', {x=>'a&b'}),             'a&amp;b',              'ae: & escaped') },
    sub { is(ae('{{ x }}', {x=>'plain'}),           'plain',                'ae: plain text unchanged') },
    sub { is(ae('{{ x }}', {x=>''}),                '',                     'ae: empty string') },
    sub { is(ae('{{ x }}', {x=>'<script>'}),        '&lt;script&gt;',       'ae: script tag') },
    sub { is(ae('{{ x }}', {x=>'<a href="u">'}),    '&lt;a href=&quot;u&quot;&gt;', 'ae: href') },

    # --- auto_escape off ---
    sub { is(noae('{{ x }}', {x=>'<b>hi</b>'}),    '<b>hi</b>',            'no-ae: raw output') },
    sub { is(noae('{{ x }}', {x=>'"ok"'}),          '"ok"',                 'no-ae: quote unchanged') },
    sub { is(noae('{{ x }}', {x=>'a&b'}),           'a&b',                  'no-ae: amp unchanged') },

    # --- safe filter (bypass escape) ---
    sub { is(ae('{{ x|safe }}', {x=>'<b>bold</b>'}), '<b>bold</b>',        'safe: markup passed through') },
    sub { is(ae('{{ x|safe }}', {x=>'<script>'}),    '<script>',           'safe: script allowed') },
    sub { is(ae('{{ x|safe }}', {x=>'plain'}),       'plain',              'safe: plain unchanged') },
    sub { is(ae('{{ x|safe }}', {x=>''}),            '',                   'safe: empty') },

    # --- e / escape filter (force escape) ---
    sub { is(noae('{{ x|e }}',      {x=>'<b>'}),   '&lt;b&gt;',           'e filter: escapes <') },
    sub { is(noae('{{ x|escape }}', {x=>'<b>'}),   '&lt;b&gt;',           'escape filter: alias works') },
    sub { is(noae('{{ x|e }}',      {x=>'"hi"'}),  '&quot;hi&quot;',      'e filter: escapes "') },
    sub { is(noae('{{ x|e }}',      {x=>'a&b'}),   'a&amp;b',             'e filter: escapes &') },

    # --- literal in template ---
    sub { is(ae('<b>{{ x }}</b>', {x=>'hi'}), '<b>hi</b>', 'ae: literal HTML not escaped') },
    sub { is(ae('{{ "<b>" }}', {}),           '&lt;b&gt;', 'ae: string literal escaped') },

    # --- numeric values not escaped ---
    sub { is(ae('{{ x }}', {x=>42}),   '42',   'ae: integer not escaped') },
    sub { is(ae('{{ x }}', {x=>3.14}), '3.14', 'ae: float not escaped') },

    # --- chained with other filters ---
    sub { is(ae('{{ x|upper|safe }}', {x=>'<ok>'}),     '<OK>',          'ae: upper then safe') },
    sub { is(ae('{{ x|safe|upper }}', {x=>'<ok>'}),     '&lt;OK&gt;',          'ae: safe then upper') },
    sub { is(noae('{{ x|e|upper }}',  {x=>'<ok>'}),     '&LT;OK&GT;',   'no-ae: e then upper') },

    # --- whitespace control does not affect escaping ---
    sub { is(ae('{{- x -}}', {x=>'<b>'}), '&lt;b&gt;', 'ae: wsc does not bypass escape') },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
print "# $PASS passed, $FAIL failed\n";
