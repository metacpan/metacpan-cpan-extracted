use Test::More tests => 9;

require_ok('File::VMSVersions');

# removing old data from previous make tests
unlink('./.vcntl');
unlink(glob('./bla.dat;*'));

my $vdir = File::VMSVersions->new(
   -name  => '.',
   -mode  => 'versions',
   -limit => 3,
);

ok($vdir, "creating object with shipped .vcntl");

for (0..4) {
   my($fh, $fn) = $vdir->open('bla.dat', '>');
   # 3..7
   ok($fh, "creating bla.dat;$_");
   $fh->close;
}

# 8
my $info = $vdir->info('bla.dat');
ok( join('', @{$info->{versions}}) eq '345', 'leftover versions');

# 9
$vdir->purge('bla.dat');
$info = $vdir->info('bla.dat');
ok( join('', @{$info->{versions}}) eq '5', 'versions after purge');
