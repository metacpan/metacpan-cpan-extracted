package Exporter::Declare::Export;
use strict;
use warnings;
use Carp qw/croak carp/;
use Scalar::Util qw/reftype/;

our %OBJECT_DATA;

sub required_specs {qw/ exported_by /}

sub new {
    my $class = shift;
    my ( $item, %specs ) = @_;
    my $self = bless( $item, $class );

    for my $prop ( $self->required_specs ) {
        croak "You must specify $prop when calling $class\->new()"
            unless $specs{$prop};
    }

    $OBJECT_DATA{$self} = \%specs;

    return $self;
}

sub _data {
    my $self = shift;
    ($OBJECT_DATA{$self}) = @_ if @_;
    $OBJECT_DATA{$self};
}

sub exported_by {
    shift->_data->{ exported_by };
}

sub inject {
    my $self = shift;
    my ( $class, $name, @args ) = @_;

    carp(
        "Ignoring arguments importing ("
        . reftype($self)
        . ")$name into $class: "
        . join( ', ', @args )
    ) if (@args);

    croak "You must provide a class and name to inject()"
        unless $class && $name;
    no strict 'refs';
    no warnings 'once';
    *{"$class\::$name"} = $self;
}

sub DESTROY {
    my $self = shift;
    delete $OBJECT_DATA{$self};
}

1;

=head1 NAME

Exporter::Declare::Export - Base class for all export objects.

=head1 DESCRIPTION

All exports are refs, and all are blessed. This class tracks some per-export
information via an inside-out objects system. All things an export may need to
do, such as inject itself into a package are handled here. This allows some
complicated, or ugly logic to be abstracted out of the exporter and metadata
classes.

=head1 METHODS

=over

=item $class->new( $ref, exported_by => $package, %data )

Create a new export from $ref. You must specify the name of the class doing the
exporting.

=item $export->inject( $package, $name, @args )

This will inject the export into $package under $name. @args are ignored in
most cases. See L<Exporter::Declare::Export::Generator> for an example where
they are used.

=item $package = $export->exported_by()

Returns the name of the package from which this export was originally exported.

=item @params = $export->required_specs()

Documented for subclassing purposes. This should always return a list of
required parameters at construction time.

=item $export->DESTROY()

Documented for subclassing purposes. This takes care of cleanup related to
storing data in an inside-out objects system.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Exporter-Declare is free software; Standard perl licence.

Exporter-Declare is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
