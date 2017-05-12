use File::Temp;
use Test::More tests => 5;

BEGIN { use_ok('IO::File::WithFilename') };

my $mode = eval { O_RDONLY };
ok(defined $mode, 'export');

my $temp_fh = File::Temp->new;
my $file = $temp_fh->filename;

my $fh = IO::File::WithFilename->new($file, $mode);

ok($fh, 'new');
is($fh->filename, $file, 'filename method');
is("$fh", $file, 'stringification');
