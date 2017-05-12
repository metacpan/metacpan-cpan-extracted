use Evo 'Test::More; Evo::Internal::Exception';
use File::Spec::Functions qw(abs2rel catdir rel2abs);

plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';
require Evo::Fs;

like exception { Evo::Fs->new(root => '.'); }, qr/root.+absolute/i;


my $fs = Evo::Fs->new(root => '/app');
like exception { $fs->path2real('..'); }, qr/unsafe/i;
my $unsafe = $fs->cd('..');
is $unsafe->path2real('foo'), '/app/../foo';


# dirs
is $fs->path2real('.'),  '/app/';
is $fs->path2real('/'),  '/app/';
is $fs->path2real('./'), '/app/';

# files
is $fs->path2real('/foo'),  '/app/foo';
is $fs->path2real('./foo'), '/app/foo';
is $fs->path2real('foo'),   '/app/foo';

done_testing;
