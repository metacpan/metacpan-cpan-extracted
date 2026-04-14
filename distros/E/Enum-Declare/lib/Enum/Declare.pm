package Enum::Declare;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.04';

use Devel::CallParser;
use Object::Proto;

require XSLoader;
XSLoader::load('Enum::Declare', $VERSION);

use Enum::Declare::Meta;

our %_registry;

=head1 NAME

Enum::Declare - Declarative enums with compile-time constants

=head1 SYNOPSIS

	use Enum::Declare;

	# Basic integer enum (auto-increments from 0)
	enum Colour {
	    Red,
	    Green,
	    Blue,
	}

	say Red;    # 0
	say Green;  # 1
	say Blue;   # 2

	# Explicit values
	enum HttpStatus {
	    OK = 200,
	    NotFound = 404,
	    ServerError = 500,
	}

	# String enum
	enum LogLevel :Str {
	    Debug,
	    Info,
	    Warn = "warning",
	}

	say Debug;  # "debug"
	say Warn;   # "warning"

	# Bitflag enum (powers of 2)
	enum Perms :Flags {
	    Read,
	    Write,
	    Execute,
	}

	say Read;              # 1
	say Write;             # 2
	say Read | Write;      # 3

	# Auto-exported constants
	enum Colour :Export {
	    Red,
	    Green,
	    Blue,
	}

	# Meta introspection
	my $meta = Colour();
	say $meta->count;              # 3
	say $meta->name(0);            # "Red"
	say $meta->value('Green');     # 1
	say $meta->valid(2);           # 1
	my @pairs = $meta->pairs;      # (Red => 0, Green => 1, Blue => 2)
	my $names  = $meta->names;     # ['Red', 'Green', 'Blue']
	my $values = $meta->values;    # [0, 1, 2]

=head1 DESCRIPTION

Enum::Declare provides a declarative C<enum> keyword for defining enumerated
types in Perl. Constants are installed as true constant subs at compile time
and a metadata object is accessible via the enum name.

=head2 Attributes

Attributes are specified after the enum name with a colon prefix. Multiple
attributes may be combined.

=over 4

=item C<:Str>

Values are strings. Variants without an explicit value default to their
lowercased name.

=item C<:Flags>

Values are assigned as ascending powers of 2 (1, 2, 4, 8, ...), suitable for
use as bitflags.

=item C<:Export>

Populates C<@EXPORT> and C<@EXPORT_OK> in the declaring package and adds
L<Exporter> to C<@ISA>, allowing consumers to import the constants via
C<use>.

=back

=head2 Explicit Values

Any variant may be given an explicit value with C<= VALUE>. For integer enums
subsequent variants auto-increment from the last explicit value. For string
enums the value must be a quoted string.

	enum Example {
	    A = 10,
	    B,          # 11
	    C = 20,
	    D,          # 21
	}

=head2 Meta Object

Calling the enum name as a function returns an L<Enum::Declare::Meta> object:

	my $meta = EnumName();

Methods on the meta object:

=over 4

=item C<names>

Returns an arrayref of variant names.

=item C<values>

Returns an arrayref of variant values.

=item C<name($value)>

Returns the variant name for the given value.

=item C<value($name)>

Returns the value for the given variant name.

=item C<valid($value)>

Returns true if the value belongs to the enum.

=item C<pairs>

Returns a flat list of name/value pairs.

=item C<count>

Returns the number of variants.

=item C<match($value, \%handlers)>

Exhaustive pattern match. Every variant must have a corresponding handler in
the hash, or a C<_> wildcard default must be present. Dies with a
C<Non-exhaustive match> error if any variants are unhandled.

	my $hex = Color()->match($val, {
	    Red   => sub { '#ff0000' },
	    Green => sub { '#00ff00' },
	    Blue  => sub { '#0000ff' },
	});

A wildcard C<_> handler catches any unmatched or unknown value:

	my $label = Color()->match($val, {
	    Red => sub { 'stop' },
	    _   => sub { 'go' },
	});

Each handler receives the matched value as its argument.

=back

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-enum-declare at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Enum-Declare>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Enum::Declare


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Enum-Declare>

=item * Search CPAN

L<https://metacpan.org/release/Enum-Declare>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Enum::Declare
