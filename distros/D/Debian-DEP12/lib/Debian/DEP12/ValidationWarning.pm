package Debian::DEP12::ValidationWarning;

use strict;
use warnings;

# ABSTRACT: validaton warning class
our $VERSION = '0.1.0'; # VERSION

use parent 'Text::BibTeX::Validate::Warning';

=head1 NAME

Debian::DEP12::ValidationWarning - validaton warning class

=head1 SYNOPSIS

    use Debian::DEP12::ValidationWarning;

    my $warning = Debian::DEP12::ValidationWarning->new(
        'value \'%(value)s\' is better written as \'%(suggestion)s\'',
        {
            field => 'Bug-Submit',
            value => 'merkys@cpan.org',
            suggestion => 'mailto:merkys@cpan.org',
        }
    );
    print STDERR "$warning\n";

=head1 DESCRIPTION

Debian::DEP12::ValidationWarning is used to store the content of
validation warning in a structured way. Currently the class is based on
L<Text::BibTeX::Validate::Warning|Text::BibTeX::Validate::Warning>, but
may be decoupled in the future.

=head1 METHODS

=head2 new( $message, $fields )

Takes L<Text::sprintfn|Text::sprintfn>-compatible template and a hash
with the values for replacement in the template. Three field names are
reserved and used as prefixes for messages if defined: C<file> for the
name of a file, C<key> for the index inside list and C<field> for DEP12
field name. Field C<suggestion> is also somewhat special, as
L<Debian::DEP12|Debian::DEP12> may use its value to replace the original
in an attempt to clean up the DEP12 entry.

=head2 fields()

Returns an array of fields defined in the instance in any order.

=head2 get( $field )

Returns value of a field.

=head2 set( $field, $value )

Sets a new value for a field. Returns the old value.

=head2 delete( $field )

Unsets value for a field. Returns the old value.

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
