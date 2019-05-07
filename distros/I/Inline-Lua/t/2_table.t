use Test::More;

BEGIN { plan tests => 10 };

use Inline Lua	    => 'DATA',
	   Undef    => 'undefined value';

ok(1);

my @ary1 = (3, 2, 1);
my @ary2 = (3, 2, 1, [1, 2, 3]);
my %hsh1 = (key1 => 'val1', key2 => 'val2');
my %hsh2 = (key1 => 'val1', key2 => 'val2', key3 => { key4 => 'val4' });
my @mix	 = (3, 2, 1, { key1 => 'val1', ary => [1, 2, 3] }, [ qw/a b/, { 1 => 2 } ]);

is_deeply(take_table(\@ary1), \@ary1,				"simple array");
is_deeply(take_table(\@ary2), \@ary2,				"nested array");
is_deeply(take_table(\%hsh1), \%hsh1,				"simple hash");
is_deeply(take_table(\%hsh2), \%hsh2,				"nested hash");
is_deeply(take_table(\@mix),  \@mix,				"mixed");

is_deeply(return_hash(), { key1 => 'val1', key2 => 'val2' },    "return hash");
is_deeply(return_array(), [1, 2, 3, qw/a b c/],                 "return array");

is_deeply(return_mixed(), { 1   => 1,
                            2   => 2,
                            3   => 3,
                            5   => 5,
                            key => 'val' },                     "return mixed");
is_deeply(return_nested(), [1, 2, 3, [qw/a b c/]],		"return nested");

__END__
__Lua__
function take_table (a)
    return a
end

function return_hash ()
    local tab = { key1 = 'val1', key2 = 'val2' }
    return tab
end

function return_array ()
    local tab = { 1, 2, 3, "a", "b", "c" }
    return tab
end

function return_mixed ()
    local tab = { 1, 2, 3, [5] = 5, key = 'val' }
    return tab
end

function return_nested ()
    local tab = { 1, 2, 3, { "a", "b", "c" } }
    return tab
end
