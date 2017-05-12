use Test::More tests => 10;
use Test::Exception;

BEGIN { use_ok('Math::EWMA'); }

my $e = Math::EWMA->new(alpha => .125);

isa_ok($e, 'Math::EWMA', 'Class ok');

can_ok($e, qw/alpha last_avg precision ewma _set_last_avg/);

lives_ok { Math::EWMA->new(alpha => .125, last_avg => 22, precision => 3) } 'Construct with all attrubutes';

throws_ok { Math::EWMA->new() } qr/required/, 'Alpha is required';
throws_ok { Math::EWMA->new(alpha => '0x02') } qr/not a number/, 'Constructor needs number';
throws_ok { $e->precision('help') } qr/not a number/, 'precision() needs number';
throws_ok { $e->ewma('help') } qr/numbers only/, 'ewma() needs number';

throws_ok { $e->last_avg(1) } qr/read-only accessor|Usage/, 'last_avg() is read only';
throws_ok { $e->alpha(1) } qr/read-only accessor|Usage/, 'alpha() is read only';

