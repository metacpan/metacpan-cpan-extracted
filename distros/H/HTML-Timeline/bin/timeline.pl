#!/usr/bin/env perl
#
# Name:
#	timeline.pl.
#
# Description:
#	Convert a Gedcom file into a Timeline file.
#
# Output:
#	o Exit value
#
# History Info:
#	Rev		Author		Date		Comment
#	1.00   	Ron Savage	20080811	Initial version <ron@savage.net.au>

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use HTML::Timeline;

# --------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option, @option);

push @option,
'ancestors',
'everyone',
'gedcom_file=s',
'help',
'include_spouses',
'missing_as_table',
'output_dir=s',
'root_person=s',
'template_dir=s',
'template_name=s',
'timeline_height=i',
'url_for_xml=s',
'validate_gedcom_file',
'verbose',
'web_page=s',
'xml_file=s';

if ($option_parser -> getoptions(\%option, @option) )
{
	pod2usage(1) if ($option{'help'});

	exit HTML::Timeline -> new(options => \%option) -> run();
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

timeline.pl - Convert a Gedcom file into a Timeline file

=head1 SYNOPSIS

timeline.pl [options]

	Options:
	-ancestors $Boolean
	-everyone $Boolean
	-gedcom_file $a_file_name
	-help
	-include_spouses $Boolean
	-missing_as_table $Boolean
	-output_dir $a_dir_name
	-root_person $a_personal_name
	-template_dir $a_dir_name
	-template_name $a_file_name
	-timeline_height $an_integer
	-url_for_xml $a_url
	-validate_gedcom_file $Boolean
	-verbose $Boolean
	-web_page $a_file_name
	-xml_file $a_file_name

Exit value:

=over 4

=item o Zero

Success.

=item o Non-Zero

Error.

=back

=head1 OPTIONS

=over 4

=item o ancestors $Boolean

If this option is set to 1, the ancestors of the root_person (see below) are processed.

If this option is not used, their descendents are processed.

Default: 0.

=item o everyone $Boolean

If this option is set to 1, everyone is processed, and the root_person (see below) is ignored.

If this option is not used, the root_person is processed.

Default: 0.

=item o gedcom_file $a_file_name

The name of your Gedcom input file.

Default: 'bach.ged' (so timeline.pl runs OOTB [out-of-the-box]).

=item o help

Print help and exit.

=item o include_spouses $Boolean

If this option is set to 1, and descendents are processed and spouses are included.

If this option is not used, spouses are ignored.

Default: 0.

=item o missing_as_table $Boolean

If this option is set to 1, people with missing birthdates are listed under the timeline, in a
table.

If this option is not used, such people appear on the timeline, with today's date as their
birthdate.

Default: 0.

=item o output_dir $a_dir_name

If this option is used, the output HTML and XML files will be created in this directory.

Default: '';

=item o root_person $a_personal_name

The name of the person on which to base the timeline.

Default: 'Johann Sebastian Bach'.

=item o template_dir $a_dir_name

If this option is used, HTML::Template will look in this directory for 'timeline.tmpl'.

If this option is not used, the current directory will be used.

Default: ''.

=item o template_name $a_file_name

If this option is used, HTML::Template will look for a file of this name.

Default: 'timeline.tmpl'.

=item o timeline_height $an_integer

If this option is used, the height of the timeline is set to this value in pixels.

Default: 500.

=item o url_for_xml $a_url

If this option is used, it becomes the prefix of the name of the output XML file written into timeline.html.

Warning: I could not get the Timeline package to load the XML file when using /search for this option,
even though the timeline.html was in Apache's doc root, and timeline.xml was in the /search dir below
the doc root. So don't use this option until someone debugs it.

Default: ''.

=item o validate_gedcom_file $Boolean

Call validate() on the Gedcom object if set to 1. This validates the Gedcom file.

Default: 0.

=item o verbose $Boolean

Print verbose messages if set to 1.

Default: 0.

=item o web_page $a_file_name

If this option is used, it specfies the name of the HTML file to write.

See the output_dir option for where the file is written.

Default: 'timeline.html'.

=item o xml_file $a_file_name

The name of your output XML file.

Default: 'timeline.xml'.

Note: The name of the output XML file is embedded in timeline.html, at line 28.
You will need to edit this file if you do not use 'timeline.xml' as your output XML file.

=back

=head1 DESCRIPTION

timeline.pl converts a Gedcom file into a Timeline file.

See http://simile.mit.edu/timeline for details.

=cut
