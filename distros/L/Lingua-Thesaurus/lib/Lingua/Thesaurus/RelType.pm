package Lingua::Thesaurus::RelType;
use Moose;
use namespace::clean -except => 'meta';

has 'rel_id'           => (is => 'ro', isa => 'Str', required => 1,
         documentation => "identifier for the relation type");

has 'description'      => (is => 'ro', isa => 'Str',
         documentation => "description of the relation");

has 'inverse_id'       => (is => 'ro', isa => 'Maybe[Str]',
         documentation => "id of the inverse relation");

has 'is_external'      => (is => 'ro', isa => 'Bool',
         documentation => "true if the related item is an external string "
                        . "(i.e. not a term)");

1;

__END__

=head1 NAME

Lingua::Thesaurus::RelType - Relation type in a thesaurus

=head1 DESCRITION

A C<RelType> object is just a datastructure with the following
fields:

=over

=item rel_id

String, unique identifier for this relation type (e.g. 'NT', 'BT', 'RT', etc.)

=item description

Description string for this relation type

=item inverse_id

Unique identifier for the reciprocal relation, if any.

=item is_external

Boolean stating whether the item related to the lead term is another term,
or is some external data (for example a "Scope Note").

=back


