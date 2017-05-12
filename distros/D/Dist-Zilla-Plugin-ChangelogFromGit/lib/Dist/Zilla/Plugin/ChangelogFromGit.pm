package Dist::Zilla::Plugin::ChangelogFromGit;
$Dist::Zilla::Plugin::ChangelogFromGit::VERSION = '0.016';
# Indent style:
#   http://www.emacswiki.org/emacs/SmartTabs
#   http://www.vim.org/scripts/script.php?script_id=231
#
# vim: noexpandtab

# ABSTRACT: Write a Changes file from a project's git log.

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use DateTime;
use DateTime::Infinite;
use Software::Release;
use Software::Release::Change;
use Git::Repository::Log::Iterator;
use Dist::Zilla::File::InMemory;
use IPC::Cmd qw/run/;

has max_age => (
	is      => 'ro',
	isa     => 'Int',
	default => 365,
);

has tag_regexp => (
	is      => 'ro',
	isa     => 'Str',
	default => '^v(\\d+\\.\\d+)$',
);

has file_name => (
	is      => 'ro',
	isa     => 'Str',
	default => 'CHANGES',
);

has wrap_column => (
	is      => 'ro',
	isa     => 'Int',
	default => 74,
);

has debug => (
	is      => 'ro',
	isa     => 'Int',
	default => 0,
);

has releases => (
	is      => 'rw',
	isa     => 'ArrayRef[Software::Release]',
	traits  => [ 'Array' ],
	handles => {
		push_release  => 'push',
		sort_releases => 'sort_in_place',
		release_count => 'count',
		get_release   => 'get',
		all_releases  => 'elements',
	},
	default => sub { [] },
);

has skipped_release_count => (
	is      => 'rw',
	isa     => 'Int',
	default => 0,
	traits  => [ 'Number' ],
	handles => {
		add_skipped_release => 'add',
	},
);

has earliest_date => (
	is      => 'ro',
	isa     => 'DateTime',
	lazy    => 1,
	default => sub {
		my $self = shift();
		DateTime->now()->subtract(days => $self->max_age())->truncate(to=> 'day');
	},
);

has include_message => (
    is  => 'ro',
    isa => 'Str',
);

has exclude_message => (
    is  => 'ro',
    isa => 'Str',
);

sub gather_files {
	my ($self, $arg) = @_;

	# Find all release tags back to the earliest changelog date.

	my $earliest_date = $self->earliest_date();

	my @tags = $self->rungit([qw/git tag/]);
	my @head_version_per_tag = ();

	{
		my $tag_pattern = $self->tag_regexp();

		my $i = @tags;
		while ($i--) {
			unless ($tags[$i] =~ /$tag_pattern/o) {
				splice @tags, $i, 1;
				next;
			}

			my $commit = '';
			foreach ($self->rungit(['git', 'show', "refs/tags/$tags[$i]", "--pretty='tformat:(((((%ct)))))"])) {
				next if (! /\(\(\(\(\(/);
				$commit = $_;
				last;
			}
			die "Failed to find our pretty print format ((((( for tag $tags[$i]: $commit" unless $commit =~ /\(\(\(\(\((\d+?)\)\)\)\)\)/;
			push(@head_version_per_tag, ($self->rungit(['git', 'rev-list', "refs/tags/$tags[$i]"]))[0]);

			$self->push_release(
				Software::Release->new(
					date    => DateTime->from_epoch(epoch => $1),
					version => $tags[$i]
				)
			);
		}
	}

	# Add a virtual release for the most recent change in the
	# repository.  This lets us include changes after the last
	# releases, up to "HEAD".

	{
		my $head_version = ($self->rungit([qw/git rev-list HEAD/]))[0];

		if ( not $self->all_releases or ! grep {$head_version eq $_} @head_version_per_tag) {
			$self->push_release(
				Software::Release->new(
					date    => DateTime->now(),
					version => 'HEAD',
				)
			);
		}
	}

	$self->sort_releases(
		sub {
			DateTime->compare( $_[0]->date(), $_[1]->date() )
		}
	);

	{
		my $i = $self->release_count();
		while ($i--) {
			my $this_release = $self->get_release($i);

			if (DateTime->compare($this_release->date, $earliest_date) == -1) {
				$self->add_skipped_release(1);
				next;
			}

			my $prev_version = (
				$i
				? ($self->get_release($i-1)->version() . '..')
				: ''
			);

			my $release_range = $prev_version . $this_release->version();

			warn ">>> $release_range\n" if $self->debug();

			my $exclude_message_re = $self->exclude_message();
			my $include_message_re = $self->include_message();

			my $iter = Git::Repository::Log::Iterator->new($release_range);
			while (my $log = $iter->next) {
				next if (
					defined $exclude_message_re and
					$log->message() =~ /$exclude_message_re/o
				);

				next if (
					defined $include_message_re and
					$log->message() !~ /$include_message_re/o
				);

				#print STDERR "LOG: ".$log->message."\n";

				warn("    ", $log->commit(), " ", $log->committer_localtime, "\n") if (
					$self->debug()
				);

				$this_release->add_to_changes(
					Software::Release::Change->new(
						author_email    => $log->author_email,
						author_name     => $log->author_name,
						change_id       => $log->commit,
						committer_email => $log->committer_email,
						committer_name  => $log->committer_name,
						date            => DateTime->from_epoch(epoch => $log->committer_localtime),
						description     => $log->message
					)
				);
			};
		}
	}

	my $file = Dist::Zilla::File::InMemory->new(
		{
			content => $self->render_changelog(),
			name    => $self->file_name(),
		}
	);

	$self->add_file($file);
}

### Render the changelog.

sub render_changelog {
	my $self = shift();
	return(
		$self->render_changelog_header() .
		$self->render_changelog_releases() .
		$self->render_changelog_footer()
	);
}

sub render_changelog_header {
	my $self = shift();
	my $header = (
		"Changes from " . $self->format_datetime($self->earliest_date()) .
		" to present."
	);
	return $self->surround_line("=", $header) . "\n";
}

sub render_changelog_footer {
	my $self = shift();

	my $skipped_count = $self->skipped_release_count();

	my $changelog_footer;

	if ($skipped_count) {
		my $releases = "release" . ($skipped_count == 1 ? "" : "s");
		$changelog_footer = (
			"Plus $skipped_count $releases after " .
			$self->format_datetime($self->earliest_date()) . '.'
		);
	}
	else {
		$changelog_footer = "End of releases.";
	}

	return $self->surround_line("=", $changelog_footer);
}

sub render_changelog_releases {
	my $self = shift();

	my $changelog = '';

	RELEASE: foreach my $release (reverse $self->all_releases()) {
		next RELEASE if $release->has_no_changes();
		$changelog .= $self->render_release($release);
	}

	return $changelog;
}

### Render a release.

sub render_release {
	my ($self, $release) = @_;
	return(
		$self->render_release_header($release) .
		$self->render_release_changes($release) .
		$self->render_release_footer($release)
	);
}

sub render_release_header {
	my ($self, $release) = @_;

	my $version = $release->version();
	$version = $self->zilla()->version() if $version eq 'HEAD';

	my $release_header = (
		$self->format_release_tag($release->version()) . ' at ' .
		$self->format_datetime($release->date())
	);

	return $self->surround_line("-", $release_header) . "\n";
}

sub render_release_footer {
	my ($self, $release) = @_;
	return '';
}

sub render_release_changes {
	my ($self, $release) = @_;

	my $changelog = '';

	foreach my $change (@{ $release->changes() }) {
		$changelog .= $self->render_change($release, $change);
	}

	return $changelog;
}

### Render a change.

sub render_change {
	my ($self, $release, $change) = @_;
	return(
		$self->render_change_header($release, $change) .
		$self->render_change_message($release, $change) .
		$self->render_change_footer($release, $change)
	);
}

sub render_change_header {
	my ($self, $release, $change) = @_;

	use Text::Wrap qw(fill);

	local $Text::Wrap::huge    = 'wrap';
	local $Text::Wrap::columns = $self->wrap_column();

	my @indent = ("  ", "  ");

	return(
		fill(
			"  ", "  ",
			'Change: ' . $change->change_id
		) .
		"\n" .
		fill(
			"  ", "  ",
			'Author: ' . $change->author_name.' <'.$change->author_email.'>'
		) .
		"\n" .
		fill(
			"  ", "  ",
			'Date  : ' . $self->format_datetime($change->date())
		) .
		"\n\n"
	);
}

sub render_change_footer {
	my ($self, $release, $change) = @_;
	return "\n";
}

sub render_change_message {
	my ($self, $release, $change) = @_;

	use Text::Wrap qw(fill);

	return '' if $change->description() =~ /^\s/;

	local $Text::Wrap::huge = 'wrap';
	local $Text::Wrap::columns = $self->wrap_column();

	return fill("    ", "    ", $change->description) . "\n";
}

### Helpers.

sub surround_line {
	my ($self, $character, $string) = @_;

	my $surrounder = substr(
		($character x (length($string) / length($character) + 1)),
		0,
		length($string)
	);

	return "$surrounder\n$string\n$surrounder\n";
}

sub format_release_tag {
	my ($self, $release_tag) = @_;

	return 'version ' . $self->zilla()->version() if $release_tag eq 'HEAD';

	my $tag_regexp = $self->tag_regexp();
	$release_tag =~ s/$tag_regexp/version $1/;
	return $release_tag;
}

sub format_datetime {
	my ($self, $datetime) = @_;
	return $datetime->strftime("%F %T %z");
}

sub rungit {
	my ($self, $arrayp) = @_;
	my $buf;
	run(command => $arrayp, buffer => \$buf);
	return split("\n", $buf);
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

Dist::Zilla::Plugin::ChangelogFromGit - Write a Changes file from a project's git log.

=head1 VERSION

version 0.016

=head1 SYNOPSIS

Here's an example dist.ini section showing all the current options and
their default values.

	[ChangelogFromGit]
	max_age     = 365
	tag_regexp  = ^v(\d+\.\d+)$
	file_name   = CHANGES
	wrap_column = 74
	debug       = 0

Variables don't need to be set to their default values.  This is
equivalent to the configuration above.

	[ChangelogFromGit]

=head1 DESCRIPTION

This Dist::Zilla plugin turns a project's git commit log into a
change log file.  It's better than simply running `git log > CHANGES`
in at least two ways.  First, it understands release tags, and it uses
them to group changes by release.  Second, it reformats the changes to
make them easier to read.  And third, subclasses can change some or
all of the reformatting to make change logs even easier to read.

See this project's CHANGES file for sample output.  Yes, this project
uses itself to generate its own change log.  Why not?

=head1 CONFIGURATION / PUBLIC ATTRIBUTES

As seen in the L</SYNOPSIS>, this plugin has a number of public
attributes that may be set using dist.ini configuration variables.

=head2 max_age = INTEGER

The C<max_age> configuration variable limits the age of releases to be
included in the change log.  The default is to include releases going
back about a year.  To include about two years, one would double the
default value:

	[ChangelogFromGit]
	max_age = 730

C<max_age> is intended to limit the size of change logs for large,
long-term projects that don't want to include the entire, huge commit
history in every release.

=head2 tag_regexp = REGULAR_EXPRESSION

C<tag_regexp> sets the regular expression that detects which tags mark
releases.  It also extracts the version numbers from these tags using
a regular expression back reference or capture.  For example, a
project's release tags might match 'release-1.000', 'release-1.001',
etc.  This C<tag_regexp> will find them and extract their versions.

	[ChangelogFromGit]
	tag_regexp = ^release-(\d+.*)$

There is no single standard format for release tags.  C<tag_regexp>
defaults to the author's convention.  It will most likely need to be
changed.

=head2 file_name = STRING

C<file_name> sets the name of the change log that will be written.  It
defaults to "CHANGES", but some people may prefer "Changes",
"Changelog", or something else.

	[ChangelogFromGit]
	file_name = Changes

=head2 wrap_column = INTEGER

Different contributors tend to use different commit message formats,
which can be disconcerting to the typographically aware release
engineer.  C<wrap_column> sets the line length to which all commit
messages will be re-wrapped.  It's 74 columns by default.  If this is
too short:

	[ChangelogFromGit]
	wrap_column = 78

=head2 debug = BOOLEAN

Developers are people, too.  The C<debug> option enables some noisy
runtime tracing on STDERR.

	[ChangelogFromGit]
	debug = 1

=head2 exclude_message = REGULAR_EXPRESSION

C<exclude_message> sets a regular expression which discards matching
commit messages.  This provides a way to exclude commit messages such
as 'forgot to include file X' or 'typo'.  The regular expression is
case sensitive.

	[ChangelogFromGit]
	exclude_message = ^(forgot|typo)

C<include_message> can be used to do the opposite: exclude all changes
except ones that match a regular expression.  Using both at once is
liable to generate empty change logs.

=head2 include_message = REGULAR_EXPRESSION

C<include_message> does the opposite of C<exclude_message>: it sets a
regular expression which commit messages must match in order to be
included in the Changes file.  This means that when making a commit
with a relevant message, you must include text that matches the
regular expression pattern to have it included in the Changes file.
All other commit messages are ignored.

The regular expression is case sensitive.

	[ChangelogFromGit]
	include_message = ^Major

Using both C<include_message> and C<exclude_message> at the same time
will most likely result in empty change logs.

=head1 HOW IT WORKS

Dist::Zilla::ChangelogFromGit collects the tags matching C<tag_regexp>
that are not older than C<max_age> days old.  These are used to
identify and time stamp releases.  Each release is encapsulated into a
L<Software::Release> object.

Git::Repository::Log::Iterator is used to collect the changes prior to
each release but after the previous release.  Change log entries are
added to their respective Software::Release objects.

C<< $self->render_changelog() >> is called after all the relevant
releases and changes are known.  It must return the rendered change
log as a string.  That string will be used as the content for a
L<Dist::Zilla::File::InMemory> object representing the new change log.

=head1 SUBCLASSING FOR NEW FORMATS

Dist::Zilla::ChangelogFromGit implement about a dozen methods to
render the various parts of a change log.  Subclasses may override or
augment any or all of these methods to alter the way change logs are
rendered.

All methods beginning with "render" return strings that will be
incorporated into the change log.  Methods that will not contribute to
the change log must return empty strings.

=head2 Rendering Entire Change Logs

Methods beginning with "render_changelog" receive no parameters other
than $self.  Everything they need to know about the change log is
included in the object's attributes: C<wrap_column>, C<releases>,
C<skipped_release_count>, C<earliest_date>.

=head3 render_changelog

render_changelog() returns the text of the entire change log.  By
default, the change log is built from a header, zero or more releases,
and a footer.

	sub render_changelog {
		my $self = shift();
		return(
			$self->render_changelog_header() .
			$self->render_changelog_releases() .
			$self->render_changelog_footer()
		);
	}

=head3 render_changelog_header

render_changelog_header() renders some text that introduces the reader
to the change log.

	sub render_changelog_header {
		my $self = shift();
		my $header = (
			"Changes from " . $self->format_datetime($self->earliest_date()) .
			" to present."
		);
		return $self->surround_line("=", $header) . "\n";
	}

=head3 render_changelog_releases

render_changelog_releases() iterates through each release, calling
upon $self to render them one at a time.

	sub render_changelog_releases {
		my $self = shift();

		my $changelog = '';

		RELEASE: foreach my $release (reverse $self->all_releases()) {
			next RELEASE if $release->has_no_changes();
			$changelog .= $self->render_release($release);
		}

		return $changelog;
	}

=head3 render_changelog_footer

render_changelog_footer() tells the reader that the change log is
over.  Normally the end of the file is sufficient warning, but a
truncated change log is friendlier when the reader knows what they're
missing.

	sub render_changelog_footer {
		my $self = shift();

		my $skipped_count = $self->skipped_release_count();

		my $changelog_footer;

		if ($skipped_count) {
			my $releases = "release" . ($skipped_count == 1 ? "" : "s");
			$changelog_footer = (
				"Plus $skipped_count $releases after " .
				$self->format_datetime($self->earliest_date()) . '.'
			);
		}
		else {
			$changelog_footer = "End of releases.";
		}

		return $self->surround_line("=", $changelog_footer);
	}

=head2 Rendering Individual Releases

Methods beginning with "render_release" receive $self plus one
additional parameter: a Software::Release object encapsulating the
release and its changes.  See L<Software::Release> to learn the
information that object encapsulates.

=head3 render_release

render_release() is called upon to render a single release.  In the
change log, a release consists of a header, one or more changes, and a
footer.

	sub render_release {
		my ($self, $release) = @_;
		return(
			$self->render_release_header($release) .
			$self->render_release_changes($release) .
			$self->render_release_footer($release)
		);
	}

=head3 render_release_header

render_release_header() introduces a release.

	sub render_release_header {
		my ($self, $release) = @_;

		my $version = $release->version();
		$version = $self->zilla()->version() if $version eq 'HEAD';

		my $release_header = (
			$self->format_release_tag($release->version()) . ' at ' .
			$self->format_datetime($release->date())
		);

		return $self->surround_line("-", $release_header) . "\n";
	}

=head3 render_release_changes

render_release_changes() iterates through the changes associated with
each Software::Release object.  It calls upon render_change() to
render each change.

	sub render_release_changes {
		my ($self, $release) = @_;

		my $changelog = '';

		foreach my $change (@{ $release->changes() }) {
			$changelog .= $self->render_change($release, $change);
		}

		return $changelog;
	}

=head3 render_release_footer

render_release_footer() may be used to divide releases.  It's not used
	by default, but it's implemented for completeness.

	sub render_release_footer {
		my ($self, $release) = @_;
		return '';
	}

=head2 Rendering Individual Changes

Methods beginning with "render_change" receive two parameters in
addition to $self: a L<Software::Release> object encapsulating the
release containing this change, and a L<Software::Release::Change>
object encapsulating the change itself.

=head3 render_change

render_change() renders a single change, which is the catenation of a
change header, change message, and footer.

	sub render_change {
		my ($self, $release, $change) = @_;
		return(
			$self->render_change_header($release, $change) .
			$self->render_change_message($release, $change) .
			$self->render_change_footer($release, $change)
		);
	}

=head3 render_change_header

render_change_header() generally renders identifying information about
each change.  This method's responsibility is to produce useful
information in a pleasant format.

	sub render_change_header {
		my ($self, $release, $change) = @_;

		use Text::Wrap qw(fill);

		local $Text::Wrap::huge    = 'wrap';
		local $Text::Wrap::columns = $self->wrap_column();

		my @indent = ("  ", "  ");

		return(
			fill(
				"  ", "  ",
				'Change: ' . $change->change_id
			) .
			"\n" .
			fill(
				"  ", "  ",
				'Author: ' . $change->author_name.' <'.$change->author_email.'>'
			) .
			"\n" .
			fill(
				"  ", "  ",
				'Date  : ' . $self->format_datetime($change->date())
			) .
			"\n\n"
		);
	}

=head3 render_change_message

render_change_message() renders the commit message for the change log.

	sub render_change_message {
		my ($self, $release, $change) = @_;

		use Text::Wrap qw(fill);

		return '' if $change->description() =~ /^\s/;

		local $Text::Wrap::huge = 'wrap';
		local $Text::Wrap::columns = $self->wrap_column();

		return fill("    ", "    ", $change->description) . "\n";
	}

=head3 render_change_footer

render_change_footer() returns summary and/or divider text for the
change.

	sub render_change_footer {
		my ($self, $release, $change) = @_;
		return "\n";
	}

=head2 Formatting Data

Dist::Zilla::Plugin::ChangelogFromGit includes a few methods to
consistently format certain data types.

=head3 format_datetime

format_datetime() converts the L<DateTime> objects used internally
into friendly, human readable dates and times for the change log.

	sub format_datetime {
		my ($self, $datetime) = @_;
		return $datetime->strftime("%F %T %z");
	}

=head3 format_release_tag

format_release_tag() turns potentially cryptic release tags into
friendly version numbers for the change log.  By default, it also
replaces the 'HEAD' version with the current version being released.
This accommodates release managers who prefer to tag their
distributions after releasing them.

	sub format_release_tag {
		my ($self, $release_tag) = @_;

		return 'version ' . $self->zilla()->version() if $release_tag eq 'HEAD';

		my $tag_regexp = $self->tag_regexp();
		$release_tag =~ s/$tag_regexp/version $1/;
		return $release_tag;
	}

=head3 surround_line

surround_line() will surround a line of output with lines of dashes or
other characters.  It's used to help heading stand out.  This method
takes two strings: a character (or string) that will repeat to fill
surrounding lines, and the line to surround.  It returns a three-line
string: the original line preceded and followed by surrounding lines.

	sub surround_line {
		my ($self, $character, $string) = @_;

		my $surrounder = substr(
			($character x (length($string) / length($character) + 1)),
			0,
			length($string)
		);

		return "$surrounder\n$string\n$surrounder\n";
	}

=head1 INTERNAL ATTRIBUTES

Dist::Zilla::Plugin::ChangelogFromGit accumulates useful information
into a few internal attributes.  These aren't intended to be
configured by dist.ini, but they are important for rendering change
logs.

=head2 earliest_date

earliest_date() contains a L<DateTime> object that represents the date
and time of the earliest release to include.  It's initialized as
midnight for the date max_age() days ago.

=head2 releases

releases() contains an array reference of L<Software::Release> objects
that will be included in the change log.

=head3 all_releases

all_releases() returns a list of the Software::Release objects that
should be included in the change log.  It's a friendly equivalent of
C<< @{$self->releases()} >>.

=head3 get_release

get_release() returns a single release by index.  The first release
in the change log may be retrieved as C<< $self->get_release(0) >>.

=head3 releae_count

release_count() returns the number of Software::Release objects in the
L</releases> attribute.

=head3 sort_releases

sort_releases() sorts the Software::Release objects in the releases()
using some comparator.  For example, to sort releases in time order:

	$self->sort_releases(
		sub {
			DateTime->compare( $_[0]->date(), $_[1]->date() )
		}
	);

=head2 skipped_release_count

skipped_release_count() contains the number of releases truncated by
max_age().  The default render_changelog_footer() uses it to display
the number of changes that have been omitted from the log.

=head1 Subversion and CVS

This plugin is almost entirely a copy-and-paste port of a command-line
tool I wrote a while ago.  I also have tools to generate similar
change logs for CVS and Subversion projects.  I'm happy to contribute
that code to people interested in creating Dist::Zilla plugins for
other version control systems.

We should also consider abstracting the formatting code out to a role
so that it can be shared among different plugins.

=head1 BUGS

The documentation includes copies of the renderer methods.  This
increases technical debt, since changes to those methods must also be
copied into the documentation.  Rocco needs to finish L<Pod::Plexus>
and use it here to simplify maintenance of the documentation.

Collecting all releases and changes before rendering the change log
may be considered harmful for extremely large projects.  If someone
thinks they can generate change logs incrementally, their assistance
would be appreciated.

=head1 AUTHORS

Rocco Caputo <rcaputo@cpan.org> - Initial release, and ongoing
management and maintenance.

Cory G. Watson <gphat@cpan.org> - Made formatting extensible and
overridable.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2013 by Rocco Caputo.

This is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language itself.

=cut
