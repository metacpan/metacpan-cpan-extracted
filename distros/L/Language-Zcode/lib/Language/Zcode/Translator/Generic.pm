package Language::Zcode::Translator::Generic;

use strict;
use warnings;

=head1 NAME

Language::Zcode::Translator::Generic

=head1 DESCRIPTION

Abstract class that's the parent of all language-specific translators.

A translator has methods to translate Z-code into a given other language.

=head2 Methods

(Implement all of these to have a valid language translator.)

=head3 program_start

Returns a string that should be at the beginning of the output program.
(Empty by default)

=head3 program_end

Returns a string that should be at the end of the output program.
(Empty by default)

=cut

sub program_start { "" }
sub program_end { "" }

=head3 routine_start

Returns a string that should be at the beginning of each output subroutine.
Might have side effects (e.g., tell translator to start indenting).

Input: Name of sub, array of initial local variable values (all 0 for v5+)

=head3 translate_command(command_hashref)

This is the translation workhorse. Translate a command (a reference
to a hash returned by a LZ::Parser::parse routine) to the destination
language.

=head3 routine_end

Returns a string that should be at the end of each output subroutine.
Might have side effects (e.g., tell translator to stop indenting).

=head3 packed_address_str(address, type_of_address)

String representing a version-dependent packed address.
(Note packing is different for routines and strings in V6/7.)

Calculate actual address if $address is a number.
Create a language-dependent multiplication string
by calling language-dependent mult_add_str otherwise.

=cut

sub library { "" }

sub packed_address_str {
    my ($self, $address, $key) = @_;
    my %c = %Language::Zcode::Util::Constants;
    my $mult = $c{packed_multiplier};
    my $add;
    # (Add will be zero for versions not 6 or 7)
    if ($key eq "routine") {
	$add = 8 * $c{routines_offset};
    } elsif ($key eq "packed_address_of_string") {
	$add = 8 * $c{strings_offset};
    } else { die "Unknown key $key to packed_address_str" }

    # Now actually create the string. Only do calculation for true number
    if ($address =~ /^\d+$/) {
#    if ($address =~ /^(sp|local\d+|g[a-f\d]{2})$/) {
	return $mult * $address + $add;
    } else {
	return $self->mult_add_str($address, $mult, $add);
    }
}

=head3 mult_add_str(thing, multiplier, adder)

Create a language-dependent multiplication/addition string
thing*multiplier + adder

=cut

sub mult_add_str {
    my ($self, $thing, $mult, $add) = @_;
    # works for Perl, C, BASIC, java...
    return $add ? "$thing * $mult + $add" : "$thing * $mult";

}

sub AUTOLOAD {
    die "Tried to call $Plotz::Translator::Generic::AUTOLOAD for abstract class!"}

sub DESTROY {1} # make AUTOLOAD happy

# end package Plotz::Translator::Generic

1;

