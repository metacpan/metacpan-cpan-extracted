package MarpaX::Languages::SVG::Parser;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Encode; # For decode() and encode().

use Log::Handler;

use MarpaX::Languages::SVG::Parser::XMLHandler;

use Moo;

use Path::Tiny; # For path().

use Text::CSV;

use Types::Standard qw/Any Int Str/;

has attribute =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has input_file_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has item_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has items =>
(
	default  => sub{return Set::Array -> new},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has output_file_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.09';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
				utf8           => 1,
			}
		);
	}

	$self -> log(debug => 'Input file: ' . $self -> input_file_name);

} # End of BUILD.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level = 'notice' if (! defined $level);
	$s     = ''       if (! defined $s);

	$self -> logger -> $level($s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub new_item
{
	my($self, $type, $name, $value) = @_;

	$self -> item_count($self -> item_count + 1);
	$self -> items -> push
		({
			count => $self -> item_count,
			name  => $name,
			type  => $type,
			value => $value,
		});

} # End of new_item.

# --------------------------------------------------

sub report
{
	my($self)   = @_;
	my($format) = '%6s  %-10s  %-20s  %s';

	$self -> log(info => sprintf($format, 'Count', 'Type', 'Name', 'Value') );

	for my $item ($self -> items -> print)
	{
		$self -> log(info => sprintf($format, $$item{count}, $$item{type}, $$item{name}, decode('utf-8', $$item{value}) ) );
	}

} # End of report.

# ------------------------------------------------

sub run
{
	my($self, %args) = @_;
	my($handler) = MarpaX::Languages::SVG::Parser::XMLHandler -> new
	(
		logger          => $self -> logger,
		input_file_name => $self -> input_file_name,
	);

	$self -> items -> push(@{$handler -> items -> print});
	$self -> save;
	$self -> report;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# ------------------------------------------------

sub save
{
	my($self) = @_;
	my($output_file_name) = $self -> output_file_name;

	if ($output_file_name)
	{
		my($csv) = Text::CSV -> new({binary => 1, eol => $/});

		open(my $fh, '>', $output_file_name);

		$csv -> print($fh, ['Count', 'Type', 'Name', 'Value']);

		for my $item ($self -> items -> print)
		{
			$csv -> print($fh, [$$item{count}, $$item{type}, $$item{name}, decode('utf-8', $$item{value})]);
		}

		close $fh;

		$self -> log(debug => "Wrote $output_file_name");
	}

} # End of save.

# ------------------------------------------------

sub test
{
	my($self, %args) = @_;

	# Remove comment lines.

	my(@data)    = grep{! /^#/} path($self -> input_file_name) -> lines_utf8;
	my($handler) = MarpaX::Languages::SVG::Parser::XMLHandler -> new
	(
		logger => $self -> logger,
	);
	$handler -> run_marpa($self -> attribute, join('', @data) );
	$self -> items -> push(@{$handler -> items -> print});
	$self -> report;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of test.

#-------------------------------------------------

1;

=pod

=head1 NAME

C<MarpaX::Languages::SVG::Parser> - A nested SVG parser, using XML::SAX and Marpa::R2

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use MarpaX::Languages::SVG::Parser;

	# ---------------------------------

	my(%option) =
	(
		input_file_name => 'data/ellipse.01.svg',
	);
	my($parser) = MarpaX::Languages::SVG::Parser -> new(%option);
	my($result) = $parser -> run;

	die "Parse failed\n" if ($result == 1);

	for my $item (@{$parser -> items -> print})
	{
		print sprintf "%-16s  %-16s  %s\n", $$item{type}, $$item{name}, $$item{value};
	}

This script ships as scripts/synopsis.pl. Run it as:

	shell> perl -Ilib scripts/synopsis.pl

See also scripts/parse.file.pl for code which takes command line parameters. For help, run:

	shell> perl -Ilib scripts/parse.file.pl -h

=head1 Description

C<MarpaX::Languages::SVG::Parser> uses L<XML::SAX|XML::SAX::Base> and L<Marpa::R2> to parse SVG into an array of
hashrefs.

L<XML::SAX|XML::SAX::Base> parses the input file, and then certain tags' attribute values are parsed by L<Marpa::R2>.
The attribute values treated specially each have their own BNFs. This is why it's called nested parsing.

Examples of these special cases are the path's 'd' attribute and the 'transform' attribute of various tags.

The SVG versions of the attribute-specific BNFs are
L<here|http://savage.net.au/Perl-modules/html/marpax.languages.svg.parser/>.

See the L</FAQ> for details.

=head1 Installation

Install C<MarpaX::Languages::SVG::Parser> as you would for any C<Perl> module:

Run:

	cpanm MarpaX::Languages::SVG::Parser

or run:

	sudo cpan MarpaX::Languages::SVG::Parser

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

C<new()> is called as C<< my($parser) = MarpaX::Languages::SVG::Parser -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Languages::SVG::Parser>.

Key-value pairs accepted in the parameter list (see also the corresponding methods
[e.g. L</input_file_name([$string])>]):

=over 4

=item o input_file_name => $string

The names the input file to be parsed.

When calling L</run(%args)> this is an SVG file (e.g. data/*.svg).

But when calling L</test(%args)>, this is a text file (e.g. data/*.dat).

This option is mandatory.

Default: ''.

=item o logger => aLog::HandlerObject

By default, an object of type L<Log::Handler> is created which prints to STDOUT,
but given the default setting (maxlevel => 'info'), nothing is actually printed.

See C<maxlevel> and C<minlevel> below.

Set C<logger> to '' (the empty string) to stop a logger being created.

Default: undef.

=item o maxlevel => logOption1

This option affects L<Log::Handler> objects.

See the L<Log::Handler::Levels> docs.

Since the L</report()> method is always called and outputs at log level C<info>, the first of these produces no output,
whereas the second lists all the parse results. The third adds a tiny bit to the output.

	shell> perl -Ilib scripts/parse.file.pl -i data/ellipse.01.svg
	shell> perl -Ilib scripts/parse.file.pl -i data/ellipse.01.svg -max info
	shell> perl -Ilib scripts/parse.file.pl -i data/ellipse.01.svg -max debug

The extra output produced by C<debug> includes the input file name and the string which L<Marpa::R2> is trying to parse.
This helps debug the BNFs themselves.

Default: 'notice'.

=item o minlevel => logOption2

This option affects L<Log::Handler> object.

See the L<Log::Handler::Levels> docs.

Default: 'error'.

No lower levels are used.

=item o output_file_name => $string

The names the CSV file to be written.

Note: This name is only used when calling L</run(%args)>. It is of course ignored when calling L</test(%args)>.

If not set, nothing is written.

See data/circle.01.csv and data/utf8.01.csv, which were created by running:

	shell> perl -Ilib scripts/parse.file.pl -i data/circle.01.svg -o data/circle.01.csv
	shell> perl -Ilib scripts/parse.file.pl -i data/utf8.01.svg   -o data/utf8.01.csv

Default: ''.

=back

=head1 Methods

=head2 attribute($attribute)

Get or set the name of the attribute being processed.

This is only used in testing, in calls from scripts/test.file.pl and (indirectly) scripts/test.fileset.pl.

It is needed because the test files, data/*.dat, do not contain tag/attribute names, and hence the code needs
to be told explicitly which attribute it is parsing.

Note: C<attribute> is a parameter to new().

=head2 input_file_name([$string])

Here, the [] indicate an optional parameter.

Get or set the name of the file to parse.

When calling L</run(%args)> this is an SVG file (e.g. data/*.svg).

But when calling L</test(%args)>, this is a text file (e.g. data/*.dat).

Note: C<input_file_name> is a parameter to new().

=head2 item_count([$new_value])

Here, the [] indicate an optional parameter.

Get or set the counter used to populate the C<count> key in the hashref in the array of parsed tokens.

Used internally.

See the L</FAQ> for details.

=head2 items()

Returns the instance of L<Set::Array> which manages the array of hashrefs holding the parsed tokens.

$object -> items -> print returns an array ref.

See L<MarpaX::Languages::SVG::Parser/Synopsis> for sample code.

See also L</new_item($type, $name, $value)>.

=head2 log($level, $s)

Calls $self -> logger -> log($level => $s) if ($self -> logger).

=head2 logger([$log_object])

Here, the [] indicate an optional parameter.

Get or set the log object.

C<$log_object> must be a L<Log::Handler>-compatible object.

To disable logging, just set logger to the empty string.

Note: C<logger> is a parameter to new().

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

Note: C<maxlevel> is a parameter to new().

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

Note: C<minlevel> is a parameter to new().

=head2 new()

This method is auto-generated by L<Moo>.

=head2 new_item($type, $name, $value)

Pushes another hashref onto the stack managed by $self -> items.

See the L</FAQ> for details.

=head2 output_file_name([$string])

Here, the [] indicate an optional parameter.

Get or set the name of the (optional) CSV file to write.

Note: C<output_file_name> is a parameter to new().

=head2 report()

Prints a nicely-formatted report of the C<items> array via the logger.

=head2 run(%args)

The method which does all the work.

C<%args> is a hash which is currently not used.

Returns 0 for a successful parse and 1 for failure.

The code dies if L<Marpa::R2> itself can't parse the given string.

See also L</test(%args)>.

=head2 save()

Save the parsed tokens to a CSV file, but only if an output file name was provided in the call to L</new()>
or to L</output_file_name([$string])>.

=head2 test(%args)

This method is used by scripts/test.fileset.pl, since that calls scripts/test.file.pl, to run tests.

C<%args> is a hash which is currently not used.

Returns 0 for a successful parse and 1 for failure.

See also L</run(%args)>.

=head1 Files Shipped with this Module

=head2 Data Files

These are all shipped in the data/ directory.

=over 4

=item o *.log

The logs of running this on each *.svg file:

	shell> perl -Ilib scripts/parse.file.pl -i data/ellipse.02.svg -max debug > data/ellipse.02.log

The *.log files are generated by scripts/svg2.log.pl.

=item o circle.01.csv

Output from scripts/parse.file.pl

=item o circle.01.svg

Test data for scripts/parse.file.pl

=item o d.bnf

This is the grammar for the 'd' attribute of the 'path' tag.

Note: The module does not read this file. A copy of the grammar is stored at the end of the source code for
L<Marpa::Languages::SVG::Parser::SAXHandler>, and read by L<Data::Section::Simple>.

=item o d.*.dat

Fake data to test d.bnf.

Input for scripts/test.file.pl.

=item o html/d.svg

This is the graph of the grammar d.bnf.

It was generated by scripts/bnf2graph.pl.

=item o ellipse.*.svg

Test data for scripts/parse.file.pl

=item o line.01.svg

Test data for scripts/parse.file.pl

=item o points.bnf

This grammar is for both the polygon and polyline 'points' attributes.

=item o points.*.dat

Fake data to test points.bnf.

Input for scripts/test.file.pl.

=item o polygon.01.svg

Test data for scripts/parse.file.pl

=item o polyline.01.svg

Test data for scripts/parse.file.pl

=item o preserveAspectRatio.bnf

This grammar is for the 'preserveAspectRatio' attribute of various tags.

=item o preserveAspectRatio.*.dat

Fake data to test preserveAspectRatio.bnf.

Input for scripts/test.file.pl.

=item o preserveAspectRatio.01.svg

Test data for scripts/parse.file.pl

=item o html/preserveAspectRatio.svg

This is the graph of the grammar preserveAspectRatio.bnf.

It was generated by scripts/bnf2graph.sh.

=item o rect.*.svg

Test data for scripts/parse.file.pl

=item o transform.bnf

This grammar is for the 'transform' attribute of various tags.

=item o transform.*.dat

Fake data to test transform.bnf.

Input for scripts/test.file.pl.

=item o utf8.01.csv

Output from scripts/parse.file.pl

=item o utf8.01.log

The log of running:

	shell> perl -Ilib scripts/parse.file.pl -i data/utf8.01.svg -max debug > data/utf8.01.log

=item o utf8.01.svg

Test data for scripts/parse.file.pl

=item o viewBox.bnf

This grammar is for the 'viewBox' attribute of various tags.

=item o viewBox.*.dat

Fake data to test viewBox.bnf.

Input for scripts/test.file.pl.

=item o html/viewBox.svg

This is the graph of the grammar viewBox.bnf.

It was generated by scripts/bnf2graph.sh.

=back

=head2 Scripts

These are all shipped in the scripts/ directory.

=over 4

=item o bnf2graph.pl

Finds all data/*.bnf files and converts them into html/*.svg.

	shell> perl -Ilib scripts/bnf2graph.pl

Requires L<MarpaX::Grammar::GraphViz2>.

=item o copy.config.pl

This is for use by the author. It just copies the config file out of the distro, so the script generate.demo.pl
(which uses HTML template stuff) can find it.

=item o find.config.pl

This cross-checks the output of copy.config.pl.

=item o float.pl

This was posted by Jean-Damien Durand on the L<Marpa Google Group|https://groups.google.com/forum/#!forum/marpa-parser>,
as a demonstration of a grammar for parsing floats and hex numbers.

=item o generate.demo.pl

Run by generate.demo.sh.

Input files are data/*.bnf and html/*.svg. Output file is html/*.html.

=item o generate.demo.sh

Runs generate.demo.pl and then copies html/* to my web server's doc dir ($DR).

=item o number.pl

This also was posted by Jean-Damien Durand on the L<Marpa Google Group|https://groups.google.com/forum/#!forum/marpa-parser>,
as a demonstration of a grammar for parsing floats and integers, and binary, octal and hex numbers.

=item o parse.file.pl

This is the script you'll probably use most frequently. Run with '-h' for help.

=item o pod2html.sh

This lets me quickly proof-read edits to the docs.

=item o svg2log.pl

Runs parse.file.pl on each data/*.svg file and saves the output in data/*.log.

=item o synopsis.pl

The code as per the L</Synopsis>.

=item o t/test.fake.data.t

A test script. It parses data/*.dat, which are not SVG files, but just contain attribute value data.

=item o t/test.real.data.t

A test script. It parses data/*.svg, which are SVG files, and compares them to the shipped files data/*.log.

=item o test.file.pl

This runs the code on a single test file (data/*.dat, I<not> an svg file). Try:

	shell> perl -Ilib scripts/test.file.pl -a d -i data/d.30.dat -max debug

=item o test.fileset.pl

This runs the code on a set of files (data/d.*.dat, data/points.*.dat or data/transform.*.dat). Try:

	shell> perl -Ilib scripts/test.fileset.pl -a transform -max debug

=item o t/version.t

A test script.

=back

=head1 FAQ

See also L<MarpaX::Languages::SVG::Parser::Actions/FAQ>.

=head2 What exactly does this module do?

It parses SVG files (using L<XML::SAX|XML::SAX::Base>), and applies special parsing (using L<Marpa::R2>) to certain
attributes of certain tags.

The output is an array of hashrefs, whose structure is described below.

=head2 Which SVG attributes are treated specially by this module?

=over 4

=item o d

This is the 'd' attribute of the 'path' tag.

=item o points

This is the 'points' attribute of both the 'polygon' and 'polyline' tags.

=item o preserveAspectRatio

Various tags can have the 'preserveAspectRatio' attribute.

=item o transform

Various tags can have the 'transform' attribute.

=item o viewBox

Various tags can have a 'viewBox' attribute.

=back

Each of these special cases has its own Marpa-style BNF.

The SVG versions of the attribute-specific BNFs are
L<here|http://savage.net.au/Perl-modules/html/marpax.languages.svg.parser/>.

=head2 Where are the specs for SVG and the BNFs?

L<W3C's SVG specs|http://www.w3.org/TR/SVG11/>. In particular, see L<paths|http://www.w3.org/TR/SVG11/paths.html> and
L<shapes|http://www.w3.org/TR/SVG11/shapes.html>.

The BNFs have been translated into the syntax used by L<Marpa::R2>. See L<Marpa::R2::Scanless::DSL> for details.

These BNFs are actually stored at the end of the source code of L<MarpaX::Languages::SVG::Parser::SAXHandler>,
and loaded one at a time into Marpa using that fine module L<Data::Section::Simple>.

Also, the BNFs are shipped in data/*.bnf, and in html/*.svg.

=head2 Is the stuff at the start of the SVG file preserved in the array?

If by 'stuff' you mean:

	<?xml version="1.0" standalone="no"?>
	<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
		"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

Then, no.

I could not get the xml_decl etc events to fire using L<XML::SAX> V 0.99 and L<XML::SAX::ParserFactory> V 1.01.

=head2 Why don't you capture comments?

Because Perl instantly segfaults if I try. Code tried in SAXHandler.pm:

	sub comment
	{
		my($self, $element) = @_;
		my($comment) = $$element{Data};

		$self -> log(debug => "Comment: $comment");  # Prints ok.
		$self -> new_item('comment', '-', $comment); # Segfaults.

	}	# End of comment.

Hence - No comment.

=head2 How do I get access to this array?

The L</Synopsis> contains a runnable program, which ships as scripts/synopsis.pl.

=head2 How is the parser's output stored in RAM?

It is stored in an array of hashrefs managed by the L<Set::Array> module.

The hashref structure is documented in the next item.

Using L<Set::Array> is much simpler than using an arrayref. Compare:

	$self -> items -> push
		({
			count => $self -> item_count,
			name  => $name,
			type  => $type,
			value => $value,
		});

With:

	$self -> items([]);
	...
	my($araref) = $self -> items;
	push @$araref,
		{
			count => $self -> item_count,
			name  => $name,
			type  => $type,
			value => $value,
		};
	$self -> items($araref);

=head2 What exactly is the structure of the hashrefs output by the parser?

Firstly, since the following text may be confusing, the very next item in this FAQ,
L</Annotated output>, is designed to clarify things.

Also, it may be necessary to study data/*.log to fully grasp this structure.

Each hashref has these (key => value) pairs:

=over 4

=item o count => $integer

This simply counts the number of the hashref within the array, starting from 1.

=item o name => $string

=over 4

=item o tags and attributes

If the type's C<value> matches /^(attribute|tag)$/, then this is the tag name or attribute name from the SVG.

Note: The SAX parser used, L<XML::SAX|XML::SAX::Base>, outputs these names with a '{}' prefix. The code strips this
prefix.

However, for other items, where the '{...}' is I<not> empty, the specific string is left intact. See data/utf8.01.log
for this sample:

	Item  Type              Name              Value
	   1  tag               svg               open
	   2  attribute         {http://www.w3.org/2000/xmlns/}xlink  http://www.w3.org/1999/xlink
	...

You have been warned.

=item o Parser-generated tokens

In the case that this current array element has been generated by parsing the C<value> of the attribute,
the C<name's> value depends on the value of the C<type> field.

In all such cases, the array contains a hashref with the C<name> 'raw', and with the C<value> being the tag's
original value.

The elements which follow the one C<named> 'raw' are the output of Marpa parsing the value.

=back

=item o type => $string

This key can take the following values:

=over 4

=item o attribute

This is an attribute for the most-recently opened tag.

The C<name> and C<value> fields are for an attribute which has I<not> been specially parsed.

The next element in the array is necessarily another token from the SVG.

See C<raw> for the other case (i.e. compared to C<attribute>).

=item o boolean

The C<value> must be 0 or 1.

The C<name> field in this case will be a counter of parameters for the preceeding C<command> (see next point).

=item o command

The C<name> field is the letter (Mm, ..., Zz) for the command itself. In these cases, the C<value> is '-'.

Note: As of V 1.01, in the hashref returned by the C<action> sub C<command>, the C<value> is actually an arrayref
of the commands parameters. In V 1.00, the C<name> was '-' and the C<value> was the commany letter. This change
was made when I stopped pushing hashrefs onto a stack, and converted the return value of the sub from scalar to
hashref.

=item o content

This is the text content for the most recently opened, but still unclosed, tag. It may be the empty string.
Likewise, it may contain any number of newlines, since it's copied faithfully from the input *.svg file.

It will actually be followed by an array element flagging the closing of the tag it belongs to.

=item o float

Any float.

The C<name> field in this case will be a counter of parameters for the preceeding C<command>.

=item o integer

Any integer, but probably always 0, because of the way Marpa handles the BNF.

The C<name> field in this case will be a counter of parameters for the preceeding C<command>.

=item o raw

The C<name> and C<value> fields are for an attribute which has been specially parsed.

The next element in the array is necessarily I<not> another token from the SVG.

Rather, the array elements following this one are output from the Marpa-based parse of the value in the C<current>
hashref's C<value> key.

What this means is that if you are scanning the array, and detect a C<type> of C<raw>, all elements in the array
(after this one), up to the next item of C<type =~ /^(attribute|content|raw|tag)$/>, must be parameters output from the parse
of the value in the  C<current> hashref's C<value> key.

There is one exception to the claim that 'The next element in the array is necessarily I<not> another token from the SVG.'
Consider:

	<polygon points="350,75  379,161 469,161 397,215
	423,301 350,250 277,301 303,215 231,161 321,161z" />

The 'z' (which itself takes no parameters) at the end of the points is the last thing output for this tag, so the
close tag item will be next array element.

See C<attribute> for the other case (i.e. compared to C<raw>).

=item o tag

The C<name> and C<value> fields are for a tag.

The C<name> is the name of the tag, and the C<value> is 'open' or 'close'.

=back

=item o value => $string

The interpretation of this string depends on the value of the C<type> key. Basically:

In the case of tags, this string is either 'open' or 'close'.

In the case of attributes, it is the attribute's value.

In the case of parsed attributes, it is an SVG command or one of that command's parameters.

See the next FAQ item for details.

=back

=head2 Annotated output

Here is a fragment of data/ellipse.02.svg:

	<path d="M300,200 h-150 a150,150 0 1,0 150,-150 z"
		fill="red" stroke="blue" stroke-width="5" />

And here is the output from the built-in reporting mechanism (see data/ellipse.02.log):

	Item  Type        Name              Value
	   1  tag         svg               open
		...
	  27  tag         path              open
	  28  raw         d                 M300,200 h-150 a150,150 0 1,0 150,-150 z
	  29  command     M                 -
	  30  float       1                 300
	  31  float       2                 200
	  32  command     h                 -
	  33  float       1                 -150
	  34  command     a                 -
	  35  float       1                 150
	  36  float       2                 150
	  37  integer     3                 0
	  38  boolean     4                 1
	  39  boolean     5                 0
	  40  float       6                 150
	  41  float       7                 -150
	  42  command     z                 -
	  43  attribute   fill              red
	  44  attribute   stroke            blue
	  45  attribute   stroke-width      5
	  46  content     path
	  47  tag         path              close
		...
	  66  tag         svg               close

Let's go thru it:

=over 4

=item o Item 27 is the open tag for the path

	Type:  tag
	Name:  path
	Value: open

=item o Item 28 is the path's 1st attribute, 'd'

	Type:  raw
	Name:  d
	Value: M300,200 h-150 a150,150 0 1,0 150,-150 z

But since the C<type> is C<raw> we know both that it's an attribute, and that it must be followed by the parsed
output of that value.

Note: Attributes are reported in sorted order, but the parameters after parsing the attributes' values cannot be,
because drawing the coordinates of the value is naturally order-dependent.

=item o Item 29

	Type:   command
	Name:   M
	Values: '-'

This in turn is followed by its respective parameters, if any.

Note: 'Z' and 'z' have no parameters.

=item o Item 30 .. 31

Two floats. Commas are discarded in the parsing of all special values.

Also, you'll notice they are numbered for your convenience by the C<name> key in their hashrefs.

=item o Item 32

	Type:   command
	Name:   h
	Values: '-'

=item o Item 33

This is the float which belongs to 'h'.

=item o Item 34

	Type:   command
	Name:   a
	Values: '-'

=item o Items 35 .. 41

The 7 parameters of the 'a' command. You'll notice the parser calls 0 an integer rather than a float.
SVG does not care, and neither should you. But, since the code knows it is, it might as well tell you.

The two Boolean  flags are picked up explicitly, and the code tells you that, too.

=item o Item 42

	Type:   command
	Name:   z
	Values: '-'

As stated, it has no following parameters.

=item o Items 43 .. 46

The remaining attributes of the 'path'. None of these are treated specially.

=item o Item 47 is the close tag for the path

	Type:  tag
	Name:  path
	Value: close

And, yes, this does mean self-closing tags, such as 'path', have 2 items in the array, with C<values> of 'open'
and 'close'. This allows code scanning the array to know absolutely where the data for the tag finishes.

=back

=head2 Why did you use L<XML::SAX::ParserFactory> to parse the SVG?

I find the SAX mechanism for handling XML particularly easy to work with.

I did start with L<XML::Rules>, a great module, for the debugging of the BNFs, but the problem is that too many tags
shared attributes (see 'transform' etc above), which made the code awkward.

Also, that module triggers a callback for closing a tag before triggering the call to process the attributes defined
by the opening of that tag. This adds yet more complexity.

=head2 How are file encodings handled?

I let L<File::Slurper> choose the encoding.

For output, scripts/parse.file.pl uses the pragma:

	use open qw(:std :utf8); # Undeclared streams in UTF-8.

This is needed if reading files encoded in utf-8, such as data/utf8.01.svg, and at the same time trying to print the
parsed results to the screen by calling L</maxlevel([$string])> with C<$string> set to C<info> or C<debug>.

Without this pragma, data/utf8.01.svg gives you the dread 'Wide character in print...' message.

The pragma is not in the module because it's global, and the end user's program may not want it at all.

Lastly, I have unilaterally set the utf8 attribute used by L<Log::Handler>. This is harmless for non-utf-8 file,
and is vital for data/utf8.01.svg and similar end-user files. It allows the log output (STDOUT) to be redirected.
And indeed, this is what some of the tests do.

=head1 TODO

This lists some possibly nice-to-have items, but none of them are important:

=over 4

=item o Store BNF's in an array

This could be done by reading them once using L<Data::Section::Simple>, in L<MarpaX::Languages::SVG::Parser::SAXHandler>,
and caching them, rather than re-reading them each time a BNF is required.

=item o Re-write grammars to do left-recursion

Well, Jeffrey suggested this, but I don't have the skills (yet).

=back

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/MarpaX-Languages-SVG-Parser>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Languages::SVG::Parser>.

=head1 Credits

The BNFs are partially based on the L<W3C's SVG specs|http://www.w3.org/TR/SVG11/>, and partially (for numbers) on
2 programs posted by Jean-Damien Durand to L<the Marpa Google group|https://groups.google.com/forum/#!forum/marpa-parser>.
The thread is titled 'Space (\s) problems with my grammar'.

Note: Some posts (as of 2013-10-16) in that thread can't be displayed. This may be a temporary issue.
See scripts/float.pl and scripts/number.pl for Jean-Damien's original code, which were of considerable help to me.

Specifically, I use number.pl for integers and floats, with these adjustments:

=over 4

=item o The code did not handle negative numbers, but an optional sign was already defined, so that was easy

=item o The code did not handle 0

=item o The code included hex and octal and binary numbers, which I did not need

=back

=head1 Author

L<MarpaX::Languages::SVG::Parser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
