package MARC::Spec::Field;

use Moo;
use namespace::clean;

extends 'MARC::Spec::Structure';

our $VERSION = '0.1.4';

has tag => (
    is => 'rw',
    required => 1
);

has indicator1 => (
    is => 'rw',
    predicate => 1
);
    
has indicator2 => (
    is => 'rw',
    predicate => 1
);

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args % 2 == 1) { unshift @args, "tag" }
    return { @args };
}
1;
__END__

=encoding utf-8

=head1 NAME

L<MARC::Spec::Field|MARC::Spec::Field> - field specification

=head1 SYNOPSIS

    use MARC::Spec::Field;
    
    my $field = MARC::Spec::Field->new('246');
    say ref $field;           # MARC::Spec::Field
    say $field->tag;          # 246
    say $field->index_start;  # 0
    say $field->index_end;    # '#'

=head1 DESCRIPTION

L<MARC::Spec::Field|MARC::Spec::Field> is the field specification of a L<MARC::Spec|MARC::Spec>.

See L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/> for further 
details on the syntax.

=head1 METHODS

Some methods are inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 new(Str)

Create a new MARC::Spec::Field instance. Parameter must be a valid MARCspec field tag.

=head2 add_subspec(MARC::Spec::Subspec)

Appends a subspec to the array of the attribute subspecs. Parameter must be an instance of 
L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

=head2 add_subspecs(ArrayRef[MARC::Spec::Subspec])

Appends subspecs to the array of the attribute subspecs. Parameter must be an ArrayRef and 
elements must be instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>.

=head2 to_string

Returns the spec as a string.

=head1 PREDICATES

Some predicates are inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 has_char_start

True if attribute char_start has an value and false otherwise.

=head2 has_char_end

True if attribute char_end has an value and false otherwise.

=head2 has_char_pos

True if attribute char_pos has an value and false otherwise.

=head2 has_indicator1

True if attribute indicator 1 has an value and false otherwise.

=head2 has_indicator2

True if attribute indicator 2 has an value and false otherwise.

=head2 has_subspecs

Returns true if attribute subspecs has an value and false otherwise.

=head1 ATTRIBUTES

Some attributes are inherited from L<MARC::Spec::Structure|MARC::Spec::Structure>.

=head2 base

Obligatory. Scalar. The base Field spec without subspecs.

=head2 tag

Obligatory. The field tag.

=head2 char_pos

If defined, the character position or range. Only present if MARC::Spec::Field::$char_start is defined.

=head2 char_start

If defined, the beginning character position of a character position or range.

=head2 char_end

If defined, the ending character position of a character position or range.
Only present if MARC::Spec::Field::$char_start is defined.

=head2 char_length

The difference of MARC::Spec::Field::$char_start and MARC::Spec::Field::$char_end if both are numeric
(or else -1).
Only present if MARC::Spec::Field::$char_start is defined.

=head2 char_pos

If defined, the character position or range.
Only present if MARC::Spec::Field::$char_start is defined.

=head2 index_start

Obligatory. The beginning index of field repetitions. Maybe a positiv integer or the character '#'.
Default is 0.

=head2 index_end

Obligatory. The ending index of field repetitions. Maybe a positiv integer or the character '#'.
Default is '#'.

=head2 index_length

Obligatory. The difference of MARC::Spec::Field::$index_start and MARC::Spec::Field::$index_end if both are numeric.
Default is -1.

=head2 indicator1

If defined, the indicator 1 of a data field. Only present if MARC::Spec::Field::$char_start is not defnied.

=head2 indicator2

If defined, the indicator 2 of a data field. Only present if MARC::Spec::Field::$char_start is not defnied.

=head2 subspecs

Optional. An array of instances of L<MARC::Spec::Subspec|MARC::Spec::Subspec>, thus all subspecs in this 
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

L<MARC::Spec|MARC::Spec>,
L<MARC::Spec::Subfield|MARC::Spec::Subfield>,
L<MARC::Spec::Subspec|MARC::Spec::Subspec>,
L<MARC::Spec::Structure|MARC::Spec::Structure>,
L<MARC::Spec::Comparisonstring|MARC::Spec::Comparisonstring>,
L<MARC::Spec::Parser|MARC::Spec::Parser>

=cut
