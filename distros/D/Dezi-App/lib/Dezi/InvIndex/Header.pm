package Dezi::InvIndex::Header;
use Moose;
with 'Dezi::Role';
use Types::Standard qw( InstanceOf HashRef );
use Dezi::Types qw( DeziInvIndex );
use MooseX::Types::Path::Class;
use Carp;
use SWISH::3 qw( :constants );

use namespace::autoclean;

our $VERSION = '0.014';

has 'invindex' => ( is => 'rw', isa => DeziInvIndex, required => 1 );
has 'file' => ( is => 'ro', isa => 'Path::Class::File', coerce => 1, );
has 'data' => ( is => 'ro', isa => HashRef );
has 'swish3_config' => ( is => 'ro', isa => InstanceOf ['SWISH::3::Config'] );

# index metadata. read/write libswish3 file xml format.
#

sub header_file {
    return SWISH_HEADER_FILE();
}

# back compat
sub swish_header_file { shift->header_file }

sub BUILD {
    my $self = shift;
    $self->{file} = $self->invindex->path->file( $self->header_file );
    if ( !-s $self->{file} ) {
        confess("No such file: $self->{file}");
    }
    $self->{swish3_config} = SWISH::3::Config->read("$self->{file}");

    # unroll swish3_config into a local perl hash
    $self->_build_data();

    #warn Data::Dump::dump( $self->{data} );

    $self->_build_property_maps();

    #SWISH::3->dump( $self );
}

sub _build_data {
    my $self     = shift;
    my $s3config = $self->swish3_config;

    $self->{data} = {
        SWISH_PROP()    => $s3config->get_properties->_as_hash,
        SWISH_META()    => $s3config->get_metanames->_as_hash,
        SWISH_MIME()    => $s3config->get_mimes->_as_hash,
        SWISH_PARSERS() => $s3config->get_parsers->_as_hash,
        SWISH_INDEX()   => $s3config->get_index->_as_hash,
        SWISH_ALIAS()   => $s3config->get_aliases->_as_hash,
    };

    # add any leftovers
    my $misc = $s3config->get_misc();
    for my $key ( @{ $misc->keys } ) {
        next if exists $self->{data}->{$key};
        $self->{data}->{$key} = $misc->get($key);
    }

    #SWISH::3->dump($self);

}

sub _build_property_maps {
    my $self = shift;

    my $props      = $self->swish3_config->get_properties;
    my $prop_names = $props->keys;

    # start with the built-in PropertyNames,
    # which cannot be aliases for anything.
    my %propnames = map { $_ => { alias_for => undef } }
        keys %{ SWISH_DOC_PROP_MAP() };
    $propnames{swishrank} = { alias_for => undef };
    $propnames{score}     = { alias_for => undef };

    my @pure_props;
    my %prop_map;
    for my $name (@$prop_names) {
        my $property = $props->get($name);
        $propnames{$name} = { alias_for => undef };
        if ( defined $property->alias_for ) {
            $propnames{$name}->{alias_for} = $property->alias_for;
            $prop_map{$name} = $property->alias_for;
        }
        else {
            push @pure_props, $name;
        }
    }
    $self->{_propnames}  = \%propnames;
    $self->{_pure_props} = \@pure_props;
    $self->{_prop_map}   = \%prop_map;
}

sub get_properties {
    return shift->{_propnames};
}

sub get_property_map {
    return shift->{_prop_map};
}

sub get_pure_properties {
    return shift->{_pure_props};
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*://;
    return if $method eq 'DESTROY';

    if ( exists $self->{data}->{$method} ) {
        return $self->{data}->{$method};
    }
    confess "no such Header key: $method";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Dezi::InvIndex::Header - read/write InvIndex metadata

=head1 SYNOPSIS

 use Data::Dump qw( dump );
 use Dezi::InvIndex;
 my $index = Dezi::InvIndex->new(path => 'path/to/index');
 my $meta = $index->meta;  # isa Dezi::InvIndex::Header object
 for my $key (keys %{ $meta->data }) {
    dump $meta->$key;
 }
 
=head1 DESCRIPTION

A Dezi::InvIndex::Header object represents the metadata for an
InvIndex. It supports the Swish3 C<swish.xml> header file format only
at this time.

=head1 CONSTANTS

All the L<SWISH::3> constants are imported into this namespace,
including:

=head2 SWISH_DOC_PROP_MAP

=head1 METHODS

=head2 header_file

Class or object method. Returns the basename of the header file.
Default is C<swish.xml>.

=head2 swish_header_file

Alias for header_file(). For backwards compatability with SWISH::Prog.

=head2 BUILD

Read and initialize the header_file().

=head2 data

The contents of the header file as a Perl hashref. This is a read-only
accessor.

=head2 file

The full path to the header_file() file. This is a read-only accessor.

=head2 invindex

The Dezi::InvIndex object which the Dezi::InvIndex::Header
object represents.

=head2 get_properties

Returns hashref of PropertyNames with aliases resolved.

=head2 get_pure_properties

Returns arrayref of PropertyName values, excluding aliases.

=head2 get_property_map

Returns hashref of alias names to pure names.

=cut

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::InvIndex::Header

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 or later.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>
