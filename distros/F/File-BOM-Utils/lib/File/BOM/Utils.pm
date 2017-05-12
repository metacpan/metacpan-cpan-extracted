package File::BOM::Utils;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use File::Slurper qw/read_binary write_binary/;

use Moo;

use Types::Standard qw/Int ScalarRef Str/;

has action =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has bom_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has data =>
(
	default  => sub{return \''}, #Use ' in comment for UltraEdit syntax hiliter.
	is       => 'rw',
	isa      => ScalarRef[Str],
	required => 0,
);

has input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has output_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

# http://search.cpan.org/perldoc?PPI::Token::BOM or String::BOM.

our(%bom2name) =
(
	"\x00\x00\xfe\xff" => 'UTF-32-BE',
	"\xff\xfe\x00\x00" => 'UTF-32-LE',
	"\xfe\xff"         => 'UTF-16-BE',
	"\xff\xfe"         => 'UTF-16-LE',
	"\xef\xbb\xbf"     => 'UTF-8',
);

our(%name2bom) =
(
	'UTF-32-BE' => "\x00\x00\xfe\xff",
	'UTF-32-LE' => "\xff\xfe\x00\x00",
	'UTF-16-BE' => "\xfe\xff",
	'UTF-16-LE' => "\xff\xfe",
	'UTF-8'     => "\xef\xbb\xbf",
);

our $VERSION = '1.02';

# ------------------------------------------------

sub add
{
	my($self, %opt) = @_;

	$self -> _read(%opt);
	$self -> bom_name($opt{bom_name})       if (defined $opt{bom_name});
	$self -> output_file($opt{output_file}) if (defined $opt{input_file});

	my($output_file) = $self -> output_file;
	my($name)        = $self -> bom_name;

	die "Unknown BOM name: $name\n" if (! $name2bom{$name});

	write_binary($output_file, $name2bom{$name} . ${$self -> data});

	# Return 0 for success and 1 for failure.

	return 0;

} # End of add.

# ------------------------------------------------

sub bom_report
{
	my($self, %opt) = @_;

	$self -> bom_name($opt{bom_name}) if (defined $opt{bom_name});

	my($name) = $self -> bom_name;

	return
	{
		length => length($name2bom{$name}) || 0,
		name   => $name,
		value  => $name2bom{$name} || 0,
	};

} # End of bom_report.

# ------------------------------------------------

sub bom_values
{
	my($self) = @_;

	return sort{4 - length($a) <=> 4 - length($b)} keys %bom2name;

} # End of bom_values;

# ------------------------------------------------

sub file_report
{
	my($self, %opt) = @_;

	$self -> _read(%opt);

	my($data)  = ${$self -> data};
	my($name)  = ''; # Sugar: Make $name not null.
	my($value) = 0;  # Sugar: Make $value not null.

	my($length);

	# Sort from long to short to avoid false positives.

	for my $key ($self -> bom_values)
	{
		$length = length $key;

		# Warning: Use eq and not ==.

		if (substr($data, 0, $length) eq $key)
		{
			$value                    = $key;
			$name                     = $bom2name{$key};
			substr($data, 0, $length) = '';

			last;
		}
	}

	return
	{
		length  => $name ? $length : 0,
		message => $name ? "BOM name $name found" : 'No BOM found',
		name    => $name,
		value   => $value,
	};

	return 0;

} # End of file_report.

# ------------------------------------------------

sub _read
{
	my($self, %opt) = @_;

	$self -> input_file($opt{input_file}) if (defined $opt{input_file});
	$self -> data(\read_binary($self -> input_file) );

	# Return 0 for success and 1 for failure.

	return 0;

} # End of _read.

# ------------------------------------------------

sub remove
{
	my($self, %opt) = @_;
	my($result)     = $self -> file_report(%opt);

	$self -> output_file($opt{output_file}) if (defined $opt{input_file});

	die "Output file not specified\n" if (length($self -> output_file) == 0);

	my($output_file) = $self -> output_file;

	substr(${$self -> data}, 0, $$result{length}) = '';

	write_binary($output_file, ${$self -> data});

	# Return 0 for success and 1 for failure.

	return 0;

}  # End of remove.

# ------------------------------------------------

sub run
{
	my($self, %opt) = @_;
	my($action)     = lc($opt{action} || $self -> action || '');
	my(%sugar) =
	(
		a => 'add',
		r => 'remove',
		t => 'test',
	);
	$action     = $sugar{$action} || $action;
	my(%action) =
	(
		add    => 1,
		remove => 1,
		test   => 1,
	);

	$self -> input_file($opt{input_file}) if (defined $opt{input_file});

	die "Input file not specified\n" if (length($self -> input_file) == 0);
	die "Unknown action '$action'\n" if (! $action{$action});

	$self -> $action(%opt);

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# ------------------------------------------------

sub test
{
	my($self, %opt) = @_;
	my($result)     = $self -> file_report(%opt);
	my($file_name)  = $self -> input_file;

	print "BOM report for $file_name: \n";
	print 'File size: ', -s $file_name, " bytes \n";

	my($prefix);

	for my $key (qw/message name/)
	{
		$prefix = ($key eq 'message') ? 'Message' : 'BOM name';

		print "$prefix: $$result{$key}\n";
	}

	if ($$result{name})
	{
		my($stats) = $self -> bom_report(bom_name => $$result{name});

		print "Length: $$stats{length} bytes \n";
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of test.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<File::BOM::Utils> - Check, Add and Remove BOMs

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use File::BOM::Utils;
	use File::Spec;

	# -------------------

	my($bommer)    = File::BOM::Utils -> new;
	my($file_name) = File::Spec -> catfile('data', 'bom-UTF-8.xml');

	$bommer -> action('test');
	$bommer -> input_file($file_name);

	my($report) = $bommer -> file_report;

	print "BOM report for $file_name: \n";
	print join("\n", map{"$_: $$report{$_}"} sort keys %$report), "\n";

Try 'bommer.pl -h'. It is installed automatically when the module is installed.

=head1 Description

L<File::BOM::Utils> provides a means of testing, adding and removing BOMs (Byte-Order-Marks)
within files.

It also provides two hashes accessible from outside the module, which convert in both directions
between BOM names and values. These hashes are called C<%bom2name> and C<%name2bom>.

See also bommer.pl, which is installed automatically when the module is installed.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<File::BOM::Utils> as you would any C<Perl> module:

Run:

	cpanm File::BOM::Utils

or run:

	sudo cpan File::BOM::Utils

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = File::BOM::Utils -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<File::BOM::Utils>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</action([$string])>]):

=over 4

=item o action => $string

Specify the action wanted:

=over 4

=item o add

Add the BOM named with the C<bom_name> option to C<input_file>.
Write the result to C<output_file>.

=item o remove

Remove any BOM found from the C<input_file>. Write the result to C<output_file>.

The output is created even if the input file has no BOM, in order to not violate the
L<Principle of Least Surprise|https://en.wikipedia.org/wiki/Principle_of_least_astonishment>.

=item o test

Print the BOM status of C<input_file>.

The methods L</bom_report([%opt])> and L</file_report([%opt])> return hashrefs if you wish to
avoid printed output.

=back

Default: ''.

A value for this option is mandatory.

Note: As syntactic sugar, you may specify just the 1st letter of the action. And that's why
C<test> is called C<test> and not C<report>.

=item o bom_name => $string

Specify which BOM to add to C<input_file>.

This option is mandatory if the C<action> is C<add>.

Values (always upper-case):

=over 4

=item o UTF-32-BE

=item o UTF-32-LE

=item o UTF-16-BE

=item o UTF-16-LE

=item o UTF-8

=back

Default: ''.

Note: These names are taken from the test data for L<XML::Tiny>.

=item o input_file => $string

Specify the name of the input file. It is read in C<:raw> mode.

A value for this option is mandatory.

Default: ''.

=item o output_file => $string

Specify the name of the output file for when the action is C<add> or C<remove>.
It is written in C<:raw> mode.

And yes, it can be the same as the input file, but does not default to the input file.
That would be dangerous.

This option is mandatory if the C<action> is C<add> or C<remove>.

Default: ''.

=back

=head1 Methods

=head2 action([$string])

Here, the [] indicate an optional parameter.

Gets or sets the action name, as a string.

If you supplied an abbreviated (1st letter only) version of the action, the return value is the
full name of the action.

C<action> is a parameter to L</new([%opt])>.

=head2 add([%opt])

Here, the [] indicate an optional parameter.

Adds a named BOM to the input file, and writes the result to the output file.

Returns 0.

C<%opt> may contain these (key => value) pairs:

=over 4

=item o bom_name => $string

The name of the BOM.

The names are listed above, under L</Constructor and Initialization>.

=item o input_file => $string

=item o output_file => $string

=back

=head2 bom_name([$string])

Here, the [] indicate an optional parameter.

Gets or sets the name of the BOM to add to the input file as that file is copied to the output file.

The names are listed above, under L</Constructor and Initialization>.

C<bom_name> is a parameter to L</new([%opt])>.

=head2 bom_report([%opt])

Here, the [] indicate an optional parameter.

Returns a hashref of statitics about the named BOM.

C<%opt> may contain these (key => value) pairs:

=over 4

=item o bom_name => $string

=back

The hashref returned has these (key => value) pairs:

=over 4

=item o length => $integer

The # of bytes in the BOM.

=item o name => $string

The name of the BOM.

The names are listed above, under L</Constructor and Initialization>.

=item o value => $integer

The value of the named BOM.

=back

=head2 bom_values()

Returns an array of BOM values, sorted from longest to shortest.

=head2 data()

Returns a reference to a string holding the contents input file, or returns a reference to the
empty string.

=head2 file_report([%opt])

Here, the [] indicate an optional parameter.

Returns a hashref of statistics about the input file.

C<%opt> may contain these (key => value) pairs:

=over 4

=item o input_file => $string

=back

The hashref returned has these (key => value) pairs:

=over 4

=item o length => $name ? $length : 0

This is the length of the BOM in bytes.

=item o message => $name ? "BOM name $name found" : 'No BOM found'

=item o name => $name || ''

The name of the BOM.

The names are listed above, under L</Constructor and Initialization>.

=item o value => $value || 0

This is the value of the BOM.

=back

=head2 input_file([$string])

Here, the [] indicate an optional parameter.

Gets or sets the name of the input file.

C<input_file> is a parameter to L</new([%opt])>.

=head2 new([%opt])

Here, the [] indicate an optional parameter.

Returns an object of type C<File::BOM::Utils>.

C<%opt> may contain these (key => value) pairs:

=over 4

=item o action => $string

The action wanted.

The actions are listed above, under L</Constructor and Initialization>.

=item o bom_name => $string

The name of the BOM.

The names are listed above, under L</Constructor and Initialization>.

=item o input_file => $string

=item o output_file => $string

=back

=head2 output_file([$string])

Here, the [] indicate an optional parameter.

Gets or sets the name of the output file.

And yes, it can be the same as the input file, but does not default to the input file.
That would be dangerous.

C<output_file> is a parameter to L</new([%opt])>.

=head2 remove(%opt)

Here, the [] indicate an optional parameter.

Removes any BOM from the input file, and writes the result to the output_file.

C<%opt> may contain these (key => value) pairs:

=over 4

=item o input_file => $string

=item o output_file => $string

=back

=head2 run(%opt)

Here, the [] indicate an optional parameter.

This is the only method users would normally call, but you can call directly any of the
3 methods mentioned next.

C<%opt> is passed to L</add([%opt]>, L</remove([%opt])> and L</test([%opt])>.

Returns 0.

C<%opt> may contain these (key => value) pairs:

=over 4

=item o action => $string

The action wanted.

The actions are listed above, under L</Constructor and Initialization>.

=item o bom_name => $string

The name of the BOM.

The names are listed above, under L</Constructor and Initialization>.

=item o input_file => $string

=item o output_file => $string

=back

=head1 test([%opt])

Here, the [] indicate an optional parameter.

Print to STDOUT various statistics pertaining to the input file.

C<%opt> may contain these (key => value) pairs:

=over 4

=item o input_file => $string

=back

=head1 FAQ

=head2 How does this module read and write files?

It uses L<File::Slurper>'s read_binary() and write_binary().

=head2 What are the hashes accessible from outside the module?

They are called C<%bom2name> and C<%name2bom>.

The BOM names used are listed under L</Constructor and Initialization>.

=head2 Which program is installed when the module is installed?

It is called C<bommer.pl>. Run it with the -h option, to display help.

=head2 How is the parameter %opt, which may be passed to many methods, handled?

The keys in C<%opt> are used to find values which are passed to the methods named after the
keys.

For instance, if you call:

	my($bommer) = File::BOM::Utils -> new(action => 'add');

	$bommer -> run(action => 'test');

Then the code calls C<action('test')>, which sets the 'current' value of C<action> to C<test>.

This means that if you later call C<action()>, the value returned is whatever was the most recent
value provided (to any method) in C<$opt{action}>. Similarly for the other parameters to
L</new([%opt])>.

Note: As syntactic sugar, you may specify just the 1st letter of the action. And that's why
C<test> is called C<test> and not C<report>.

=head2 What happens if I add the same BOM twice?

The program will do as you order it to do. Hopefully, you remove one or both of the BOMs immediately
after testing the output.

=head1 See Also

L<String::BOM>.

L<PPI::Token::BOM>.

L<File::BOM>.

L<XML::Tiny>, whose test data I've adopted.

L<File::Slurper>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/File-BOM-Utils>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File::BOM::Utils>.

=head1 Author

L<File::BOM::Utils> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
