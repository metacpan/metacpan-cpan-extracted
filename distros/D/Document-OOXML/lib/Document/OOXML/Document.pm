use utf8;
package Document::OOXML::Document;
use Moose;
use namespace::autoclean;

# ABSTRACT: Base class for the different OOXML document types

use Moose::Util::TypeConstraints qw(role_type);
use Path::Tiny;


has filename => (
    is  => 'ro',
    isa => 'Str',
);

has source => (
    is       => 'ro',
    isa      => 'Archive::Zip',
    required => 1,
);

has is_strict => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has rels => (
    is      => 'ro',
    isa     => 'HashRef[Document::OOXML::Rels]',
    default => sub { {} },
);

has document_part => (
    is      => 'rw',
    isa     => role_type('Document::OOXML::Part'),
    writer  => 'set_document_part',
);

has loaded_parts => (
    is      => 'ro',
    isa     => 'HashRef[Document::OOXML::Part]',
    default => sub { {} },
);

has content_types => (
    is       => 'ro',
    isa      => 'Document::OOXML::ContentTypes',
    required => 1,
);


sub get_part {
    my $self = shift;
    my $part_name = shift;

    return $self->loaded_parts->{$part_name}
        if exists $self->loaded_parts->{$part_name};

    my $content_type = $self->content_types->get_content_type_for_part($part_name);

    my $part_contents = $self->source->contents($part_name)
        or croak("No member named '$part_name' in document.");

    my $part = Document::OOXML::PartParser->parse_part(
        content_type  => $content_type,
        contents      => $part_contents,
        part_name     => $part_name,
        is_strict     => $self->is_strict,
    );

    $part->document($self);
    $self->loaded_parts->{$part_name} = $part;

    return $part;
}


sub get_rels_for_part {
    my $self = shift;
    my $part_name = shift;

    my $path = path($part_name);

    my $dir = $path->parent->stringify;
    my $filename = $path->basename;
    my $rels_file = path($dir, "_rels", "${filename}.rels");

    return $self->rels->{$part_name} if exists $self->rels->{$part_name};

    my $rels_data = $self->source->contents($rels_file->stringify)
        or return; # No relations

    $self->rels->{$part_name} = Document::OOXML::Rels->new_from_xml($rels_data, $dir);

    return $self->rels->{$part_name};
}


sub save_to_file {
    my $self = shift;
    my $filename = shift;

    my $output = Archive::Zip->new();

    for my $member ( $self->source->members() ) {
        if ($member->fileName eq $self->document_part->part_name) {
            $output->addString(
                $self->document_part->to_string(),
                $self->document_part->part_name,
            );
        } elsif (exists $self->loaded_parts->{$member->fileName}) {
            # This is how members will be marked for deletion internally:
            next if not defined $self->loaded_parts->{$member->fileName};

            my $part = $self->loaded_parts->{$member->fileName};
            $output->addString(
                $part->to_string(),
                $part->part_name,
            );
        } else {
            # File not changed by us. Copy verbatim.
            $output->addMember($member);
        }
    }

    $output->writeToFileNamed($filename);

    return;
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML::Document - Base class for the different OOXML document types

=head1 VERSION

version 0.181410

=head1 SYNOPSIS

    package Document::OOXML::Document::SomeType;
    use Moose;
    extends 'Document::OOXML::Document';

    # implement document-type specifics here

=head1 METHODS

=head2 get_part($part_name)

Retrieve a (related) document part by name.

=head2 get_rels_for_part($part_name)

Retrieve a L<Document::OOXML::Rels> object representing the ".rels" file for
the specified part of the document.

C<.rels> files contain a mapping of filenames/types to 

=head2 save_to_file($filename)

Saves the document to file named C<$filename>.

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
