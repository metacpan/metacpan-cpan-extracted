package Getopt::Pad::Util;

use v5.26;
use strict;
use warnings;
use experimental 'signatures';

use Exporter qw(import);

our $VERSION   = '0.03';
our @EXPORT_OK = qw(camelize specError expandTilde useColor isValidName);

sub useColor($handle) {
	return (-t $handle) && !length($ENV{NO_COLOR} // '') && (($ENV{TERM} // '') ne 'dumb') ? 1 : 0;
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

sub camelize($name) {
	my ($first, @rest) = split /[-_]+/, $name // '';
	specError("cannot derive a reader name from '%s'", $name // '') if !defined $first || $first eq '';

	my $reader = $first . join('', map { ucfirst } @rest);
	specError("derived reader name '%s' (from '%s') is not a valid identifier", $reader, $name) if $reader !~ /^[a-zA-Z_]\w*$/;

	return $reader;
}

# Spec mistakes are programmer errors: report them at the first caller
# outside Getopt::Pad, normally the GetOptions call, not at the library
# frame that noticed them.
sub specError($format, @args) {
	my $frame = 0;
	$frame++ while (caller($frame + 1))[0] && (caller($frame))[0] =~ /\AGetopt::Pad(?:::|\z)/;
	my (undef, $file, $line) = caller($frame);
	die sprintf("Getopt::Pad spec: %s at %s line %d.\n", sprintf($format, @args), $file, $line);
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Util - internal helpers

=head1 DESCRIPTION

Internal helpers: camelCase reader derivation (camelize), the shared name check for options, aliases, args and commands (isValidName), spec error reporting at the caller outside the library (specError), tilde expansion (expandTilde) and the color decision for a handle (useColor). Not part of the public API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
