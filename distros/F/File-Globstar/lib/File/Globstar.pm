# Copyright (C) 2016-2023 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

# This next lines is here to make Dist::Zilla happy.
# ABSTRACT: Perl Globstar (double asterisk globbing) and utils

package File::Globstar;
$File::Globstar::VERSION = 'v1.1.0';
use strict;

use Locale::TextDomain qw(File-Globstar);
use File::Glob qw(bsd_glob);
use Scalar::Util 1.21 qw(reftype);
use File::Find;

use base 'Exporter';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(globstar fnmatchstar translatestar quotestar pnmatchstar);

use constant RE_NONE => 0x0;
use constant RE_NEGATED => 0x1;
use constant RE_FULL_MATCH => 0x2;
use constant RE_DIRECTORY => 0x4;

# Remember what Scalar::Util::reftype() returns for a compiled regular
# expression.  It should normally be 'REGEXP' but with Perl 5.10 (or
# maybe older) this seems to be an empty string.  In this case, the
# check in pnmatchstar() whether it received a compiled regex will be
# rather weak ...
my $test_re = qr/./;
my $regex_type = reftype $test_re;

sub _globstar;
sub pnmatchstar;

sub empty($) {
	my ($what) = @_;

	return if defined $what && length $what;

	return 1;
}

sub _find_directories($) {
	my ($directory) = @_;

	my $empty = empty $directory;
	$directory = '.' if $empty;

	my @hits;
	File::Find::find sub {
		return if !-d $_;
		return if '.' eq substr $_, 0, 1;
		push @hits, $File::Find::name;
	}, $directory;

	if ($empty) {
		@hits = map { substr $_, 2 } @hits;
	}

	return @hits;
}

sub _find_all($) {
	my ($directory) = @_;

	my $empty = empty $directory;
	$directory = '.' if $empty;

	my @hits;
	File::Find::find sub {
		return if '.' eq substr $_, 0, 1;
		push @hits, $File::Find::name;
	}, $directory;

	if ($empty) {
		@hits = map { substr $_, 2 } @hits;
	}

	return @hits;
}

sub _globstar($$;$) {
	my ($pattern, $directory, $flags) = @_;

	# This should fix https://github.com/gflohr/File-Globstar/issues/7
	# although I can actually not reproduce the behaviour described there.
	my @flags = defined $flags ? ($flags) : ();

	$directory = '' if !defined $directory;
	$pattern = $_ if !@_;

	if ('**' eq $pattern) {
		return _find_all $directory;
	} elsif ('**/' eq $pattern) {
		return map { $_ . '/' } _find_directories $directory;
	} elsif ($pattern =~ s{^\*\*/}{}) {
		my %found_files;
		foreach my $directory ('', _find_directories $directory) {
			foreach my $file (_globstar $pattern, $directory, @flags) {
				$found_files{$file} = 1;
			}
		}
		return keys %found_files;
	}

	my $current = $directory;

	# This is a quotemeta() that does not escape the slash and the
	# colon.  Escaped slashes confuse bsd_glob() and escaping colons
	# may make a full port to Windows harder.
	$current =~ s{([\x00-\x2d\x3b-\x40\x5b-\x5e\x60\x7b-\x7f])}{\\$1}g;
	if ($directory ne '' && '/' ne substr $directory, -1, 1) {
		$current .= '/';
	}
	while ($pattern =~ s/(.)//s) {
		if ($1 eq '\\') {
			$pattern =~ s/(..?)//s;
			$current .= $1;
		} elsif ('/' eq $1 && $pattern =~ s{^\*\*/}{}) {
			$current .= '/';

			# Expand until here.
			my @directories = bsd_glob $current, @flags;

			# And search in every subdirectory;
			my %found_dirs;
			foreach my $directory (@directories) {
				$found_dirs{$directory} = 1;
				foreach my $subdirectory (_find_directories $directory) {
					$found_dirs{$subdirectory . '/'} = 1;
				}
			}

			if ('' eq $pattern) {
				my %found_subdirs;
				foreach my $directory (keys %found_dirs) {
					$found_subdirs{$directory} = 1;
					foreach my $subdirectory (_find_directories $directory) {
						$found_subdirs{$subdirectory . '/'} = 1;
					}
				}
				return keys %found_subdirs;
			}
			my %found_files;
			foreach my $directory (keys %found_dirs) {
				foreach my $hit (_globstar $pattern, $directory, $flags) {
					$found_files{$hit} = 1;
				}
			}
			return keys %found_files;
		} elsif ('**' eq $pattern) {
			my %found_files;
			foreach my $directory (bsd_glob $current, @flags) {
				$found_files{$directory . '/'} = 1;
				foreach my $file (_find_all $directory) {
					$found_files{$file} = 1;
				}
			}
			return keys %found_files;
		} else {
			$current .= $1;
		}
	}

	# Pattern without globstar.  Just return the normal expansion.
	return bsd_glob $current, @flags;
}

sub globstar {
	my ($pattern, $flags) = @_;

	# The double asterisk can only be used in place of a directory.
	# It is illegal everywhere else.
	my @parts = split /\//, $pattern;
	foreach my $part (@parts) {
		$part ne '**' and 0 <= index $part, '**' and return;
	}

	return _globstar $pattern, '', $flags;
}

sub quotestar {
	my ($string, $listmatch) = @_;

	$string =~ s/([\\\[\]*?])/\\$1/g;
	$string =~ s/^!/\\!/ if $listmatch;

	return $string;
}

sub _transpile_range($) {
	my ($range) = @_;

	# Strip-off enclosing brackets.
	$range = substr $range, 1, -2 + length $range;

	# Replace leading exclamation mark with caret.
	$range =~ s/^!/^/;

	# Backslashes escape inside Perl ranges but not in ours.  Escape them:
	$range =~ s/\\/\\\\/g;

	# Quote dots and equal sign to prevent Perl from interpreting
	# equivalence and collating classes.
	$range =~ s/\./\\\./g;
	$range =~ s/\=/\\\=/g;

	return "[$range]";
}

sub translatestar {
	my ($pattern, %options) = @_;

	die __x("invalid pattern '{pattern}'\n", pattern => $pattern)
		if $pattern =~ m{^/+$};

	my $blessing = RE_NONE;

	if ($options{pathMode}) {
		$blessing |= RE_NEGATED if $pattern =~ s/^!//;
		$blessing |= RE_DIRECTORY if $pattern =~ s{/$}{};
		$blessing |= RE_FULL_MATCH if $pattern =~ m{/};
		$pattern =~ s{^/}{};
	}

	# xgettext doesn't parse Perl code in regexes.
	my $invalid_msg = __"invalid use of double asterisk";

	$pattern =~ s
				{
					(.*?)				# Anything, followed by ...
					(
					\\.					# escaped character
					|					# or
					\A\*\*(?=/)			# leading **/
					|					# or
					/\*\*(?=/|\z)		# /**/ or /** at end of string
					|					# or
					\*\*.				# invalid
					|					# or
					.\*\*				# invalid
					|					# or
					\.					# a dot
					|					# or
					\*					# an asterisk
					|
					\?			 		# a question mark
					|
					\[					# opening bracket
					!?
					\]?					# possible (literal) closing bracket
					(?:
					\\.					# escaped character
					|
					\[:[a-z]+:\]		# character class
					|
					[^\\\]]+		 	# non-backslash or closing bracket
					)+
					\]
					)?
				}{
					my $translated = quotemeta $1;
					if ('\\' eq substr $2, 0, 1) {
						$translated .= quotemeta substr $2, 1, 1;
					} elsif ('**' eq $2) {
						$translated .= '.*';
					} elsif ('/**' eq $2) {
						$translated .= '(?:/.*)?';
					} elsif ('.' eq $2) {
						$translated .= '\\.';
					} elsif ('*' eq $2) {
						$translated .= '[^/]*';
					} elsif ('?' eq $2) {
						$translated .= '[^/]';
					} elsif ('[' eq substr $2, 0, 1) {
						$translated .= _transpile_range $2;
					} elsif (length $2) {
						if ($2 =~ /\*\*/) {
							die $invalid_msg;
						}
						die "should not happen: $2";
					}
					$translated;
				}gsex;

	my $re = $options{ignoreCase} ? qr/^$pattern$/i : qr/^$pattern$/;

	bless $re, $blessing;
}

sub fnmatchstar {
	my ($pattern, $string, %options) = @_;

	my $transpiled = eval { translatestar $pattern, %options };
	return if $@;

	$string =~ $transpiled or return;

	return 1;
}

sub pnmatchstar {
	my ($pattern, $string, %options) = @_;

	$options{isDirectory} = 1 if $string =~ s{/$}{};

	my $full_path = $string;

	# Check whether the regular expression is compiled.
	# (ref $pattern) may be false here because it can be 0.
	my $reftype = reftype $pattern;
	unless (defined $reftype && $regex_type eq $reftype) {
		$pattern = eval { translatestar $pattern, %options, pathMode => 1 };
		return if $@;
	}

	my $flags = ref $pattern;
	$string =~ s{.*/}{} unless $flags & RE_FULL_MATCH;

	my $match = $string =~ $pattern;
	if ($flags & RE_DIRECTORY) {
		undef $match if !$options{isDirectory};
	}

	my $negated = $flags & RE_NEGATED;

	if ($match) {
		if ($negated) {
			return;
		} else {
			return 1;
		}
	}

	if ($full_path =~ s{/[^/]*$}{}) {
		return pnmatchstar $pattern, $full_path, %options, isDirectory => 1;
	}

	return 1 if $negated;

	return;
}

1;
