use Test::More tests => 6;
BEGIN { use_ok('Digest::MD5::File') };


chdir 't';

for(1..2) {
   ok($_ == 1, 'pre do not clobber $_');
   ok( Digest::MD5::File::file_md5_hex('hello-world') eq '2cad20c19a8eb9bb11a9f76527aec9bc', 'simple calc' );
   ok($_ == 1, 'pst do not clobber $_');
   last;
}

my $d = Digest::MD5::File->new;
$d->adddir('teststruct');
my $dirdigest_a = $d->hexdigest;

my $c = Digest::MD5::File->new;
$c->adddir('teststruct');
my $dirdigest_b = $c->hexdigest;

is($dirdigest_a, $dirdigest_b, 'dir digest is the same');

my $hr = Digest::MD5::File::dir_md5_hex('teststruct');

is_deeply(
	$hr, 
	{
		'a' => 'b1946ac92492d2347c6235b4d2611184',
		'b' => '32d6c11747e03715521007d8c84b5aff',
		'subdir' => '',
		File::Spec->catfile( qw(subdir c) ) => 'df0590f214a2eaf9a638f43838132f67',
    }, 
    'directory struct',
);
chdir '..';