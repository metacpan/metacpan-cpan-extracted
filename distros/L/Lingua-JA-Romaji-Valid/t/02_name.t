use strict;
use warnings;
use Test::More qw(no_plan);
use Lingua::JA::Romaji::Valid;

my $validator = Lingua::JA::Romaji::Valid->new('international');

# names shouldn't have syllabic 'n/m' at the beginning
ok !$validator->as_name('ngawa'); 

# names shouldn't have particle 'wo' at the beginning
ok !$validator->as_name('wogawa'); 

# fullname should have both first and last names
# but not a middle name
ok !$validator->as_fullname('ishigaki');
ok  $validator->as_fullname('ishigaki kenichi');
ok !$validator->as_fullname('ishigaki no kenichi');

# Japanese names shouldn't have foreign kanas
ok  $validator->as_romaji('vaiorin');
ok !$validator->as_name('vaiorin');

ok  $validator->as_romaji('kwawai');
ok !$validator->as_name('kwawai');

ok  $validator->as_romaji('yebisu');
ok !$validator->as_name('yebisu');

ok  $validator->as_romaji('fasuto');
ok !$validator->as_name('tsero');

ok  $validator->as_romaji('jetto');
ok !$validator->as_name('jetto');

ok  $validator->as_romaji('chen');
ok !$validator->as_name('chen');

ok  $validator->as_romaji('shen');
ok !$validator->as_name('shen');
