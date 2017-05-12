use strict;
use warnings;

use File::Basename; # For basename().
use File::Slurp; # For read_file(), write_file().
use File::Spec;
use File::Temp;

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

	write_file($out_file_name, {binmode => ':raw'}, @result);

	is
	(
		read_file("$out_file_name", {binmode => ':raw:encoding(utf-8)'}),
		read_file("$log_file_name", {binmode => ':raw:encoding(utf-8)'}),
		"Parsing $in_file_name matches shipped log"
	);

} # End of process.

# ------------------------------------------------

my($count)         = 0;
my($data_dir_name) = 'data';

for my $file_name (sort grep{/svg$/} read_dir('data', {prefix => 1}) )
{
	process($data_dir_name, $file_name);
	$count++;
}

print "# Internal test count: $count. \n";

done_testing;
