use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# Script with POD at bottom
{
	my $input = <<'END';
#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my %opts;
GetOptions(\%opts,
'verbose|v',
'output|o=s',
'help|h',
);

if ($opts{help}) {
print_usage();
exit 0;
}

sub print_usage {
print "Usage: myscript [options]\n";
}

sub run {
my $data = shift;
if ($opts{verbose}) {
print "Processing...\n";
}
return process($data);
}

sub process {
my $input = shift;
return uc($input);
}

run($ARGV[0]);

=head1 NAME

myscript - a useful script

=head1 SYNOPSIS

    myscript [options] <input>

    Options:
        -v, --verbose    Enable verbose output
        -o, --output     Output file
        -h, --help       Show help

=head1 DESCRIPTION

This script processes input data.

=head1 EXAMPLES

    # Basic usage
    myscript input.txt

    # With verbose output
    myscript -v -o result.txt input.txt

=cut
END

	my $expected = <<'END';
#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my %opts;
GetOptions(\%opts,
	'verbose|v',
	'output|o=s',
	'help|h',
);

if ($opts{help}) {
	print_usage();
	exit 0;
}

sub print_usage {
	print "Usage: myscript [options]\n";
}

sub run {
	my $data = shift;
	if ($opts{verbose}) {
		print "Processing...\n";
	}
	return process($data);
}

sub process {
	my $input = shift;
	return uc($input);
}

run($ARGV[0]);

=head1 NAME

myscript - a useful script

=head1 SYNOPSIS

	myscript [options] <input>

	Options:
	-v, --verbose    Enable verbose output
	-o, --output     Output file
	-h, --help       Show help

=head1 DESCRIPTION

This script processes input data.

=head1 EXAMPLES

	# Basic usage
	myscript input.txt

	# With verbose output
	myscript -v -o result.txt input.txt

=cut
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'script with POD at bottom');
}

# Script with =pod block as standalone docs
{
	my $input = <<'END';
#!/usr/bin/perl

=pod

=head1 DESCRIPTION

This script does things.

    my $example = 1;

=cut

use strict;
use warnings;

my $x = 1;
if ($x) {
print "yes\n";
}
END

	my $expected = <<'END';
#!/usr/bin/perl

=pod

=head1 DESCRIPTION

This script does things.

	my $example = 1;

=cut

use strict;
use warnings;

my $x = 1;
if ($x) {
	print "yes\n";
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'script with =pod block');
}

# POD between conditionals
{
	my $input = <<'END';
sub dispatch {
my ($self, $action) = @_;
if ($action eq 'create') {
return $self->create;
}

=head2 dispatch

Dispatches actions:

    $obj->dispatch('create');
    $obj->dispatch('delete');

=cut

elsif ($action eq 'delete') {
return $self->delete;
}
return;
}
END

	my $expected = <<'END';
sub dispatch {
	my ($self, $action) = @_;
	if ($action eq 'create') {
		return $self->create;
	}

=head2 dispatch

Dispatches actions:

	$obj->dispatch('create');
	$obj->dispatch('delete');

=cut

	elsif ($action eq 'delete') {
		return $self->delete;
	}
	return;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'POD between conditional blocks');
}

# Multiple code examples in one POD section
{
	my $input = <<'END';
=head1 USAGE

Create an object:

    my $obj = Foo->new(
        name => 'test',
    );

Then call methods:

    $obj->run;
    $obj->finish;

Or chain them:

    Foo->new(name => 'test')
        ->run
        ->finish;

=cut
END

	my $expected = <<'END';
=head1 USAGE

Create an object:

	my $obj = Foo->new(
	name => 'test',
	);

Then call methods:

	$obj->run;
	$obj->finish;

Or chain them:

	Foo->new(name => 'test')
	->run
	->finish;

=cut
END

	my $got = Eshu->indent_pod($input);
	is($got, $expected, 'multiple code examples in one POD section');
}

# Perl with heredoc near POD
{
	my $input = <<'END';
sub help {
my $text = <<'HELP';
Usage: tool [options]
  --verbose    be verbose
  --quiet      be quiet
HELP
return $text;
}

=head1 HELP

The help output looks like:

    Usage: tool [options]
      --verbose    be verbose
      --quiet      be quiet

=cut

sub version {
return '1.0';
}
END

	my $expected = <<'END';
sub help {
	my $text = <<'HELP';
Usage: tool [options]
  --verbose    be verbose
  --quiet      be quiet
HELP
	return $text;
}

=head1 HELP

The help output looks like:

	Usage: tool [options]
	--verbose    be verbose
	--quiet      be quiet

=cut

sub version {
	return '1.0';
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'heredoc near POD boundary');
}
