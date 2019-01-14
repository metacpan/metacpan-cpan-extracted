package JSONAPI::Document::Builder::Role::Attributes;
$JSONAPI::Document::Builder::Role::Attributes::VERSION = '2.4';
=head1 NAME

JSONAPI::Document::Builder::Role::Attributes - Utility role for JSON API attributes

=head1 VERSION

version 2.4

=head1 DESCRIPTION

Provides methods to retrieve and manipulate a resource documents attributes.

=cut

use Moo::Role;

use List::Util;

=head2 get_attributes(DBIx::Class::Row $row?) : HashRef

Retrieves the attributes for a given row.

Does all of the field manipulation according to the
relevant attributes of the consuming class, such as
returning a subset of fields, casing, etc.

=cut

sub get_attributes {
    my ($self, $row) = @_;
    $row //= $self->row;
    my $sparse_fieldset = $self->fields;

    if ($row->DOES('JSONAPI::Document::Role::Attributes')) {
        my $columns = $row->attributes($sparse_fieldset);
        if ($self->kebab_case_attrs) {
            return { $self->kebab_case(%$columns) };
        }
        return $columns;
    }

    my %columns = $row->get_inflated_columns();

    if ($columns{id}) {
        delete $columns{id};
    }

    if (defined($sparse_fieldset) && @$sparse_fieldset) {
        for my $field (keys(%columns)) {
            unless (List::Util::first { $_ eq $field } @$sparse_fieldset) {
                delete $columns{$field};
            }
        }
    }

    if ($self->kebab_case_attrs) {
        return { $self->kebab_case(%columns) };
    }
    return \%columns;
}

=head2 kebab_case(Hash $row) : Hash

Takes the keys of the given row and dash cases
them.

Will not kebab case columns whose names start
with an underscore, this is to allow private
properties to be included.

=cut

sub kebab_case {
    my ($self, %row) = @_;
    my %new_row;
    foreach my $column (keys(%row)) {
        my $value = $row{$column};
        unless ($column =~ m/^_/) {
            $column =~ s/_/-/g;
        }
        $new_row{$column} = $value;
    }
    return %new_row;
}

1;
