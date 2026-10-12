package FixMP3Tags::Processor;

use strict;
use warnings;
use utf8;
use feature 'state';

use File::Find;
use File::Basename;
use Cwd 'abs_path';
use Getopt::Long;

use FixMP3Tags ();

# Use MP3::Tag for ID3v2 writing
eval {
	require MP3::Tag;
	MP3::Tag->import();
};
if ($@)
{
	die "MP3::Tag required: sudo cpan MP3::Tag\n";
}

my @CD_PATTERNS = qw/cd disk disc part volume/;

sub run
{
	my $class = shift;

	my ($quiet, $dry_run, $pattern, $directory, $file);
	GetOptions(
		'quiet|q'       => \$quiet,
		'dry-run|n'     => \$dry_run,
		'pattern|p=s'   => \$pattern,
		'directory|d=s' => \$directory,
		'file|f=s'      => \$file,
		'help|h'        => \&show_help,
		'version|v'     => \&show_version,
	);

	$directory ||= '.';

	unless (-d $directory)
	{
		die "Directory does not exist: $directory\n";
	}

	if ($file)
	{
		unless (-f $file)
		{
			die "File does not exist: $file\n";
		}
		$class->process_file(
			$file,
			{
				quiet   => $quiet,
				dry_run => $dry_run,
				pattern => $pattern,
			}
		);
	}
	else
	{
		$class->process_directory(
			$directory,
			{
				quiet   => $quiet,
				dry_run => $dry_run,
				pattern => $pattern,
			}
		);
	}
}

sub process_directory
{
	my ($class, $directory, $opts) = @_;

	my %album_preview;
	my $abs_directory = abs_path($directory);

	# First pass: collect album directories for preview
	find(
		{
			wanted => sub {
				my $file_path = $File::Find::name;
				return unless $file_path && -f $file_path;
				return unless $file_path =~ /\.mp3$/i;

				my ($album_dir, $artist_dir, $cd_dir) =
					$class->find_album_dir($file_path);
				if ($album_dir && $artist_dir)
				{
					my $album_name  = basename($album_dir);
					my $artist_name = basename($artist_dir);

					# Store unique album-artist combinations
					my $key = "$artist_name|$album_name";
					$album_preview{$key} = {
						artist => $artist_name,
						album  => $album_name,
						has_cd => $cd_dir ? 1 : 0
					};
				}
			},
			no_chdir => 1,
		},
		$abs_directory
	);

	# Show preview
	if (!$opts->{quiet} && keys %album_preview)
	{
		print "=== Album Name Preview ===\n";
		print
			"Format: Artist -> 'Real Album Name' -> 'Extracted Album Name' (Year-Month)\n";
		print "====================================\n";

		for my $key (sort keys %album_preview)
		{
			my $info = $album_preview{$key};
			my ($year, $month, $album_clean) =
				$class->extract_album_info($info->{album}, $opts->{pattern});

			$album_clean =~ s/^['"]*|['"]*$//g;

			my $cd_indicator = $info->{has_cd} ? " [has CD subdirs]" : "";

			if ($year && $month)
			{
				print
					"  $info->{artist} -> '$info->{album}' -> '$album_clean' ($year-$month)$cd_indicator\n";
			}
			else
			{
				print
					"  $info->{artist} -> '$info->{album}' -> '$album_clean' (no date)$cd_indicator\n";
			}
		}
		print "\n";
	}

	return if $opts->{dry_run};

	# Ask for confirmation
	if (!$opts->{quiet} && keys %album_preview)
	{
		print "Proceed with processing? (Y/n): ";
		my $response = <STDIN>;
		chomp $response;
		if ($response !~ /^[Yy]?$/)
		{
			print "Processing cancelled.\n";
			return;
		}
		print "\n";
	}

	# Second pass: actual processing
	my ($processed, $errors) = (0, 0);
	find(
		{
			wanted => sub {
				my $file_path = $File::Find::name;
				return unless $file_path && -f $file_path;
				return unless $file_path =~ /\.mp3$/i;

				if ($class->process_file($file_path, $opts))
				{
					$processed++;
				}
				else
				{
					$errors++;
				}
			},
			no_chdir => 1,
		},
		$abs_directory
	);

	if ($errors > 0)
	{
		print
			"Processing complete with errors: $processed files updated, $errors errors\n";
	}
	elsif (!$opts->{quiet})
	{
		print
			"Processing complete: $processed files updated, $errors errors\n";
	}
}

sub process_file
{
	my ($class, $file_path, $opts) = @_;

	# Validate file path
	unless ($file_path && -f $file_path)
	{
		warn "ERROR: Invalid file path: $file_path\n";
		return;
	}

	# Get album and artist directories
	my ($album_dir, $artist_dir, $cd_dir) =
		$class->find_album_dir($file_path);
	return unless $album_dir && $artist_dir;

	my $album_name  = basename($album_dir);
	my $artist_name = basename($artist_dir);

	# Extract year, month, and clean album name
	my ($year, $month, $album) =
		$class->extract_album_info($album_name, $opts->{pattern});

	# Clean quotes for tags only
	my $album_clean = $album;
	$album_clean =~ s/^['"]*|['"]*$//g;

	# Parse filename
	my $base_name;
	eval {
		$base_name = basename($file_path);
		$base_name =~ s/\.(mp3|MP3)$//i;
	};
	if ($@ || !defined $base_name)
	{
		warn "ERROR: Could not parse filename: $file_path\n";
		return;
	}

	unless ($base_name =~ /^(\d+)\.(.+)$/)
	{
		warn
			"ERROR: Filename doesn't match pattern NN.SongName: $base_name\n";
		return;
	}

	my ($track, $title) = ($1, $2);
	$title =~ s/[._]/ /g;

	# Display processing info
	unless ($opts->{quiet})
	{
		print "Processing: $file_path\n";
		if ($cd_dir)
		{
			print "  CD Directory: $cd_dir\n";
		}
		if ($year && $month)
		{
			print "  Album: '$album_name' -> '$album_clean' ($year-$month)\n";
		}
		else
		{
			print "  Album: '$album_name' -> '$album_clean' (no date)\n";
		}
		print "  Artist: '$artist_name'\n";
		print "  Track: $track, Title: '$title'\n";
	}

	return 1 if $opts->{dry_run};

	eval {
		my $mp3 = MP3::Tag->new($file_path);
		$mp3->get_tags;

		# Completely remove existing ID3v2 tag and create new one
		delete $mp3->{ID3v2} if exists $mp3->{ID3v2};
		my $id3v2 = $mp3->new_tag("ID3v2");

		# Set the frames
		$id3v2->add_frame("TPE1", $artist_name);    # Artist
		$id3v2->add_frame("TALB", $album_clean);    # Album
		$id3v2->add_frame("TIT2", $title);          # Title
		$id3v2->add_frame("TRCK", $track);          # Track number

		if ($year)
		{
			$id3v2->add_frame("TYER", $year);       # Year
		}

		# Write the tag
		$id3v2->write_tag;
		$mp3->close;

		print "  ✓ Tags updated successfully\n" unless $opts->{quiet};
	};

	if ($@)
	{
		warn "ERROR: Failed to update tags for: $file_path - $@\n";
		return;
	}

	return 1;
}

sub find_album_dir
{
	my ($class, $file_path) = @_;

	my $abs_path = eval {abs_path($file_path)};
	unless ($abs_path && -f $abs_path)
	{
		warn "ERROR: Cannot get absolute path for: $file_path\n";
		return (undef, undef);
	}

	my $current_dir  = dirname($abs_path);
	my $current_name = basename($current_dir);

	# First, check if current directory is a CD directory
	if ($class->is_cd_directory($current_name))
	{
		# Go up one level to get the album directory
		my $album_dir  = dirname($current_dir);
		my $artist_dir = dirname($album_dir);
		return ($album_dir, $artist_dir, $current_name);
	}

	# Current directory is not a CD directory, so it should be the album directory
	my $artist_dir = dirname($current_dir);
	return ($current_dir, $artist_dir, undef);
}

sub is_cd_directory
{
	my ($class, $name) = @_;
	return 0 unless defined $name && $name ne '';

	my $lower = lc($name);

	for my $pattern (@CD_PATTERNS)
	{
		return 1 if $lower =~ /^$pattern\s*\d+/;
		return 1 if $lower =~ /\d+\s*$pattern/;
		return 1 if $lower =~ /^\d+$/;
	}

	return 0;
}

sub extract_album_info
{
	my ($class, $dir_name, $pattern) = @_;

	unless (defined $dir_name && $dir_name ne '')
	{
		return (undef, undef, '');
	}

	# User pattern
	if ($pattern && $dir_name =~ /$pattern/)
	{
		my ($year, $month, $album) = ($1, $2, $3);
		$album ||= $dir_name;
		return ($year, $month, $album);
	}

	# Flexible YYYY*MM pattern - specifically handle the quote case
	if ($dir_name =~ /^.*(\d{4})\D*?(\d{2})['"\s]*([^'"]*)['"]*$/)
	{
		my ($year, $month, $album) = ($1, $2, $3);
		return ($year, $month, $album) if $album;
	}

	# No pattern matched
	return (undef, undef, $dir_name);
}

sub preview_album_name
{
	my ($class, $dir_name, $pattern) = @_;

	my ($year, $month, $album_name) =
		$class->extract_album_info($dir_name, $pattern);

	# Clean quotes for display in preview
	my $album_clean = $album_name;
	$album_clean =~ s/^['"]*|['"]*$//g;

	if (defined $year && defined $month)
	{
		print "  '$dir_name' -> '$album_clean' ($year-$month)\n";
	}
	else
	{
		print "  '$dir_name' -> '$album_clean' (no date)\n";
	}
}

sub show_help
{
	print <<'HELP';
Usage: fix-mp3-tags [OPTIONS]

Options:
  -d, --directory DIR    Process all MP3 files in directory DIR (default: current directory)
  -f, --file FILE        Process single MP3 file FILE
  -q, --quiet           Display only errors
  -p, --pattern PATTERN  Custom album directory pattern (regex)
  -n, --dry-run         Preview without processing
  -v, --version         Show version
  -h, --help            Show this help

Examples:
  fix-mp3-tags                      # Process all MP3s in current directory (verbose)
  fix-mp3-tags -q                   # Process all MP3s, show only errors
  fix-mp3-tags -n                   # Preview album name extraction
  fix-mp3-tags -d /path/to/music    # Process specific directory

Installation:
  cpanm --installdeps .
HELP
	exit 0;
}

sub show_version
{
	print "fix-mp3-tags version $FixMP3Tags::VERSION\n";
	exit 0;
}

1;

__END__

=head1 NAME

FixMP3Tags::Processor - Internal processor for fixing MP3 tags

=head1 VERSION

Version 0.1.0

=head1 SYNOPSIS

    use FixMP3Tags::Processor;

    FixMP3Tags::Processor->run();

=head1 DESCRIPTION

This module implements the processing used by the C<fix-mp3-tags> command-line
program. It derives artist and album names from parent directories and the track
number and title from filenames, then writes the derived values to an ID3v2 tag.

The command-line program is the intended user interface. This module does not
provide an object constructor; its routines are invoked as class methods.

=head1 METHODS

=head2 run

    FixMP3Tags::Processor->run();

Reads command-line options from C<@ARGV> and processes either the file specified
by C<--file> or MP3 files found recursively under C<--directory>. The default
directory is the current working directory. C<--help> and C<--version> print
their information and exit.

=head2 process_directory

    FixMP3Tags::Processor->process_directory($directory, \%options);

Recursively scans a directory for MP3 files and processes files whose paths
match the expected artist/album/track structure. The options hash may contain
C<quiet>, C<dry_run>, and C<pattern>. In normal mode, non-quiet runs show a
preview and request confirmation before writing tags. With C<dry_run>, the
routine returns without changing tags.

=head2 process_file

    FixMP3Tags::Processor->process_file($file_path, \%options);

Processes one MP3 file. The artist and album are derived from its parent folders;
the track number and title are derived from a filename in the form
C<NN.SongName.mp3>. The options hash supports C<quiet>, C<dry_run>, and
C<pattern>. The routine returns a true value when processing succeeds (or a dry
run completes), and a false/undefined value when the file cannot be processed
or tag writing fails.

=head1 AUTHOR

vr-ski, C<< <166657596+vr-ski@users.noreply.github.com> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by vr-ski.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
=cut
