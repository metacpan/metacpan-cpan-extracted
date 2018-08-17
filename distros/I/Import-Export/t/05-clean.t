use Test::More;
use lib 't/test';
use Clean::Up;
use Clean::Down;

is(Clean::Up::okay, 1, 'okay exits');
is(Clean::Up::not, 0, 'not exists that calls not_okay');
my $no = eval { Clean::Up::not_okay() }; 
like($@, qr/Undefined subroutine &Clean::Up::not_okay/, 'not_okay does not exists aka cleaned');

is(Clean::Down::okay, 1, 'okay exits');
is(Clean::Down::not, 0, 'not exists that calls not_okay');
$no = eval { Clean::Down::not_okay() }; 
like($@, qr/Undefined subroutine &Clean::Down::not_okay/, 'not_okay does not exists aka cleaned');

done_testing;
