package HTML::Timeline;

use strict;
use warnings;

require 5.005_62;

# Warning: This list must include format and gedobj, unlike the list in sub new(),
# since those 2 special cases are attributes which are not available to the caller.

use accessors::classic qw/
ancestors
everyone
format
gedcom_file
gedobj
include_spouses
missing_as_table
output_dir
root_person
template_dir
template_name
timeline_height
url_for_xml
validate_gedcom_file
verbose
web_page
xml_file
/;
use Carp;

use Gedcom;
use Gedcom::Date;

use HTML::Template;

use Path::Class;

our $VERSION = '1.10';

# -----------------------------------------------

sub clean_persons_name
{
	my($self, $name) = @_;

	# Find /s everwhere (/g) and remove them.

	$name =~ s|/||g;

	return $name;

} # End of clean_persons_name.

# -----------------------------------------------

sub generate_xml_file
{
	my($self, $people)   = @_;
	my($missing_message) = 'People excluded because of missing birth dates: ';
	my($todays_date)     = 1900 + (localtime)[5];

	# Process each person.

	my($birth_date);
	my($death_date);
	my($earliest_date, $extracted_date);
	my(@missing);
	my($name, %notes);
	my($person);
	my($result);
	my(%seen);
	my(@xml);

	push @xml, '<data>';

	for $person (@$people)
	{
		$name = $person -> get_value('name');

		if ($seen{$name})
		{
			$self -> log(sprintf($self -> format, 'Note', "$name appears twice in the input file") );

			next;
		}

		$seen{$name} = 1;
		$name        = $self -> clean_persons_name($name);
		$birth_date  = $person -> get_value('birth date');
		$death_date  = $person -> get_value('death date');

		# Process birth dates.

		if (Gedcom::Date -> parse($birth_date) )
		{
			$notes{$name} = '';

			if ($earliest_date && ($birth_date < $earliest_date) )
			{
				$earliest_date = $birth_date;
			}
			elsif (! $earliest_date)
			{
				$earliest_date = $birth_date;
			}
		}
		elsif ($birth_date)
		{
			$notes{$name}    = "Fuzzy birthdate: $birth_date";
			($extracted_date = $birth_date) =~ /(\d{4})/;

			if ($extracted_date)
			{
				$birth_date = $extracted_date;
			}

			if ($earliest_date && ($birth_date < $earliest_date) )
			{
				$earliest_date = $birth_date;
			}
			elsif (! $earliest_date)
			{
				$earliest_date = $birth_date;
			}
		}
		else
		{
			push @missing,
			{
				death_date => $death_date,
				name       => $name,
			};

			next;
		}

		# Process death dates.

		if (Gedcom::Date::parse($death_date) )
		{
			# James Riley Durbin's death date (FEB 1978) is parseable by ParseDate
			# but not Similie Timeline, so we only extract the year.

			if ($name eq 'James Riley Durbin')
			{
				($extracted_date = $death_date) =~ /(\d{4})/;

				if ($extracted_date)
				{
					$death_date = $extracted_date;
				}
			}
		}
		elsif ($death_date)
		{
			($extracted_date = $death_date) =~ /(\d{4})/;

			if ($extracted_date)
			{
				$death_date = $extracted_date;
			}
		}

		if ($birth_date && $death_date)
		{
			push @xml, qq|  <event title="$name" start="$birth_date" end="$death_date">$notes{$name}</event>|;
		}
		elsif ($birth_date)
		{
			push @xml, qq|  <event title="$name" start="$birth_date">$notes{$name}</event>|;
		}
	}

	if ( ($self -> missing_as_table == 0) && ($#missing >= 0) )
	{
		my($missing) = join(', ', map{$$_{'name'} } @missing);

		push @xml, qq|  <event title="Missing" start="$todays_date" end="$todays_date">$missing</event>|;
	}

	push @xml, '</data>';

	# Write timeline.xml.

	my($output_dir)       = $self -> output_dir;
	my($output_file_name) = $self -> xml_file;

	if ($output_dir)
	{
		$output_file_name = file($output_dir, $output_file_name);
	}

	open(my $fh, "> $output_file_name") || Carp::croak "Can't open(> $output_file_name): $!";
	print $fh join("\n", @xml), "\n";
	close $fh;

	$self -> log(sprintf($self -> format, 'Created', $output_file_name) );

	# Write timeline.html.

	my($template)     = HTML::Template -> new(filename => $self -> template_name, path => $self -> template_dir );
	my($url_for_xml)  = $self -> url_for_xml;
	$output_file_name = $self -> xml_file;

	if ($url_for_xml)
	{
		$output_file_name = "$url_for_xml/$output_file_name"; # No Path::Class here.
	}

	$template -> param(earliest_date    => $earliest_date);
	$template -> param(missing_as_table => $self -> missing_as_table);
	$template -> param(timeline_height  => $self -> timeline_height);
	$template -> param(xml_file_name    => $output_file_name);

	if ($#missing >= 0)
	{
		if ($self -> missing_as_table == 1)
		{
			$template -> param(missing      => $missing_message);
			$template -> param(missing_loop => [map{ { death_date => $$_{'death_date'}, name => $$_{'name'} } } @missing]);
		}
		else
		{
			$template -> param(todays_date => $todays_date);
		}
	}

	$output_file_name = $self -> web_page;

	if ($output_dir)
	{
		$output_file_name = file($output_dir, $output_file_name);
	}

	open($fh, "> $output_file_name") || Carp::croak "Can't open(> $output_file_name): $!";
	print $fh $template -> output;
	close $fh;

	$self -> log(sprintf($self -> format, 'Created', $output_file_name) );

} # End of generate_xml_file.

# -----------------------------------------------

sub get_spouses
{
	my($self, $people) = @_;
	my($spouses)       = [];

	my($person);
	my($spouse);

	for my $person (@$people)
	{
		$spouse = $person -> spouse;

		if ($spouse)
		{
			push @$spouses, $spouse;
		}
	}

	return $spouses;

} # End of get_spouses.

# -----------------------------------------------

sub log
{
	my($self, $message) = @_;

	if ($self -> verbose)
	{
		print STDERR "$message\n";
	}

} # End of log.

# -----------------------------------------------

sub new
{
	my($class, %arg)    = @_;
	my($self)           = bless({}, $class);
	# Warning: This list must not contain: format or gedobj,
	# since these are attributes not available to the caller.
	my(@options)        = (qw/
ancestors
everyone
gedcom_file
include_spouses
missing_as_table
output_dir
root_person
template_dir
template_name
timeline_height
url_for_xml
validate_gedcom_file
verbose
web_page
xml_file
/);

	# Set defaults.

	$self -> ancestors(0);
	$self -> everyone(0);
	$self -> format('%-16s: %s'); # Not in the @options array!
	$self -> gedcom_file('bach.ged');
	$self -> gedobj(''); # Not in the @options array!
	$self -> include_spouses(0);
	$self -> missing_as_table(0);
	$self -> output_dir('');
	$self -> root_person('Johann Sebastian Bach');
	$self -> template_dir('.');
	$self -> template_name('timeline.tmpl');
	$self -> timeline_height(500);
	$self -> url_for_xml('');
	$self -> validate_gedcom_file(0);
	$self -> verbose(0);
	$self -> web_page('timeline.html');
	$self -> xml_file('timeline.xml');

	# Check ~/.timelinerc for more defaults.

	my($resource_file_name) = "$ENV{'HOME'}/.timelinerc";

	if (-e $resource_file_name)
	{
		require "Config/IniFiles.pm";

		my($config)       = Config::IniFiles -> new(-file => $resource_file_name);
		my($section_name) = 'HTML::Timeline';

		if (! $config -> SectionExists($section_name) )
		{
			Carp::croak "Error: Section '$section_name' is missing from $resource_file_name";
		}

		my($option);
		my($value);

		for $option (@options)
		{
			$value = $config -> val($section_name, $option);

			if (defined $value)
			{
				$self -> $option($value);
			}
		}
	}

	# Process user options.

	my($attr_name);

	for $attr_name (@options)
	{
		if (exists($arg{'options'}{$attr_name}) )
		{
			$self -> $attr_name($arg{'options'}{$attr_name});
		}
	}

	if (! -f $self -> gedcom_file)
	{
		Carp::croak 'Cannot find file: ' . $self -> gedcom_file;
	}

	$self -> gedobj
	(
	 Gedcom -> new
	 (
	  callback        => undef,
	  gedcom_file     => $self -> gedcom_file,
	  grammar_version => '5.5',
	  read_only       => 1,
	 )
	);

	if ( ($self->validate_gedcom_file == 1) && ! $self -> gedobj -> validate)
	{
		Carp::croak 'Cannot validate file: ' . $self -> gedcom_file;
	}

	$self -> log('Parameters:');

	for $attr_name (@options)
	{
		$self -> log(sprintf($self -> format, $attr_name, $self -> $attr_name) );
	}

	$self -> log('-' x 50);

	return $self;

}	# End of new.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	$self -> log('Processing:');

	my($root_person) = $self -> gedobj -> get_individual($self -> root_person);
	my($name)        = $self -> clean_persons_name($root_person -> name);

	my(@people);

	if ($self -> everyone == 1)
	{
		@people = $self -> gedobj -> individuals;
	}
	else
	{
		my($method) = $self -> ancestors == 1 ? 'ancestors' : 'descendents';
		@people     = $root_person -> $method;

		$self -> log(sprintf($self -> format, 'Relationship', $method) );

		if ($self -> ancestors == 0)
		{
			# If descendents are wanted, check for spouses.

			if ($self -> include_spouses == 1)
			{
				push @people, @{$self -> get_spouses([$root_person, @people])};
			}
		}
		else
		{
			# If ancestors are wanted, check for siblings.

			push @people, $root_person -> siblings;
		}

		unshift @people, $root_person;
	}

	$self -> generate_xml_file(\@people);
	$self -> log('Success');

	return 0;

} # End of run.

# -----------------------------------------------

1;

=head1 NAME

HTML::Timeline - Convert a Gedcom file into a Timeline file

=head1 Synopsis

	shell> perl bin/timeline.pl -h

=head1 Description

C<HTML::Timeline> is a pure Perl module.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<HTML::Timeline>.

This is the class contructor.

Usage: C<< HTML::Timeline -> new() >>.

This method takes a hashref of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

See the next section for a discussion of the resource file $HOME/.timelinerc,
which can be used to override the default values for options.

Available options:

=over 4

=item ancestors $Boolean

If this option is 1, the ancestors of the root_person (see below) are processed.

If this option is 0, their descendents are processed.

Default: 0.

=item everyone $Boolean

If this option is 1, everyone is processed, and the root_person (see below) is ignored.

If this option is 0, the root_person is processed.

Default: 0.

=item gedcom_file $a_file_name

This takes the name of your input Gedcom file.

Default: 'bach.ged'.

=item include_spouses $Boolean

If this option is 1, and descendents are processed, spouses are included.

If this option is 0, spouses are ignored.

Default: 0.

=item missing_as_table $Boolean

If this option is 1, people with missing birthdates are listed under the timeline, in a table.

If this option is 0, such people appear on the timeline, with a date (today) as their birthdate.

Default: 0.

=item output_dir $a_dir_name

If this option is used, the output HTML and XML files will be created in this directory.

Default: '';

=item root_person $a_personal_name

The name of the person on which to base the timeline.

Default: 'Johann Sebastian Bach'.

=item template_dir $a_dir_name

If this option is used, HTML::Template will look in this directory for 'timeline.tmpl'.

If this option is not used, the current directory will be used.

Default: ''.

=item template_name $a_file_name

If this option is used, HTML::Template will look for a file of this name.

If this option is not used, 'timeline.tmpl' will be used.

Default: ''.

=item url_for_xml $a_url

If this option is used, it becomes the prefix of the name of the output XML file written into
timeline.html.

If this option is not used, no prefix is used.

Default: ''.

=item validate_gedcom_file $Boolean

If set to 1, call validate() on the Gedcom object. This validates the Gedcom file.

Default: 0.

=item verbose $Boolean

Write more or less progress messages to STDERR.

Default: 0.

=item web_page a_file_name

If this option is used, it specfies the name of the HTML file to write.

If this option is not used, 'timeline.html' is written.

See the output_dir option for where the file is written.

Default: 'timeline.html'.

=item xml_file $an_xml_file_name

The name of your XML output file.

Default: 'timeline.xml'.

Note: The name of the XML file is embedded in timeline.html, at line 28.
You will need to edit the latter file if you use a different name for your XML output file.

=back

=head1 The resource file $HOME/.timelinerc

The program looks for a file called $HOME/.timelinerc during execution of the constructor.

If this file is present, the module Config::IniFiles is loaded to process it.

If the file is absent, Config::IniFiles does not have to be installed.

This file must contain the section [HTML::Timeline], after which can follow any number
of options, as listed above.

The option names in the file do I<not> start with hyphens.

If the same option appears two or more times, the I<last> appearence is used to set the value
of that option.

The values override the defaults listed above.

These values are, in turn, overridden by the values passed in to the constructor.

This means that command line options passed in to timeline.pl will override the values
found in $HOME/.timelinerc.

Sample file:

	[HTML::Timeline]
	output_dir=/var/www/html

=head1 Method: log($message)

If C<new()> was called as C<< new({verbose => 1}) >>, write the message to STDERR.

If C<new()> was called as C<< new({verbose => 0}) >> (the default), do nothing.

=head1 Method: run()

Do everything.

See C<examples/timeline.pl> for an example of how to call C<run()>.

=head1 See also

The C<Gedcom> module.

=head1 Running Tests

	perl -I../lib ../bin/timeline.pl -gedcom_file ../examples/bach.ged -output_dir /tmp -template_name ../examples/timeline.tmpl

=head1 Support

Support is via the Gedcom mailing list.

Subscribe via perl-gedcom-subscribe@perl.org.

=head1 Credits

The MIT Simile Timeline project, and others, are at http://code.google.com/p/simile-widgets/.

Its original home is at http://simile.mit.edu/timeline.

Philip Durbin write the program examples/ged2xml.pl, which Ron Savage converted into a module.

Philip also supplied the files examples/bach.* and examples/timeline.html.

Ron Savage wrote bin/timeline.pl.

examples/timeline.xml is the output of that program, using the default options.

=head1 Repository

L<https://github.com/ronsavage/HTML-Timeline>

=head1 Author

C<HTML::Timeline> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2008.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2008, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
