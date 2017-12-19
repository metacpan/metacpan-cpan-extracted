package MARC::Spec::Subfield;

use Moo;
use namespace::clean;

our $VERSION = '2.0.3';

extends 'MARC::Spec::Structure';

has code => (
    is => 'rw',
    required => 1
);

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args % 2 == 1) { unshift @args, "code" }
    return { @args };
}
1;

__END__

=encoding utf-8

=head1 NAME

MARC::Spec::Subfield - subfield specification

=head1 SYNOPSIS

    use MARC::Spec;
    
    my $ms = MARC::Spec->new('245$a/0-2);
    say ref $ms->subfields;                     # ARRAY
    say ref $ms->subfields->[0];                # MARC::Spec::Subfield

=head1 DESCRIPTION

MARC::Spec::Subfield is the subfield specification of a L<MARC::Spec|MARC::Spec>.

See L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/> for further 
details on the syntax.

=head1 METHODS

Some methods are inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 new

Create a new MARC::Spec::Subfield instance.

=head2 add_subspec(MARC::Spec::Subspec)

Appends a subspec to the array of the attribute subspecs. Parameter must be an instance of 
L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

Inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 add_subspecs(ArrayRef[MARC::Spec::Subspec])

Appends subspecs to the array of the attribute subspecs. Parameter must be an ArrayRef and 
elements must be instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

Inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 to_string

Returns the spec as a string.

Inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head1 PREDICATES

Some predicates are inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 has_char_start

True if attribute char_start has an value and false otherwise.

=head2 has_char_end

True if attribute char_end has an value and false otherwise.

=head2 has_char_pos

True if attribute char_pos has an value and false otherwise.

=head2 has_subspecs

Returns true if attribute subspecs has an value and false otherwise.

=head1 ATTRIBUTES

Some attributes are inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 base

Obligatory. The base Subfield spec without subspecs.

=head2 code

Obligatory. The subfield code.

=head2 char_pos

If defined, the character position or range. Only present if MARC::Spec::Subfield::$char_start is defined.

=head2 char_start

If defined, the beginning character position of a character position or range.

=head2 char_end

If defined, the ending character position of a character position or range.
Only present if MARC::Spec::Subfield::$char_start is defined.

=head2 char_length

The difference of MARC::Spec::Subfield::$char_start and MARC::Spec::Field::$char_end if both are numeric
(or else -1).
Only present if MARC::Spec::Subfield::$char_start is defined.

=head2 index_start

Obligatory. The beginning index of subfield repetitions. Maybe a positiv integer or the character '#'.
Default is 0.

=head2 index_end

Obligatory. The ending index of subfield repetitions. Maybe a positiv integer or the character '#'.
Default is '#'.

=head2 index_length

Obligatory. The difference of MARC::Spec::Subfield::$index_start and MARC::Spec::Subfield::$index_end if both are numeric.
Default is -1.

=head2 subspecs

Optional an array of instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>, thus all subspecs in this 
array MUST be validated as a combination with the boolean 'AND',
and/or an array of arrays (AoA) of instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>, thus all subspecs 
in this AoA must be validated as a combination with the boolean 'OR'.

See L<MARC::Spec::Subspec|MARC::Spec::Subspec> for description of attributes of L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

=head1 AUTHOR

Carsten Klee C<< <klee at cpan.org> >>

=head1 CONTRIBUTORS

=over

=item * Johann Rolschewski, C<< <jorol at cpan> >>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Carsten Klee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs to L<https://github.com/MARCspec/MARC-Spec/issues|https://github.com/MARCspec/MARC-Spec/issues>

=head1 SEE ALSO

=over

=item * L<MARC::Spec|MARC::Spec>

=item * L<MARC::Spec::Field|MARC::Spec::Field>

=item * L<MARC::Spec::Indicator|MARC::Spec::Indicator>

=item * L<MARC::Spec::Subspec|MARC::Spec::Subspec>

=item * L<MARC::Spec::Structure|MARC::Spec::Structure>

=item * L<MARC::Spec::Comparisonstring|MARC::Spec::Comparisonstring>

=item * L<MARC::Spec::Parser|MARC::Spec::Parser>

=back

=cut
