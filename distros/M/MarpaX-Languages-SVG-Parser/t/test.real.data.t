use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use File::Basename; # For basename().
use File::Slurper 'read_text';
use File::Spec;
use File::Temp;

use Path::Tiny; # For slurp_utf8.

use Test::More;

# ------------------------------------------------

sub process
{
	my($data_dir_name, $file_name) = @_;

	my($name)          = basename($file_name);
	$name              =~ s/^(\w+)(\.\d\d)(\..+)$/$1$2/;
	my($in_file_name)  = File::Spec -> catfile($data_dir_name, "$name.svg");
	my($log_file_name) = File::Spec -> catfile($data_dir_name, "$name.log");

	# The EXLOCK option is for BSD-based systems.

	my($temp_dir)      = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($temp_dir_name) = $temp_dir -> dirname;
	my($out_file_name) = File::Spec -> catfile($temp_dir_name, "$name.log");

	my(@params);

	push @params, '-Ilib';
	push @params, 'scripts/parse.file.pl';
	push @params, '-i', $in_file_name;
	push @params, '-maxlevel', 'info';

	my(@result)  = `$^X @params`;

	path($out_file_name) -> spew(@result);

	is
	(
		read_text($out_file_name),
		read_text($log_file_name),
		"Parsing $in_file_name"
	);

} # End of process.

# ------------------------------------------------

my($count)         = 0;
my($data_dir_name) = 'data';

for my $file_name (sort grep{/svg$/} path('data') -> children)
{
	process($data_dir_name, File::Spec -> catfile('data', $file_name) );
	$count++;
}

print "# Internal test count: $count. \n";

done_testing;
