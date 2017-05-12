use Test::More 'tests' => 4;

use IO::Scalar;

use_ok( 'IO::YAML' );

my $str;
my $fh = IO::Scalar->new(\$str);

my $io = IO::YAML->new($fh, '>');

isa_ok( $io, 'IO::YAML' );

$io->auto_terminate(1);

ok( $io->auto_terminate, 'auto_terminate accessor' );

$io->print([1,2,3]);
$io->print([4,5,6]);

seek $fh, 0, 0;

my $io2 = IO::YAML->new($fh, '<');
$io2->auto_load(1);

my $val1 = <$io2>;
my $val2 = <$io2>;

is_deeply( [$val1, $val2], [ [1,2,3], [4,5,6] ], 'auto_terminate' );
