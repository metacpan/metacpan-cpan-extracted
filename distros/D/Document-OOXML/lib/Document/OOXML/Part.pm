use utf8;
package Document::OOXML::Part;
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Role for OOXML document parts


requires 'to_string';

has part_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,  
);

has document => (
    is       => 'rw',
    isa      => 'Document::OOXML::Document',
    weak_ref => 1,
);

sub get_relations_part {
    my $self = shift;
    my $type = shift;
    my $id   = shift;

    my $rels = $self->document->get_rels_for_part($self->part_name);

    return $rels;
}

sub find_referenced_part_by_id {
    my $self = shift;
    my $id   = shift;

    my $rels = $self->get_relations_part;
    my $data = $rels->get_part_relation_by_id($id);

    return $self->document->get_part($data->{part_name});
}

sub find_referenced_part_by_type {
    my $self = shift;
    my $type = shift;

    my $rels = $self->get_relations_part;
    my $data = $rels->get_part_relation_by_type($type);

    return $self->document->get_part($data->{part_name});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML::Part - Role for OOXML document parts

=head1 VERSION

version 0.180750

=head1 SYNOPSIS

    package Document::OOXML::Part::SomePart;
    use Moose;
    with 'Document::OOXML::Part';

    # used to save the part back to a file
    sub to_string { }

=head1 SEE ALSO

=over

=item * L<Document::OOXML>

=back

=head1 AUTHOR

Martijn van de Streek <martijn@vandestreek.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Martijn van de Streek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
