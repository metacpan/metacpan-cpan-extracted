use Test::More tests => 13;
use Test::Exception;

BEGIN { use_ok('Math::SMA'); }

my $e = Math::SMA->new(size => 3);

isa_ok($e, 'Math::SMA', 'Class ok');

can_ok($e, qw/size last_avg precision values _set_last_avg sma _raw_average/);

lives_ok { Math::SMA->new(size => 1, last_avg => 22, precision => 3, values => [1,2,3]) } 'Construct with all attrubutes';

throws_ok { Math::SMA->new() } qr/required/, 'size is required';
throws_ok { Math::SMA->new(size => '0x02') } qr/is not an integer/, 'Constructor needs number';
throws_ok { Math::SMA->new(size => .1) } qr/is not an integer/, 'Constructor needs number';
throws_ok { Math::SMA->new(size => 2, values => 'nope') } qr/is not an array/, 'values takes an arrayref';
throws_ok { $e->precision('help') } qr/not a number/, 'precision() needs number';
throws_ok { $e->sma('help') } qr/numbers only/, 'sma() needs a number';

throws_ok { $e->last_avg(1) } qr/read-only accessor|Usage/, 'last_avg() is read only';
throws_ok { $e->size(1) } qr/read-only accessor|Usage/, 'size() is read only';
throws_ok { $e->values(1) } qr/read-only accessor|Usage/, 'values() is read only';

