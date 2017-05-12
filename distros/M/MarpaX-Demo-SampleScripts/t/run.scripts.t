use strict;
use warnings;

use Capture::Tiny 'capture';

use File::Slurp; # For read_dir().

use Test::More;

use Try::Tiny;

# ------------------------------------------------

sub run_one
{
	my($script) = @_;
	my($result) = 'OK';

	try
	{
		my($stdout, $stderr) = capture{"$^X $script"};
	}
	catch
	{
		$result = $_;
	};

	ok($result eq 'OK', "Script $script");

} # End of run_one.

# ------------------------------------------------

my($count)    = 0;
my($dir_name) = './scripts';

for my $script (read_dir($dir_name) )
{
	$count++;

	run_one("$dir_name/$script");
}

print "# Internal test count: $count\n";

done_testing($count);
