use Evo 'Test::More';
plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';

require Evo::Fs;
Evo::Fs->import('SKIP_HIDDEN');
ok !&SKIP_HIDDEN->('.git');
ok !&SKIP_HIDDEN->('foo/.git');
ok !&SKIP_HIDDEN->('/foo/.git');
ok &SKIP_HIDDEN->('foo/foo.git');


done_testing;
