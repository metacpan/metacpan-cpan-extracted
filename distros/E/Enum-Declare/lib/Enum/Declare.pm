package Enum::Declare;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.08';

use Devel::CallParser;
use Object::Proto;

require XSLoader;
XSLoader::load('Enum::Declare', $VERSION);

use Enum::Declare::Meta;
use Enum::Declare::Set;

our %_registry;

1;

__END__

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

	# Enum sets - predefined constant set (frozen)
	enumSet PrimaryColours :Colour { Red, Blue }

	say PrimaryColours->has(Red);   # 1
	say PrimaryColours->has(Green); # 0

	# Mutable singleton set
	enumSet AllowedColours :Colour;
	AllowedColours->add(Red, Green);

	# Set as Object::Proto type constraint
	enumSet ColourSet :Type :Export :Colour;
	ColourSet->add(Red, Blue);

	# Slot holds a bare enum value validated against the set
	use Object::Proto;
	object 'Palette', 'name:Str', 'colours:ColourSet';

	my $p = Palette->new(name => 'warm', colours => Red);  # OK
	eval { Palette->new(name => 'bad', colours => Green) }; # dies

=head1 DESCRIPTION

Enum::Declare provides a declarative C<enum> keyword for defining enumerated
types in Perl. Constants are installed as true constant subs at compile time
and a metadata object is accessible via the enum name.

An C<enumSet> keyword creates typed sets over an enum's variants, supporting
membership tests, set algebra, and use as L<Object::Proto> type constraints.

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

=head2 Enum Sets

The C<enumSet> keyword creates an L<Enum::Declare::Set> over the variants of
an existing enum. The last colon-attribute is always the enum binding.

=head3 Predefined constant set (frozen)

	enumSet PrimaryColours :Colour { Red, Blue }

A block form lists specific variants. The resulting set is frozen and cannot
be modified at runtime.

=head3 Mutable singleton set

	enumSet ColourSet :Colour;

Without a block, an empty mutable singleton is installed as a constant sub.
Add or remove members at runtime:

	ColourSet->add(Red, Blue);
	ColourSet->remove(Blue);

=head3 Attributes

C<enumSet> supports the same C<:Export> and C<:Type> attributes as C<enum>.

=over 4

=item C<:Export>

Exports the set constant so consumers can import it.

=item C<:Type>

Registers the set as an L<Object::Proto> type constraint. Slots declared with
the set's name accept B<bare enum values> that are members of the set.
Set objects themselves are rejected.

	enumSet ColourSet :Type :Export :Colour;
	ColourSet->add(Red, Blue);

	object 'Palette', 'name:Str', 'colours:ColourSet';
	Palette->new(name => 'ok', colours => Red);    # accepted
	Palette->new(name => 'no', colours => Green);  # dies

Because the singleton is mutable, adding or removing members at runtime
dynamically expands or restricts what values the type constraint accepts.

=back

=head3 Set methods

Sets use a vec-based bitmask internally for O(1) membership tests and
bitwise set algebra. All algebra methods return a new mutable set.

=over 4

=item C<has($value)>

Returns true if C<$value> is a member of the set.

	ColourSet->has(Red);   # 1
	ColourSet->has(Green); # 0

=item C<add(@values)>

Adds one or more enum values to the set. Dies if the set is frozen. Returns
the set for chaining.

	ColourSet->add(Red, Blue);

=item C<remove(@values)>

Removes one or more enum values from the set. Dies if the set is frozen.
Returns the set for chaining.

	ColourSet->remove(Blue);

=item C<toggle(@values)>

Toggles membership of the given values (adds if absent, removes if present).
Dies if the set is frozen. Returns the set for chaining.

	ColourSet->toggle(Red, Green);

=item C<members>

Returns a list of the enum values currently in the set.

	my @vals = ColourSet->members;  # (0, 2)

=item C<names>

Returns a list of the variant names currently in the set.

	my @n = ColourSet->names;  # ('Red', 'Blue')

=item C<count>

Returns the number of members in the set.

	say ColourSet->count;  # 2

=item C<is_empty>

Returns true if the set contains no members.

=item C<clone>

Returns a new mutable copy of the set with the same members.

	my $copy = ColourSet->clone;

=item C<union($other)>

Returns a new set containing all members from both sets.

	my $all = $a->union($b);

=item C<intersection($other)>

Returns a new set containing only members present in both sets.

	my $common = $a->intersection($b);

=item C<difference($other)>

Returns a new set containing members in the invocant but not in C<$other>.

	my $only_a = $a->difference($b);

=item C<symmetric_difference($other)>

Returns a new set containing members in either set but not in both.

	my $xor = $a->symmetric_difference($b);

=item C<is_subset($other)>

Returns true if every member of the invocant is also in C<$other>.

=item C<is_superset($other)>

Returns true if the invocant contains every member of C<$other>.

=item C<is_disjoint($other)>

Returns true if the two sets share no members.

=item C<equals($other)>

Returns true if both sets contain exactly the same members. Also available
via the C<==> and C<!=> overloaded operators.

=back

=head3 Overloaded operators

=over 4

=item C<""> (stringification)

Returns C<Name(Member1, Member2, ...)>. For example C<ColourSet(Red, Blue)>.

=item C<==> / C<!=>

Delegate to C<equals>.

=item C<bool>

True if the set is non-empty.

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
