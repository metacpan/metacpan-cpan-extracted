package File::ArchivableFormats::Plugin;
our $VERSION = '1.8';
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Role which implements logic for all plugins

requires '_build_preferred_formats';

has preferred_formats => (
    is        => 'ro',
    isa       => 'HashRef',
    traits    => ['Hash'],
    lazy      => 1,
    builder   => '_build_preferred_formats',
    handles   => {
        is_archivable => 'defined',
        get_info      => 'get',

    }
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _not_allowed {
    my $self = shift;
    return { types => [], allowed_extensions => [] };
}

sub allowed_extensions {
    my ($self, $mimetype) = @_;

    if ($self->is_archivable($mimetype)) {
        return $self->get_info($mimetype);
    }

    return $self->_not_allowed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ArchivableFormats::Plugin - Role which implements logic for all plugins

=head1 VERSION

version 1.8

=head1 ATTRIBUTES

=head2 preferred_formats

The list of preferred formats. Implements F <is_archivable> and F <get_info>

=head2 name

The (short) name of the plugin

=head1 METHODS

=head2 _build_preferred_formats

Consumers of this role must implement this function to build the
C<preferred_formats> attribute.

=head2 allowed_extensions

Tells you if an extension is allowed, Returns an HashRef with data.

    {
        types => [
            # Tells you something about the filetype
        ],
        allowed_extensions => [
            # Tells you which extensions are allowed for the mimetype in
            # the preferred formats list
        ],
    }

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mintlab BV.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
