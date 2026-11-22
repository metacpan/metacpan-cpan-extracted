use strict;
use warnings;
use utf8;

use Test::More;

use Geo::Postcodes::NO;

my @all = sort(Geo::Postcodes::NO::get_postcodes());
my %a = map { $_ => 1 } grep { $_ =~ /\A00/ } @all;
my %b = map { $_ => 1 } grep { (Geo::Postcodes::NO::type_of($_) || '') eq 'SX' } @all;

my %expected = (
    'and'      => [ sort grep {  $a{$_} &&  $b{$_} } @all ],
    'and not'  => [ sort grep {  $a{$_} && !$b{$_} } @all ],
    'nand'        => [ sort grep { !($a{$_} &&  $b{$_}) } @all ],
    'nand not'    => [ sort grep { !($a{$_} && !$b{$_}) } @all ],
    'oldnand'     => [ sort grep {  $a{$_} && !$b{$_} } @all ],
    'oldnand not' => [ sort grep {  $a{$_} &&  $b{$_} } @all ],
    'or'          => [ sort grep {  $a{$_} ||  $b{$_} } @all ],
    'or not'   => [ sort grep {  $a{$_} || !$b{$_} } @all ],
    'nor'      => [ sort grep { !($a{$_} ||  $b{$_}) } @all ],
    'nor not'  => [ sort grep { !($a{$_} || !$b{$_}) } @all ],
    'xor'      => [ sort grep { (!!$a{$_}) != (!!$b{$_}) } @all ],
    'xor not'  => [ sort grep { (!!$a{$_}) != (!$b{$_}) } @all ],
    'xnor'     => [ sort grep { (!!$a{$_}) == (!!$b{$_}) } @all ],
    'xnor not' => [ sort grep { (!!$a{$_}) == (!$b{$_}) } @all ],
);

for my $mode (sort keys %expected) {
    my @got = Geo::Postcodes::NO::selection(postcode => '00%', $mode, type => 'SX');
    is_deeply(\@got, $expected{$mode}, "$mode selection mode follows documented set logic");
}


ok(Geo::Postcodes::NO::is_legal_selectionmode('oldnand'), 'oldnand is a legal selection mode');
ok(Geo::Postcodes::NO::is_legal_selectionmode('oldnand not'), 'oldnand not is a legal selection mode');

my ($status, @verified) = Geo::Postcodes::NO::verify_selectionlist(
    postcode => '00%',
    oldnand  => type => 'SX',
);
ok($status, 'oldnand verifies in selection list');
is_deeply(\@verified, [postcode => '00%', oldnand => type => 'SX'], 'oldnand selection list is preserved');

is_deeply([ Geo::Postcodes::NO::selection('not', postcode => '00%') ],
    [ sort grep { !$a{$_} } @all ],
    'initial not selection returns complement');

is_deeply([ Geo::Postcodes::NO::selection('none') ], [], 'initial none returns no postcodes');

my @one = Geo::Postcodes::NO::selection('one');
is(scalar @one, 1, 'initial one returns a single postcode');
ok(Geo::Postcodes::NO::valid($one[0]), 'initial one returns a valid postcode');

is_deeply([ Geo::Postcodes::NO::selection(procedure => sub { $_[0] eq '1178' }) ],
    ['1178'],
    'procedure selection can match one postcode');

is_deeply([ Geo::Postcodes::NO::selection(postcode => '1178', 'and', procedure => sub { $_[0] eq '1178' }) ],
    ['1178'],
    'procedure in a non-initial clause keeps a matching postcode');

is_deeply([ Geo::Postcodes::NO::selection(postcode => '1178', 'and', procedure => sub { $_[0] eq '0010' }) ],
    [],
    'procedure in a non-initial clause can empty the selection');

is(Geo::Postcodes::NO::selection(procedure => sub { die "boom" }), undef,
    'procedure selection failure returns undef');

is(Geo::Postcodes::NO::selection(location => '('), undef,
    'invalid selection regex returns undef');

my @invalid_regex = Geo::Postcodes::NO::selection(location => '(');
is_deeply(\@invalid_regex, [], 'invalid selection regex returns empty list in list context');

done_testing;
