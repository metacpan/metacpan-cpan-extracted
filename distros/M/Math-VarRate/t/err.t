#!perl
use strict;
use warnings;
use Test::More 'no_plan';

use Math::VarRate;

eval { Math::VarRate->new({ rate_changes => { -10 => 2 } }); };
like($@, qr/negative offset/, "can't have a negative offset in rate changes");

eval { Math::VarRate->new({ rate_changes => { 10 => -2 } }); };
like($@, qr/negative rate/, "can't have a negative rate in rate changes");

eval { Math::VarRate->new({ rate_changes => { 'ten' => 2 } }); };
like($@, qr/non-numeric offset/, "can't have a non-numeric offset in rate_c");

eval { Math::VarRate->new({ rate_changes => { 10 => 'neg two' } }); };
like($@, qr/non-numeric rate/, "can't have a non-numeric rate in rate_c");

my $varrate = Math::VarRate->new({ rate_changes => { 0 => 1 } });

eval { $varrate->offset_for(-10) };
like($@, qr/illegal value: negative/, "can't get offset for a negative value");

eval { $varrate->offset_for('ten') };
like($@, qr/illegal value: non-n/, "can't get offset for a non-numeric value");

eval { $varrate->value_at(-10) };
like($@, qr/illegal offset: negative/, "can't get value for a negative value");

eval { $varrate->value_at('ten') };
like($@, qr/illegal offset: non-n/, "can't get value for a non-numeric value");
