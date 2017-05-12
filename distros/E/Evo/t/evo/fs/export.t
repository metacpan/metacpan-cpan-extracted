use Evo 'Test::More';

plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';
require Evo::Fs;
Evo::Fs->import('FSROOT');

is &FSROOT()->root, '/';

done_testing;
