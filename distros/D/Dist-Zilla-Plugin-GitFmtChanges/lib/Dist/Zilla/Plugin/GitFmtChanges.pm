package Dist::Zilla::Plugin::GitFmtChanges;
$Dist::Zilla::Plugin::GitFmtChanges::VERSION = '0.006';
=head1 NAME

Dist::Zilla::Plugin::GitFmtChanges - Build CHANGES file from a project's git log using git log format.

=head1 VERSION

version 0.006

=head1 SYNOPSIS

In your dist.ini:

	[GitFmtChanges]
	max_age     = 365
	tag_regexp  = ^v\d+\.\d+$
	file_name   = CHANGES
	log_format  = medium

The example values are the defaults.

=head1 DESCRIPTION

This Dist::Zilla plugin writes a CHANGES file that contains formatted
commit information from recent git logs.  The CHANGES file is formatted
using the "--format" option of the git log command.  This makes it easy
to make the CHANGES file look the way you want it to.

This is based on Dist::Zilla::Plugin::ChangelogFromGit.

This plugin has the following configuration variables:

=over 2

=item * max_age

It may be impractical to include the full change log in a mature
project's distribution.  "max_age" limits the changes to the most
recent ones within a number of days.  The default is about one year.

Include two years of changes:

	max_age = 730

=item * tag_regexp

This plugin breaks the changelog into sections delineated by releases,
which are defined by release tags.  "tag_regexp" may be used to focus
only on those tags that follow a particular release tagging format.
Some of the author's repositories contain multiple projects, each with
their own specific release tag formats, so that changelogs can focus
on particular projects' tags.  For instance, POE::Test::Loops' release
tags may be specified as:

	tag_regexp = ^ptl-

=item * file_name

Everyone has a preference for their change logs.  If you prefer
lowercase in your change log file names, you might specify:

	file_name = Changes

=item * log_format

Define the format used for the change listing in the CHANGES file.
This option is passed through to the B<git log> command.
One can use the predefined formats, such as 'oneline', 'short', 'medium' etc.

	log_format = short

Or one can exersize more control by using the "format" formatting.
The following example will give the author and date, a newline, and
the "subject" of the change.

	log_format = %ai%n%s

=back

=cut

require 5.6.0;
use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use POSIX qw(strftime);
use Date::Simple qw(date today);
use Git::Wrapper;

has max_age => (
	is      => 'ro',
	isa     => 'Int',
	default => 365,
);

has tag_regexp => (
	is      => 'ro',
	isa     => 'Str',
	default => '^v\\d+\.\\d+$',
);

has file_name => (
	is      => 'ro',
	isa     => 'Str',
	default => 'CHANGES',
);

has log_format => (
	is      => 'ro',
	isa     => 'Str',
	default => 'medium',
);

has git => (
	is      =>'ro',
	default => sub { Git::Wrapper->new('.') }
);

sub gather_files {
	my ($self, $arg) = @_;

	my $earliest_date = strftime(
		"%FT %T +0000", gmtime(time() - $self->max_age() * 86400)
	);

	my @tags = $self->git->tag;

	{
		my $tag_pattern = $self->tag_regexp();

		my $i = @tags;
		while ($i--) {
			unless ($tags[$i] =~ /$tag_pattern/o) {
				splice @tags, $i, 1;
				next;
			}

			my @commit = $self->git->show(
				{ format => 'tformat:(((((%ci)))))' },
				$tags[$i]
			);
			my ($commit) = grep { m#\(\(\(\(\(# } @commit;

			die $commit unless $commit =~ /\(\(\(\(\((.+?)\)\)\)\)\)/;

			$tags[$i] = {
				'time' => $1,
				'tag'  => $tags[$i],
			};
		}
	}

	push @tags, {'time' => '9999-99-99 99:99:99 +0000', 'tag' => 'HEAD'};

	@tags = sort { $a->{'time'} cmp $b->{'time'} } @tags;

	my $changelog = "";

	{
		my $log_format = $self->log_format();
		my $i = @tags;
		while ($i--) {
			my $tag_time = $tags[$i]{time};
			last if $tag_time lt $earliest_date;

			my @commit;
			my $prev_tag = $tags[$i-1]{tag};
			my $curr_tag = $tags[$i]{tag};

			# Handle initial releases properly
			$prev_tag = 'HEAD~1'
				if (!$i && $curr_tag eq 'HEAD' && @tags == 1);

			open my $commit, "-|", "git log --format=\"$log_format\" $prev_tag..$curr_tag ."
				or die $!;

			{ local $/ = "\n\n" ; @commit = <$commit> };

			# Don't display the tag if there's nothing under it.
			next unless @commit;

			my $tag_line = "$tag_time $curr_tag";
			# if this is the HEAD then take the version from
			# the version, and the date as today
			if ($curr_tag eq 'HEAD')
			{
			    my $today = today();
			    my $ver = $self->zilla->version;
			    $tag_line = "v$ver $today";
			}
			elsif ($tag_time =~ /(\d+-\d+-\d+)/) # only date
			{
			    $tag_line = "$curr_tag $1";
			}
			$changelog .= (
				"\n$tag_line\n" .
				("-" x length($tag_line)) . "\n\n"
			);

			$changelog .= $_ foreach @commit;
		}
	}

	my $epilogue = "End of changes in the last " . $self->max_age() . " day";
	$epilogue .= "s" unless $self->max_age() == 1;

	$changelog .= (
		"\n" .
		("=" x length($epilogue)) . "\n" .
		"$epilogue\n" .
		("=" x length($epilogue)) . "\n"
	);
	my $dist_name = $self->zilla->name;
	my $chlog_title = "Revision History for $dist_name";
	my $prologue = (
		"$chlog_title\n" .
		("=" x length($chlog_title)) . "\n"
	);
	$changelog = $prologue . $changelog;

	my $file = Dist::Zilla::File::InMemory->new({
		content => $changelog,
		name    => $self->file_name(),
	});

	$self->add_file($file);
	return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 AUTHOR

Kathryn Andersen <perlkat@katspace.org>

=head1 COPYRIGHT AND LICENSE

This is based on Dist::Zilla::Plugin::ChangelogFromGit by Rocco Caputo.

This software is copyright (c) 2010 by Kathryn Andersen.

This is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language itself.

=cut
