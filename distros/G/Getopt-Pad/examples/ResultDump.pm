package ResultDump;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Exporter  qw(import);
use List::Util qw(max);
use Object::Pad qw(:experimental(mop));

our @EXPORT = qw(dumpResult);

# Prints an overview of every reader on a Getopt::Pad result object and what
# it returns; nested subcommand results are indented one level further.

sub dumpResult($result, $indent = 0) {
	my $pad  = '  ' x $indent;
	my $meta = Object::Pad::MOP::Class->for_class(ref $result);

	my @readers = sort
		grep { $result->can($_) && $_ ne 'command' && $_ ne 'subcommand' }
		map  { $_->name =~ s/^\$//r } $meta->fields;

	my $width = max(map { length } @readers, 'subcommand');
	printf "%s%-*s = %s\n", $pad, $width, $_, formatValue($result->$_) foreach @readers;
	printf "%s%-*s = %s\n", $pad, $width, 'command', formatValue($result->command);

	if (defined $result->subcommand) {
		print "${pad}subcommand:\n";
		dumpResult($result->subcommand, $indent + 1);
	}
	else {
		printf "%s%-*s = undef\n", $pad, $width, 'subcommand';
	}

	return;
}

sub formatValue($value) {
	return 'undef' if !defined $value;
	return '[' . join(', ', map { formatValue($_) } $value->@*) . ']' if ref $value eq 'ARRAY';
	return $value if $value =~ /^-?\d+(?:\.\d+)?$/;
	return "'$value'";
}

1;
