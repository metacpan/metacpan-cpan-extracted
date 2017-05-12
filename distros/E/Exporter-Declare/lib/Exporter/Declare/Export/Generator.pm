package Exporter::Declare::Export::Generator;
use strict;
use warnings;

use base 'Exporter::Declare::Export::Sub';
use Exporter::Declare::Export::Variable;
use Carp qw/croak/;

sub required_specs {
    my $self = shift;
    return(
        $self->SUPER::required_specs(),
        qw/ type /,
    );
}

sub type { shift->_data->{ type }}

sub new {
    my $class = shift;
    croak "Generators must be coderefs, not " . ref($_[0])
        unless ref( $_[0] ) eq 'CODE';
    $class->SUPER::new( @_ );
}

sub generate {
    my $self = shift;
    my ( $import_class, @args ) = @_;
    my $ref = $self->( $self->exported_by, $import_class, @args );

    return Exporter::Declare::Export::Sub->new(
        $ref,
        %{ $self->_data },
    ) if $self->type eq 'sub';

    return Exporter::Declare::Export::Variable->new(
        $ref,
        %{ $self->_data },
    ) if $self->type eq 'variable';

    return $self->type->new(
        $ref,
        %{ $self->_data },
    );
}

sub inject {
    my $self = shift;
    my ( $class, $name, @args ) = @_;
    $self->generate( $class, @args )->inject( $class, $name );
}

1;

=head1 NAME

Exporter::Declare::Export::Generator - Export class for exports that should be
generated when imported.

=head1 DESCRIPTION

Export class for exports that should be generated when imported.

=head1 OVERRIDEN METHODS

=over 4

=item $class->new( $ref, $ref, exported_by => $package, type => $type, %data )

You must specify the type as 'sub' or 'variable'.

=item $export->inject( $package, $name, @args )

Calls generate() with @args to create a generated export. The new export is
then injected.

=back

=head1 ADDITIONAL METHODS

=over 4

=item $new = $export->generate( $import_class, @args )

Generates a new export object.

=item $type = $export->type()

Returns the type of object to be generated (sub or variable)

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
