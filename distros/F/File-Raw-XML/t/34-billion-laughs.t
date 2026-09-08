#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use File::Raw::XML qw(file_xml_decode);

# The three shapes of entity expansion attack, each refused by the budget
# built for it and under a wall-clock bound, and each proven to be caught
# by that budget alone by lifting the other two out of the way. The bound
# is loose - a smoker under load is slow - and what it guards is the
# difference between bounded work and the gigabytes the documents describe.

sub refused { my ($b, %o) = @_; my $ok = eval { file_xml_decode($b, profile => 'full', %o); 1 }; $ok ? '' : $@ }
my $BOUND = 10;   # seconds; the real figures are milliseconds

# the classic: ten levels, ten references each, a billion "lol"s
my $laughs = "<!DOCTYPE lolz [\n<!ENTITY lol \"lol\">\n"
    . join('', map { my $p = $_ - 1; qq{<!ENTITY lol$_ "} . ('&lol' . ($p ? $p : '') . ';') x 10 . qq{">\n} } 1 .. 9)
    . "]>\n<lolz>&lol9;</lolz>\n";

# the quadratic form: one large entity referenced many times
my $big = '<!DOCTYPE r [<!ENTITY big "' . ('x' x 50_000) . '">]><r>' . ('&big;' x 100_000) . '</r>';

# the deep chain: each entity refers to the next
my $chain = '<!DOCTYPE r [' . join('', map { qq{<!ENTITY e$_ "&e@{[$_+1]};">} } 1 .. 199) . '<!ENTITY e200 "x">]><r>&e1;</r>';

my $t0 = time;
like(refused($laughs), qr/exceeds max_expansion_ratio/, 'the classic is refused by the ratio, with the defaults');
like(refused($laughs, max_expansion_ratio => 1_000_000_000), qr/exceeds max_expansion_bytes/, 'with the ratio out of the way, by the byte cap');
like(refused($laughs, max_expansion_ratio => 1_000_000_000, max_expansion_bytes => 1 << 30, max_entity_depth => 5),
     qr/deeper than max_entity_depth/, 'with both out of the way and a depth of five, by the depth');
cmp_ok(time - $t0, '<', $BOUND, 'all three in bounded time');

$t0 = time;
like(refused($big), qr/exceeds max_expansion_bytes/, 'the quadratic form is refused by the byte cap, with the defaults');
like(refused($big, max_expansion_bytes => 1 << 30), qr/exceeds max_expansion_ratio/, 'with the byte cap out of the way, by the ratio');
cmp_ok(time - $t0, '<', $BOUND, 'in bounded time');

$t0 = time;
like(refused($chain), qr/deeper than max_entity_depth/, 'the chain is refused by the depth, with the defaults');
ok(file_xml_decode($chain, profile => 'full', max_entity_depth => 200), 'and parses under a depth of 200');
cmp_ok(time - $t0, '<', $BOUND, 'in bounded time');

# the offsets name the reference that crossed the budget, inside the entity
# whose text it stands in, so the message shows the attacker's own text
like(refused($laughs), qr/at byte offset \d+ near "&lol/, 'the refusal points at a reference');

done_testing;
