package File::Slurper::Dash;

our $DATE = '2019-10-06'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Carp 'croak';
use Exporter 5.57 'import';

use Encode qw(:fallbacks);
use PerlIO::encoding;

our @EXPORT_OK = qw/read_binary read_text read_lines write_binary write_text read_dir/;

sub read_binary {
	my $filename = shift;

	my $fh;

	if ($filename eq '-') {
		$fh = *STDIN;
	} else {
		# This logic is a bit ugly, but gives a significant speed boost
		# because slurpy readline is not optimized for non-buffered usage
		open my $fh, '<:unix', $filename or croak "Couldn't open $filename: $!";
        }

	if (my $size = -s $fh) {
		my $buf;
		my ($pos, $read) = 0;
		do {
			defined($read = read $fh, ${$buf}, $size - $pos, $pos) or croak "Couldn't read $filename: $!";
			$pos += $read;
		} while ($read && $pos < $size);
		return ${$buf};
	}
	else {
		return do { local $/; <$fh> };
	}
}

use constant {
	CRLF_DEFAULT => $^O eq 'MSWin32',
	HAS_UTF8_STRICT => scalar do { local $@; eval { require PerlIO::utf8_strict } },
};

sub _text_layers {
	my ($encoding, $crlf) = @_;
	$crlf = CRLF_DEFAULT if $crlf && $crlf eq 'auto';

	if ($encoding =~ /^(latin|iso-8859-)1$/i) {
		return $crlf ? ':unix:crlf' : ':raw';
	}
	elsif (HAS_UTF8_STRICT && $encoding =~ /^utf-?8\b/i) {
		return $crlf ? ':unix:utf8_strict:crlf' : ':unix:utf8_strict';
	}
	else {
		# non-ascii compatible encodings such as UTF-16 need encoding before crlf
		return $crlf ? ":raw:encoding($encoding):crlf" : ":raw:encoding($encoding)";
	}
}

sub read_text {
	my ($filename, $encoding, $crlf) = @_;
	$encoding ||= 'utf-8';
	my $layer = _text_layers($encoding, $crlf);
	return read_binary($filename) if $layer eq ':raw';

	local $PerlIO::encoding::fallback = FB_CROAK;
	my $fh;
	if ($filename eq '-') {
		$fh = *STDIN;
	} else {
		open $fh, "<$layer", $filename or croak "Couldn't open $filename: $!";
	}
	return do { local $/; <$fh> };
}

sub write_text {
	my ($filename, undef, $encoding, $crlf) = @_;
	$encoding ||= 'utf-8';
	my $layer = _text_layers($encoding, $crlf);

	local $PerlIO::encoding::fallback = FB_CROAK;
	my $fh;
	if ($filename eq '-') {
		$fh = *STDOUT;
	} else {
		open $fh, ">$layer", $filename or croak "Couldn't open $filename: $!";
	}
	print $fh $_[1] or croak "Couldn't write to $filename: $!";
	close $fh or croak "Couldn't write to $filename: $!";
	return;
}

sub write_binary {
	return write_text(@_[0,1], 'latin-1');
}

sub read_lines {
	my ($filename, $encoding, $crlf, $skip_chomp) = @_;
	$encoding ||= 'utf-8';
	my $layer = _text_layers($encoding, $crlf);

	local $PerlIO::encoding::fallback = FB_CROAK;
	my $fh;
	if ($filename eq '-') {
		$fh = *STDIN;
	} else {
		open $fh, "<$layer", $filename or croak "Couldn't open $filename: $!";
	}
	return <$fh> if $skip_chomp;
	my @buf = <$fh>;
	close $fh;
	chomp @buf;
	return @buf;
}

sub read_dir {
	my ($dirname) = @_;
	opendir my ($dir), $dirname or croak "Could not open $dirname: $!";
	return grep { not m/ \A \.\.? \z /x } readdir $dir;
}

1;

# ABSTRACT: A fork of File::Slurper to grok "-" as stdin/stdout

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Slurper::Dash - A fork of File::Slurper to grok "-" as stdin/stdout

=head1 VERSION

This document describes version 0.001 of File::Slurper::Dash (from Perl distribution File-Slurper-Dash), released on 2019-10-06.

=head1 SYNOPSIS

 # use like you would File::Slurper
 use File::Slurper::Dash 'read_text', 'write_text';

 my $content = read_text("-"); # read from stdin

 write_text('-', $content); # write to stdout

=head1 DESCRIPTION

This module is a fork of L<File::Slurper> 0.009. It's exactly like
File::Slurper, except that it groks "-" to mean read from STDIN, or write to
STDOUT.

=head1 FUNCTIONS

=head2 read_text

=head2 read_binary($filename)

=head2 read_lines($filename, $encoding, $crlf, $skip_chomp)

=head2 write_text($filename, $content, $encoding, $crlf)

=head2 write_binary($filename, $content)

=head2 read_dir($dirname)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Slurper-Dash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Slurper-Dash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Slurper-Dash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Slurp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
