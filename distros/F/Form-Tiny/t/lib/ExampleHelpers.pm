package ExampleHelpers;

use v5.10;
use warnings;
use Exporter qw(import);
use File::Basename;

our @EXPORT = qw(
	do_example
);

my $examples_path = dirname(dirname(dirname(__FILE__))) . "/ex";

sub do_example
{
	my ($name) = @_;

	my $filename = $examples_path . "/$name.pl";
	die "Example file does not exist: $filename"
		unless -f $filename;

	return do $filename;
}

1;
