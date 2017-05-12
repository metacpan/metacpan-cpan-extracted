package Devel::FindGlobals;

use strict;
use Devel::Size qw(size total_size);

use base 'Exporter';
our @EXPORT = qw(find_globals find_globals_sizes print_globals_sizes);

# may be overriden
our @TYPES = qw(SCALAR ARRAY HASH);
# for pretty output
our %SYMS = (
	SCALAR	=> '$',
	ARRAY	=> '@',
	HASH	=> '%',
	CODE	=> '&',
);

our $VERSION = 0.03;

{
	# we don't want to hit a variable more than once, because we
	# can get in a loop
	my %seen = ();

	sub _seen {
		my($sym) = @_;
		if ($seen{$sym}) {
			return 1;
		} else {
			$seen{$sym} = 1;
			return 0;
		}
	}

	sub _reset_seen {
		%seen = ();
	}
}


=head1 NAME

Devel::FindGlobals - Find global variables and their size

=head1 SYNOPSIS

	use Devel::FindGlobals;
	print print_globals_sizes();

=head1 DESCRIPTION

This module just runs around and over the symbol table, finds global variables,
gets their sizes with Devel::Size, and then prints them out.

find_globals() just finds the globals (and returns a hashref), and
find_globals_sizes() returns the globals and the sizes in a hashref.
print_globals_sizes() prints out that data in a pretty table.

find_globals() hashref is of the form $hash->{TYPE}{NAME}, where TYPE
is SCALAR, ARRAY, HASH (types stored in @Devel::FindGlobals::TYPES).

find_globals_sizes() hashref is the same, except that the value of the
record is not C<1> but an arrayref of size and total_size (size is the
size of the variable itself, and total_size counts up all the other
members of the variable, for arrayrefs and hashrefs).

print_globals_sizes() accepts an OPTIONS hash.  Currently recognized
options are:

=over 4

=item * ignore_files

Ignore file globals (like C<$main::_</usr/local/lib/perl5/5.8.0/vars.pm>).
Default value is true.

=item * ignore_undef_scalars

Ignore scalars that exist, but are not defined.  Default value is true.

=item * exclude_match

An arrayref of strings to match; e.g., ['^VERSION$', '^Debug'].  Will not print
variables matching any of the expressions.

=item * include_match

Same as exclude_match, except for variables to exclusively include, instead of
strings to exclude.

=item * lexicals

A hashref of C<name => reference> for lexical variables to include in the report.

=back

=head1 BUGS

Code references, being not handled by Devel::Size, are not handled by this module.

=cut

sub print_globals_sizes {
	my %opts = &_get_opts;
	my $all  = &find_globals_sizes;

	my $output = '';

	if (ref $opts{lexicals}) {
		$output .= sprintf "\n%-45.45s   %15s  %15s\n" . ('=' x 80) . "\n",
			"Name of lexical variable", "Size", "Total Size";

		for my $name (sort keys %{$opts{lexicals}}) {
			$output .= sprintf "%-45s   %15d  %15d\n", $name,
				size($opts{lexicals}{$name}),
				total_size($opts{lexicals}{$name});
		}
	}

	for my $type (@TYPES) {
		$output .= sprintf "\n%-45.45s   %15s  %15s\n" . ('=' x 80) . "\n",
			"Name of $type variable", "Size", "Total Size";

		for my $full (sort keys %{$all->{$type}}) {
			# list strings to explicitly exclude ...
			if (ref $opts{exclude_match} &&
			     grep { $full =~ /$_/ } @{$opts{exclude_match}}) {
				next;
			}

			# ... or include
			if (ref $opts{include_match} &&
			    !grep { $full =~ /$_/ } @{$opts{include_match}}) {
				next;
			}

			# files are stores in special scalars, we don't care, usually
			if ($opts{ignore_files}) {
				next if $full =~ /^main::_</;
			}

			# many scalars end up being created for subs etc. ...
			if ($opts{ignore_undef_scalars} && $type eq 'SCALAR') {
				next unless defined $$full;
			}

			(my $print = $full) =~ s/([^[:print:]]|\s)/sprintf("%%%02X", ord $1)/ge;
			$print = $SYMS{$type} . $print if $SYMS{$type};

			$output .= sprintf "%-45.45s   %15d  %15d\n",
				$print, @{$all->{$type}{$full}};
		}
	}
	return $output;
}


# get the sizes for each global (size == size of *V, total_size == size of entire
# structure (e.g., references))
sub find_globals_sizes {
	my $all = find_globals();

	no strict 'refs';
	for my $type (@TYPES) {
		for my $full (keys %{$all->{$type}}) {
			local $^W;
			$all->{$type}{$full} = [
				size(*{$full}{$type}),
				total_size(*{$full}{$type})
			];
		}
	}

	return $all;
}

# recursively find all the global variables and stick them in a hashref
sub find_globals {
	my($sym, $all) = @_;
	$sym ||= 'main::';
	if (!$all) {
		&_reset_seen;
		$all = {};
	}

	return if _seen($sym);

	no strict 'refs';
	for my $name (keys %$sym) {

		if ($name =~ /::$/) { # new symbol table
			my $new = $sym eq 'main::' ? $name : $sym . $name;
			find_globals($new, $all);
			next;
		} 

		my $full = "$sym$name";
		next if _seen($full);

		for my $type (@TYPES) {
			if (defined *{$full}{$type}) {
				$all->{$type}{$full} = 1;
			}
		}
	}

	return $all;
}

sub _get_opts {
	my %opts = @_;
	$opts{ignore_files} = 1 unless defined $opts{ignore_files};
	$opts{ignore_undef_scalars} = 1 unless defined $opts{ignore_undef_scalars};
	return %opts;
}

1;

=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 2002-2004 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

perl(1), perlguts(1), Devel::Size.

=cut

__END__
