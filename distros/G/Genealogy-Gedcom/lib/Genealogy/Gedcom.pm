package Genealogy::Gedcom;

use strict;
use warnings;

our $VERSION = '0.88';

# --------------------------------------------------

1;

=pod

=head1 NAME

Genealogy::Gedcom - An OS-independent processor for GEDCOM data

=head1 Synopsis

See L<Genealogy::Gedcom::Reader::Lexer>.

=head1 Description

L<Genealogy::Gedcom> provides a processor for GEDCOM data.

See L<The GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/en/Main_Page>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Genealogy::Gedcom> as you would for any C<Perl> module:

Run:

	cpanm Genealogy::Gedcom

or run:

	sudo cpan Genealogy::Gedcom

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

See L<Genealogy::Gedcom::Reader::Lexer>.

=head1 FAQ

=head2 Does this module handle utf8?

Yes. The input files are assumed to be in utf8. Files in ISO-8859-1 work automatically, too.

The default output log also handles utf8.

=head2 Does this module handle ANSEL?

No. ANSEL was an invention before Unicode. Just create a utf-8 encoded file, such as
data/sample.7.ged.

That file was generated from data/GEDCOMANSELTable.xhtml by scripts/parse.sample.7.pl.

Thanx for L<Tamura Jones|http://www.tamurajones.net/GEDCOMANSELTable.xhtml> for creating that web
page.

=head2 How are user-defined tags handled?

In the same way as GEDCOM tags.

They are defined by having a leading '_', as well as same syntax as GEDCOM files. That is:

=over 4

=item o At level 0, they match /(_?(?:[A-Z]{3,4}))/.

=item o At level > 0, they match /(_?(?:ADR[123]|[A-Z]{3,5}))/.

=back

Each user-defined tag is stand-alone, meaning they can't be extended with CONC or CONT tags in the way some GEDCOM tags can.

See data/sample.4.ged.

=head2 How are CONC and CONT tags handled?

Nothing is done with them, meaning e.g. text flowing from a NOTE (say) onto a CONC or CONT is not concatenated.

Currently then, even GEDCOM tags are stand-alone.

=head2 How is the lexed data stored in RAM?

Items are stored in an arrayref. This arrayref is available via the L</items()> method.

This method returns the same data as does L<Genealogy::Gedcom::Reader/items()>.

Each element in the array is a hashref of the form:

	{
	count      => $n,
	data       => $a_string
	level      => $n,
	line_count => $n,
	tag        => $a_tag,
	type       => $a_string,
	xref       => $a_string,
	}

Key-value pairs are:

=over 4

=item o count => $n

Items are numbered from 1 up, so this is the array index + 1.

Note: Blank lines in the input file are skipped.

=item o data => $a_string

This is any data associated with the tag.

Given the GEDCOM record:

	1   NAME Given Name /Surname/

then data will be 'Given Name /Surname/', i.e. the text after the tag.

Given the GEDCOM record:

	1   SUBM @SUBM1@

then data will be 'SUBM1'.

As with xref (below), the '@' characters are stripped.

=item o level => $n

The is the level from the GEDCOM data.

=item o line_count => $n

This is the line number from the GEDCOM data.

=item o tag => $a_tag

This is the GEDCOM tag.

=item o type => $a_string

This is a string indicating what broad class the tag refers to. Values:

=over 4

=item o (Empty string)

Used for various cases.

=item o Address

=item o Concat

=item o Continue

=item o Date

If the type is 'Date', then it has been successfully parsed.

If parsing failed, the value will be 'Invalid date'.

=item o Event

=item o Family

=item o File name

=item o Header

=item o Individual

=item o Invalid date

If the type is 'Date', then it has been successfully parsed.

If parsing failed, the value will be 'Invalid date'.

=item o Link to FAM

=item o Link to INDI

=item o Link to OBJE

=item o Link to SUBM

=item o Multimedia

=item o Note

=item o Place

=item o Repository

=item o Source

=item o Submission

=item o Submitter

=item o Trailer

=back

=item o xref => $a_string

Given the GEDCOM record:

	0 @I82@ INDI

then xref will be 'I82'.

As with data (above), the '@' characters are stripped.

=back

=head2 What validation is performed?

There is no perfect answer as to what should be a warning and what should be an error.

So, the author's philosophy is that unrecoverable states are errors, and the code calls 'die'. See L</Under what circumstances does the code call 'die'?>.

And, the log level 'error' is not used. All validation failures are logged at level warning, leaving interpretation up to the user. See L</How does logging work?>.

Details:

=over 4

=item o Cross-references

Xrefs (pointers) are checked that they point to an xref which exists. Each dangling xref is only reported once.

=item o Dates are validated

=item o Duplicate xrefs

Xrefs which are (potentially) pointed to are checked for uniqueness.

=item o String lengths

Maximum string lengths are checked as per the GEDCOM Specification.

Minimum string lengths are checked as per the value of the 'strict' option to L<new()|Constructor and Initialization>.

=item o Strict 'v' Mandatory

Validation is mandatory, even with the 'strict' option set to 0. 'strict' only affects the minimum string length acceptable.

=item o Tag nesting

Tag nesting is validated by the mechanism of nested method calls, with each method (called tag_*) knowing what tags it handles, and with each nested call handling its own tags.

This process starts with the call to tag_lineage(0, $line) in method L</run()>.

=item o Unexpected tags

The lexer reports the first unexpected tag, meaning it is not a GEDCOM tag and it does not start with '_'.

=back

All validation failures are reported as log messages at level 'warning'.

=head2 What other validation is planned?

Here are some suggestions from L<the mailing list|The Gedcom Mailing List>:

=over 4

=item o Mandatory sub-tags

This means check that each tag has all its mandatory sub-tags.

=item o Natural (not step-) parent must be older than child

=item o Prior art

L<http://www.tamurajones.net/GEDCOMValidation.xhtml>.

=item o Specific values for data attached to tags

Many such checks are possible. E.g. Attribute type (p 43 of L<GEDCOM Specification|http://wiki.webtrees.net/en/Main_Page>)
must be one of: CAST | EDUC | NATI | OCCU | PROP | RELI | RESI | TITL | FACT.

=back

=head2 What other features are planned?

Here are some suggestions from L<the mailing list|The Gedcom Mailing List>:

=over 4

=item o Persistent IDs for individuals

L<A proposal re UUIDs|http://savage.net.au/Perl-modules/html/genealogy/uuid.html>.

=back

=head2 How does logging work?

=over 4

=item o Debugging

When new() is called as new(maxlevel => 'debug'), each method entry is logged at level 'debug'.

This has the effect of tracing all code which processes tags.

Since the default value of 'maxlevel' is 'info', all this output is suppressed by default. Such output is mainly for the author's benefit.

=item o Log levels

Log levels are, from highest (i.e. most output) to lowest: 'debug', 'info', 'warning', 'error'. No lower levels are used. See L<Log::Handler::Levels>.

'maxlevel' defaults to 'info' and 'minlevel' defaults to 'error'. In this way, levels 'info' and 'warning' are reported by default.

Currently, level 'error' is not used. Fatal errors cause 'die' to be called, since they are unrecoverable. See L</Under what circumstances does the code call 'die'?>.

=item o Reporting

When new() is called as new(report_items => 1), the items are logged at level 'info'.

=item o  Validation failures

These are reported at level 'warning'.

=back

=head2 Under what circumstances does the code call 'die'?

=over 4

=item o When there is a typo in the field name passed in to check_length()

This is a programming error.

=item o When an input file is not specified

This is a user (run time) error.

=item o When there is a syntax error in a GEDCOM record

This is a user (data preparation) error.

=back

=head2 How do I change the version of the GEDCOM grammar supported?

By sub-classing.

=head1 TODO

=over 4

=item o Tighten validation

=back

=head2 o What is the purpose of this set of modules?

It's the basis of a long-term project to write a new interface to GEDCOM files.

=head2 How are the modules related?

=over 4

=item o Genealogy::Gedcom

This is a dummy module at the moment, which just occupies the namespace. It holds the FAQ though.

=item o Genealogy::Gedcom::Reader

This employs the lexer to do the work. It may one day use the new (currently non-existent) parser
too.

=item o Genealogy::Gedcom::Reader::Lexer

This does the real work for finding tokens within GEDCOM files.

Run: perl scripts/lex.pl -help

=back

=head1 Programs Supplied as part of this Package

=over 4

=item o find.unused.limits.pl

Helps me debug code.

=item o lex.pl

Runs the lexer on a file and reports some statictics. Try lex.pl -h.

=item o parse.sample.7.pl

This reads data/sample.7.html and writes data/sample.7.ged.

=item o test.all.dates.pl

Reads all files in data/ and checks that any each date is valid.

=back

=head1 Repository

L<https://github.com/ronsavage/Genealogy-Gedcom>

=head1 See Also

L<Genealogy::Gedcom::Date>.

<Gedcom::Date>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who worked on L<Gedcom>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy::Gedcom>.

=head1 Author

L<Genealogy::Gedcom> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
