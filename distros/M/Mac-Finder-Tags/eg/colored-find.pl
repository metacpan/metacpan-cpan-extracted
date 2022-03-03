#! /usr/bin/env perl

use v5.26;
use warnings;
use utf8;

# ABSTRACT: Walk a file hierarchy and output color emojis for Finder tags


use Mac::Finder::Tags;

use experimental 'signatures';
use open qw( :encoding(UTF-8) :std );
use Encode qw( decode_utf8 );
use Getopt::Long 2.33 qw( :config posix_default gnu_getopt );
use Pod::Usage qw( pod2usage );
use Path::Tiny qw( path );

# Use Mac::Finder::Tags caching if more than 100 files were found
our $CACHING_LIMIT = 100;


# Parse CLI parameters

my @paths;
my $maxdepth;
my $verbose;
GetOptions(
	'maxdepth=i' => \$maxdepth,
	'verbose=i' => \$verbose,
	'help|man|?' => \(my $pod_help),
) and @paths = (@ARGV) or pod2usage(2);
pod2usage(-exitstatus => 0, -verbose => 2) if $pod_help;
@paths = map { path(decode_utf8 $_) } @paths;

if (my @missing = grep {! $_->exists} @paths) {
	say STDERR "$0: $_: not found" for @missing;
	exit 1;
}


# Walk the file system

my @bases;
my %result;
for my $base (map {$_->absolute} @paths) {
	my $base_name = $base->basename;
	my $base_dir = $base->parent;
	my $base_len = 1 + length "$base_dir";
	my @found;
	
	say STDERR "Reading file list for $base ..." if $verbose;
	
	my $walk;
	$walk = sub ($path, $depth) {
		return if defined $maxdepth && $depth > $maxdepth;
		my $iter = $path->iterator( {
			recurse         => 0,
			follow_symlinks => 0,
		} );
		while ( defined( my $child = $iter->() ) ) {
			next if $child =~ m{/\.};
			push @found, decode_utf8 substr $child, $base_len;
			if (-d $child && ! -l $child && -x $child) {
				$walk->($child, $depth + 1);
			}
		}
	};
	
	push @found, decode_utf8 substr $base, $base_len;
	$walk->($base, 1);
	
	say STDERR scalar(@found), " files found in $base_name" if $verbose;
	@found = sort { fc $a cmp fc $b } @found;
	
	$result{"$base"} = \@found;
	push @bases, $base;
}


# Read tags from file system and print the result

say STDERR "Reading file tags ..." if $verbose;
my $total_files = scalar map { $result{"$_"}->@* } @bases;
my $caching = $total_files > $CACHING_LIMIT;
my $ft = Mac::Finder::Tags->new( caching => $caching );

say STDERR "Caching tags completed; writing catalog ..." if $verbose && $caching;

for my $base (@bases) {
	my $base_dir = $base->parent;
	for my $subpath ( $result{"$base"}->@* ) {
		print $subpath;
		my $fullpath = $base_dir->child($subpath);
		my @tags = $ft->get_tags($fullpath);
		print " " if @tags;
		print $_->emoji || "\N{WHITE QUESTION MARK ORNAMENT}" for @tags;
		#print " \N{NORTH EAST ARROW}\N{VARIATION SELECTOR-16}" if -l $fullpath;
		print "\n";
	}
}


exit 0;

__END__

=encoding UTF-8

=head1 SYNOPSIS

 eg/colored-find.pl [--maxdepth num] path ...

=head1 DESCRIPTION

This example script recursively descends the directory tree for each path
listed, listing each path along with the color of its Finder tags (if any).
It works similarly to the L<find(1)> Unix utility, but doesn't support any
of that utility's options except for C<--maxdepth>.

The output will be encoded in UTF-8 (not normalised).

Note: If you get "Operation not permitted" errors when executing this script,
the cause are probably the security features introduced with Mac OS X 10.14.
To fix this, open the "Security & Privacy" section in the System Preferences
and add Terminal to the apps that are allowed Full Disk Access.

=head1 EXAMPLES
 
 eg/colored-find.pl '/Volumes/Backup HD' > backup_files.txt
 eg/colored-find.pl ~ --maxdepth 1
 eg/colored-find.pl ~/Movies ~/Music ~/Pictures | grep '🔴'

Example of how output might look:

 Applications 🟠
 Desktop
 Documents
 Downloads
 Library 🟣
 Movies 🟢
 Movies/Servant of the People 🔵🟡
 Music 🟢
 Music/Audio 🔴🟠
 Music/Lyrics
 Music/Music Library ⚫️
 Music/Radio 🔴
 Music/Sheet
 Pictures ⚪️🟢
 Public
 Sites 🟠🟠🟡
