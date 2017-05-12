use strict;
use warnings FATAL => 'all';
use Encode qw(encode);
use IRC::Utils qw(:ALL);
use Test::More tests => 46;

is('SIMPLE', uc_irc('simple'), 'Upper simple test');
is('simple', lc_irc('SIMPLE'), 'Lower simple test');
is('C0MPL~[X]', uc_irc('c0mpl^{x}'), 'Upper complex test');
is('c0mpl^{x}', lc_irc('C0MPL~[X]'), 'Lower complex test');
is('C0MPL~[X]', uc_irc('c0mpl~[x]', 'ascii'), 'Upper complex test ascii');
is('c0mpl^{x}', lc_irc('C0MPL^{X}', 'ascii'), 'Lower complex test ascii');
is('C0MPL~[X]', uc_irc('c0mpl~{x}', 'strict-rfc1459'), 'Upper complex test strict');
is('c0mpl^{x}', lc_irc('C0MPL^[X]', 'strict-rfc1459'), 'Lower complex test strict');
ok(eq_irc('C0MPL~[X]', 'c0mpl~{x}'), 'eq_irc() considers them equivalent');

ok(is_valid_nick_name( 'm00[^]' ), 'Nickname is valid test');
ok(!is_valid_nick_name( 'm00[=]' ), 'Nickname is invalid test');
ok(is_valid_chan_name( '#chan.nel' ), 'Channel is valid test');
ok(!is_valid_chan_name( '#chan,nel' ), 'Channel is invalid');
ok(!is_valid_chan_name( '#chan'.join('', ('a') x 200)), 'Channel name too long');

is(unparse_mode_line('+o-v-o-o+v-o+o+o'), '+o-voo+v-o+oo', 'Unparsed mode line');
is(gen_mode_change('ailowz','i'), '-alowz', 'Gen mode changes 1');
is(gen_mode_change('i','ailowz'), '+alowz', 'Gen mode changes 2');
is(gen_mode_change('i','alowz'), '-i+alowz', 'Gen mode changes 3');

my $hashref = parse_mode_line(qw(ov rita bob));
is($hashref->{modes}->[0], '+o', 'Parse mode test 1');
is($hashref->{args}->[0], 'rita', 'Parse mode test 2');
my $hashref2 = parse_mode_line(qw(-b +b!*@*));
is($hashref2->{modes}->[0], '-b', 'Parse mode test 3');
is($hashref2->{args}->[0], '+b!*@*', 'Parse mode test 4');
my $hashref3 = parse_mode_line(qw(+b -b!*@*));
is($hashref3->{modes}->[0], '+b', 'Parse mode test 5');
is($hashref3->{args}->[0], '-b!*@*', 'Parse mode test 6');

my $partial_mask = normalize_mask('*@*');
is($partial_mask, '*!*@*', 'Normalized partial mask');

my $banmask = normalize_mask('stalin*');
my $match = 'stalin!joe@kremlin.ru';
my $no_match = 'BinGOs!foo@blah.com';
is($banmask, 'stalin*!*@*', 'Parse ban mask test');
ok(matches_mask($banmask, $match), 'Matches Mask test 1');
ok(!matches_mask($banmask, $no_match), 'Matches Mask test 2');
ok(%{ matches_mask_array([$banmask], [$match]) }, 'Matches Mask array test 1');
ok(!%{ matches_mask_array([$banmask], [$no_match] ) }, 'Matches Mask array test 2');

my $nick = parse_user('BinGOs!null@fubar.com');
my @args = parse_user('BinGOs!null@fubar.com');
is($nick, 'BinGOs', 'Parse User Test 1');
is($nick, $args[0], 'Parse User Test 2');
is($args[1], 'null', 'Parse User Test 3');
is($args[2], 'fubar.com', 'Parse User Test 4');

my $colored = "\x0304,05Hi, I am a color junkie\x03";
ok(has_color($colored), 'Has Color Test');
is(strip_color($colored), 'Hi, I am a color junkie', 'Strip Color Test');

my $bg_colored = "\x03,05Hi, observe my colored background\x03";
is(strip_color($bg_colored), 'Hi, observe my colored background', 'Strip bg color test');
my $fg_colored = "\x0305Hi, observe my colored foreground\x03";
is(strip_color($fg_colored), 'Hi, observe my colored foreground', 'Strip fg color test');

my $formatted = "This is \x02bold\x0f and this is \x1funderlined\x0f";
ok(has_formatting($formatted), 'Has Formatting Test');
my $stripped = strip_formatting($formatted);
is($stripped, 'This is bold and this is underlined', 'Strip Formatting Test');

my $form_color = "Foo \x0305\x02bar\x0f baz";
my $no_color = strip_color($form_color);
my $no_form = strip_formatting($form_color);
is($no_color, "Foo \x02bar\x0f baz", "Only stripped colors");
is($no_form, "Foo \x0305bar\x0f baz", "Only stripped formatting");

my $string = "l\372\360i";
my $cp1252_bytes = encode('cp1252', $string);
my $utf8_bytes = encode('utf8', $string);
is(decode_irc($cp1252_bytes), $string, 'decode_irc() works for CP1252 text');
is(decode_irc($utf8_bytes), $string, 'decode_irc() works for UTF-8 text');

is(numeric_to_name('001'), 'RPL_WELCOME', 'RFC name 001 is correct');
is(name_to_numeric('RPL_MYINFO'), '004', 'RFC code 004 is correct');
