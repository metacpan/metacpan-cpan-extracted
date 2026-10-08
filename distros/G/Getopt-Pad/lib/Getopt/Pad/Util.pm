package Getopt::Pad::Util;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Encode ();
use Exporter qw(import);
use Feature::Compat::Try;

our $VERSION   = '0.06';
our @EXPORT_OK = qw(camelize specError expandTilde useColor isValidName optionSpelling processedWith scalarsIn decodedWord encodedFor);

sub useColor($handle) {
	return (-t $handle) && !length($ENV{NO_COLOR} // '') && (($ENV{TERM} // '') ne 'dumb') ? 1 : 0;
}

# A command line word as characters, like the values of config files. A
# word that is decoded already (perl -CA, or a caller's own decode) is
# taken as it is; one that is not valid UTF-8, such as a Latin-1 file
# name, stays bytes.
sub decodedWord($word) {
	return $word if !defined $word || utf8::is_utf8($word) || $word !~ /[\x80-\xFF]/;

	try {
		return Encode::decode('UTF-8', $word, Encode::FB_CROAK | Encode::LEAVE_SRC);
	}
	catch ($error) {
		return $word;
	}
}

# $text as it is printed on $handle. Text holding characters is encoded
# as UTF-8, unless the handle encodes by itself (perl -CS, an :encoding
# layer). Byte strings, such as the help texts of a program without
# 'use utf8', are printed as the program wrote them.
sub encodedFor($handle, $text) {
	return $text if !utf8::is_utf8($text);
	return $text if grep { /\A(?:utf8|encoding)\b/ } PerlIO::get_layers($handle, output => 1);
	return Encode::encode('UTF-8', $text);
}

sub expandTilde($path) {
	return $path if !defined $ENV{HOME};
	return $path =~ s{^~(?=/|$)}{$ENV{HOME}}r;
}

# The one shape an option name, an alias, an arg short name and a command
# name share: a letter, then word characters or dashes.
sub isValidName($name) {
	return defined $name && $name =~ /\A[a-zA-Z][\w-]*\z/ ? 1 : 0;
}

# An option name as it is typed: a name of one letter with one dash, a
# longer one with two.
sub optionSpelling($name) {
	return length $name == 1 ? '-' . $name : '--' . $name;
}

sub camelize($name) {
	my ($first, @rest) = split /[-_]+/, $name // '';
	specError("cannot derive a reader name from '%s'", $name // '') if !defined $first || $first eq '';

	my $reader = $first . join('', map { ucfirst } @rest);
	specError("derived reader name '%s' (from '%s') is not a valid identifier", $reader, $name) if $reader !~ /^[a-zA-Z_]\w*$/;

	return $reader;
}

# $value with every scalar in it replaced by what the processValue
# $callback of an option or arg returns for it, the shape kept. $result is
# the Result the callback sees. An unset scalar (undef) is left alone.
sub processedWith($callback, $result, $value) {
	return $value if !defined $callback || !defined $value;
	return [map { processedWith($callback, $result, $_) } $value->@*] if ref $value eq 'ARRAY';
	return { map { $_ => processedWith($callback, $result, $value->{$_}) } keys $value->%* } if ref $value eq 'HASH';
	return $callback->($result, $value);
}

# Every single value in $value: the value itself, or the scalars of a
# list, a mapping or a list of mappings.
sub scalarsIn($value) {
	return map { scalarsIn($_) } $value->@*        if ref $value eq 'ARRAY';
	return map { scalarsIn($_) } values $value->%* if ref $value eq 'HASH';
	return ($value);
}

# Spec mistakes are programmer errors: report them at the first caller
# outside Getopt::Pad, normally the GetOptions call, not at the library
# frame that noticed them.
sub specError($format, @args) {
	my $frame = 0;
	$frame++ while (caller($frame + 1))[0] && (caller($frame))[0] =~ /\AGetopt::Pad(?:::|\z)/;
	my (undef, $file, $line) = caller($frame);

	# An uncaught die exits with $! or $? when either is set; clearing both
	# makes every spec error end the program with status 255.
	($!, $?) = (0, 0);
	die sprintf("Getopt::Pad spec: %s at %s line %d.\n", sprintf($format, @args), $file, $line);
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Util - Helper functions (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

=head1 FUNCTIONS

All functions are exported on request.

=over 4

=item camelize($name)

The reader name for an option or arg name: split at dashes and
underscores, every part after the first with its first letter upper case
(C<log-level> becomes C<logLevel>). A spec error if the result is not a
valid Perl identifier.

=item isValidName($name)

Whether C<$name> is a valid option name, alias, arg name or command name:
a letter, followed by word characters or dashes.

=item optionSpelling($name)

An option name as it is typed: C<-v> for a name of one letter, else
C<--verbose>.

=item specError($format, @args)

Dies with C<Getopt::Pad spec: MESSAGE at FILE line LINE.>, where FILE and
LINE are those of the first caller outside Getopt::Pad, normally the
C<GetOptions> call. C<$!> and C<$?> are cleared first, so an uncaught
spec error exits with status 255.

=item scalarsIn($value)

Every single value in C<$value>: the value itself, or the scalars of a
list, a mapping or a list of mappings.

=item processedWith($callback, $result, $value)

C<$value> with every single value in it replaced by
C<< $callback->($result, $single) >>; arrayrefs and hashrefs around them
are rebuilt in the same shape. C<undef> and a missing C<$callback> leave
the value as it is. Options and args use it for C<processValue>.

=item decodedWord($word)

A command line word as a character string: decoded from UTF-8 unless it
is decoded already or is not valid UTF-8, in which case it is returned
as it is.

=item encodedFor($handle, $text)

C<$text> as it is printed on C<$handle>: encoded as UTF-8 when it holds
characters and the handle has no encoding layer, else unchanged.

=item expandTilde($path)

Replaces a leading C<~> (alone or followed by C</>) with C<$HOME>. Returns
the path unchanged when C<HOME> is not set.

=item useColor($handle)

Whether output to C<$handle> should be colored: it is a terminal,
C<NO_COLOR> is empty or unset, and C<TERM> is not C<dumb>.

=back

=head1 SEE ALSO

L<Getopt::Pad>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
