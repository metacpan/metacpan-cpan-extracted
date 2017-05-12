use Test::More tests => 8;

require_ok('File::VMSVersions');

# removing old data from previous make tests
unlink('./.vcntl');
unlink(glob('./bla.dat;*'));

my $vdir = File::VMSVersions->new(
   -name  => '.',
   -mode  => 'days',
   -limit => 2,
);

ok($vdir, "creating object");

for (1..5) {
   my($fh, $fn) = $vdir->open('bla.dat', '>');
   # 3..7
   ok($fh, "creating bla.dat;$_");
   $fh->close;
}

$past = time() - 300000;
utime($past, $past, 'bla.dat;2', 'bla.dat;4');
$vdir->open('bla.dat', '>');

# 8
my $info = $vdir->info('bla.dat');
ok( join('', @{$info->{versions}}) eq '1356', 'leftover versions');
