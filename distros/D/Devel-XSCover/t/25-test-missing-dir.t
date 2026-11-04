use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Test ();

my $dir = File::Temp->newdir;
my $missing = File::Spec->catdir($dir, 'missing');

ok(!eval { Devel::XSCover::Test->new(dir => $missing)->thread_tests; 1 }, 'the thread test search dies when the directory is not there');
like($@, qr/^xs_cover: cannot chdir to \Q$missing\E: /, 'naming it');

ok(!eval { Devel::XSCover::Test->new(dir => $missing, threads_covered => 1, plain => ['t/c.t'], silent => 1)->commands; 1 }, 'so does listing the files to run against a plain one');
like($@, qr/^xs_cover: cannot chdir to \Q$missing\E: /, 'with the same message');

ok(!eval { Devel::XSCover::Test->new(dir => $missing, no_perl => 1, silent => 1)->run; 1 }, 'and the run itself, before anything is started');
like($@, qr/^xs_cover: cannot chdir to \Q$missing\E: /, 'with the same message again');

done_testing;
