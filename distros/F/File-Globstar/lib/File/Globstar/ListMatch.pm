# Copyright (C) 2016-2023 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

# This next lines is here to make Dist::Zilla happy.
# ABSTRACT: Perl Globstar (double asterisk globbing) and utils

package File::Globstar::ListMatch;
$File::Globstar::ListMatch::VERSION = 'v1.1.0';
use strict;

use Locale::TextDomain qw(File-Globstar);
use Scalar::Util 1.21 qw(reftype);
use IO::Handle;

use File::Globstar qw(translatestar pnmatchstar);

use constant RE_NONE => File::Globstar::RE_NONE();
use constant RE_NEGATED => File::Globstar::RE_NEGATED();
use constant RE_FULL_MATCH => File::Globstar::RE_FULL_MATCH;
use constant RE_DIRECTORY => File::Globstar::RE_DIRECTORY;

sub new {
	my ($class, $input, %options) = @_;

	my $self = {};
	bless $self, $class;
	$self->{__ignore_case} = delete $options{ignoreCase};
	$self->{__filename} = delete $options{filename};

	if (ref $input) {
		my $type = reftype $input;
		if ('SCALAR' eq $type) {
			$self->_readString($$input);
		} elsif ('ARRAY' eq $type) {
			$self->_readArray($input);
		} else {
			$self->_readFileHandle($input);
		}
	} elsif ("GLOB" eq reftype \$input) {
		$self->_readFileHandle(\$input, );
	} else {
		$self->_readFile($input);
	}

	return $self;
}

sub __match {
	my ($self, $imode, $path, $is_directory) = @_;

	my $match;
	foreach my $pattern ($self->patterns) {
		my $type = ref $pattern;
		my $negated;
		if ($type & RE_NEGATED) {
			next if !$match;
			$negated = 1;
		} else {
			next if $match;
		}

		$match = pnmatchstar $pattern, $path, isDirectory => $is_directory;
	}

	return 1 if $match;

	# Check that none of its parent directories has been ignored.
	if (!$imode) {
		$path =~ s{/$}{};

		while ($path =~ s{/[^/]*$}{} && length $path) {
			return 1 if $self->__match(undef, $path, 1);
		}
	}

	return;
}

sub match {
	my ($self) = shift @_;

	return $self->__match(undef, @_);
}

sub matchExclude {
	&match;
}

sub matchInclude {
	my ($self) = shift @_;

	return $self->__match(1, @_);
}

sub patterns {
	return @{shift->{__patterns}};
}

sub _readArray {
	my ($self, $lines) = @_;

	my @patterns;
	$self->{__patterns} = \@patterns;

	my $ignore_case = $self->{__ignore_case};
	foreach my $line (@$lines) {
		my $transpiled = eval {
			translatestar $line,
			ignoreCase => $ignore_case,
			pathMode => 1
		};

		# Why a slash? When matching, we discard a trailing slash from the
		# string to match.  The regex '/$' can therefore never match.  And the
		# leading caret is there in order to save Perl at least reading the
		# string to the end.
		$transpiled = qr{^/$} if $@;
		push @patterns, $transpiled;
	}

	return $self;
}

sub _readString {
	my ($self, $string) = @_;

	my @lines;
	foreach my $line (split /\n/, $string) {
		next if $line =~ /^#/;

		# If the string contains trailing whitespace we have to count the
		# number of backslashes in front of the first whitespace character.
		if ($line =~ s/(\\*)([\x{9}-\x{13} ])[\x{9}-\x{13} ]*$//) {
			my ($bs, $first) = ($1, $2);
			if ($bs) {
				$line .= $bs;

				my $num_bs = $bs =~ y/\\/\\/;

				# If the number of backslashes is odd, the last space was
				# escaped.
				$line .= $first if $num_bs & 1;
			}
		}
		next if '' eq $line;

		push @lines, $line;
	}

	return $self->_readArray(\@lines);
}

sub _readFileHandle {
	my ($self, $fh) = @_;

	my $filename = $self->{__filename};
	$filename = __["in memory string"] if File::Globstar::empty($filename);

	$fh->clearerr;
	my @lines = $fh->getlines;

	die __x("Error reading '{filename}': {error}!\n",
	        filename => $filename, error => $!) if $fh->error;

	return $self->_readString(join '', @lines);
}

sub _readFile {
	my ($self, $filename) = @_;

	$self->{__filename} = $filename
		if File::Globstar::empty($self->{__filename});

	open my $fh, '<', $filename
		or die __x("Error reading '{filename}': {error}!\n",
		           filename => $filename, error => $!);

	return $self->_readFileHandle($fh);
}

1;
