use Test::Most;

use DateTime;
use English;
use File::Slurp;
use Log::JSON;

#use Test::TempDir;
use Directory::Scratch;

my $tmp_dir  = Directory::Scratch->new;
my $filename = DateTime->now->ymd . '.json';
my $file     = $tmp_dir->file($filename);
my $logger   = Log::JSON->new( file => $file );
ok -e $file->stringify, 'file exists: ' . $file->stringify;
ok -z $file->stringify, 'file is empty';

$logger->log( a => 1, b => 2, c => 3 );
my @content0 = File::Slurp::read_file( $file->stringify );
my $lines0   = scalar(@content0);
ok $lines0, 'file is no longer empty';

$logger->log( a => 10, b => 20, c => 30 );
my @content1 = File::Slurp::read_file( $file->stringify );
my $lines1   = scalar(@content1);
ok $lines1 > $lines0, 'file size is bigger than before';

#ok $lines1 > 99, 'file size is bigger than before';

done_testing;
