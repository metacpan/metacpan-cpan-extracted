use strict;
use File::Spec::Functions qw(catfile);
use FindBin               qw($Bin);
use Test::More tests => 5;

use_ok('Log::Dispatch');
use_ok('Log::Dispatch::FileShared');

my $dispatcher = Log::Dispatch->new();
ok($dispatcher);

my $logfile = catfile($Bin, 'test.log');
$dispatcher->add(	Log::Dispatch::FileShared->new(
						name => 'file1',
						min_level => 'debug',
						filename => $logfile,
					)
);

$dispatcher->log( level => 'debug', message => "test\n" );
$dispatcher->log( level => 'info', message => "test\n" );

undef($dispatcher);

my $h;
open($h, $logfile) or die("Can't read $logfile: $!");
my @lines = <$h>;
close($h);
is( $lines[0], "test\n",  "1st line OK." );
is( $lines[1], "test\n",  "2nd line OK." );
unlink($logfile);
