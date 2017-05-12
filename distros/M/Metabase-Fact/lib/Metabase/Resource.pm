use 5.006;
use strict;
use warnings;

package Metabase::Resource;

our $VERSION = '0.025';

use Carp ();

#--------------------------------------------------------------------------#
# main API methods -- shouldn't be overridden
#--------------------------------------------------------------------------#

use overload (
    '""'     => sub { $_[0]->resource },
    '=='     => sub { _obj_eq(@_) },
    '!='     => sub { !_obj_eq(@_) },
    fallback => 1,
);

# Check if two objects are the same object
sub _obj_eq {
    return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
}

my $id_re    = qr/[_a-z]+/i;
my $class_re = qr/^$id_re(?:::$id_re)*$/;

sub _load {
    my ( $class, $subclass ) = @_;
    unless ( $subclass =~ $class_re ) {
        Carp::confess "'$subclass' does not look like a class name";
    }
    eval "require $subclass; 1" ## no critic
      or Carp::confess("Could not load '$subclass': $@");
}

my %installed;

sub _add {
    my ( $self, $name, $value ) = @_;
    $self->{metadata}{$name} = $value;
    my $method = ref($self) . "::$name";
    if ( !$installed{$method} ) {
        no strict 'refs';       ## no critic
        *{$method} = sub { return $_[0]->{metadata}{$name} };
        $installed{$method}++;
    }
    return;
}

sub _type {
    my ($self) = @_;
    my $class = ref $self || $self;
    $class =~ s{::}{-}g;
    return $class;
}

sub new {
    my ( $class, $resource ) = @_;
    Carp::confess("no resource string provided")
      unless defined $resource && length $resource;

    if ( ref $resource && eval { $resource->isa('Metabase::Resource') } ) {
        $resource = $resource->resource;
    }

    # parse scheme
    my ($scheme) = $resource =~ m{\A([^:]+):};
    Carp::confess("could not determine URI scheme from '$resource'\n")
      unless defined $scheme && length $scheme;

    my $schema_class = "Metabase::Resource::$scheme";
    $class->_load($schema_class);
    my $type_class = $schema_class->_extract_type($resource);
    $class->_load($type_class);

    # construct object
    my $self = bless {
        resource => $resource,
        metadata => {},
    }, $type_class;
    if ( $self->can('_init') ) {
        $self->_init;
    }

    $self->_add( type => $self->_type );
    $self->validate;
    return $self;
}

# Don't cause segfault with perl-5.6.1 by
# overloading undef stuff...
sub resource {
    return '' unless ref $_[0] && defined $_[0]->{resource};
    return "$_[0]->{resource}";
}

# return a copy
sub metadata {
    my ($self) = @_;
    return { %{ $self->{metadata} || {} } };
}

sub metadata_types {
    my ($self) = @_;
    return {
        'type' => '//str',
        %{ $self->_metadata_types || {} }
    };
}

#--------------------------------------------------------------------------#
# abstract methods -- fatal
#--------------------------------------------------------------------------#

sub validate {
    my ($self) = @_;
    Carp::confess "validate not implemented by " . ( ref $self || $self );
}

1;

# ABSTRACT: factory class for Metabase resource descriptors

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Resource - factory class for Metabase resource descriptors

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $resource = Metabase::Resource->new(
    'cpan:///distfile/RJBS/Metabase-Fact-0.001.tar.gz',
  );

  my $resource_meta = $resource->metadata;
  my $typemap       = $resource->metadata_types;

=head1 DESCRIPTION

L<Metabase> is a framework for associating metadata with arbitrary resources.
A Metabase can be used to store test reports, reviews, coverage analysis
reports, reports on static analysis of coding style, or anything else for which
L<Metabase::Fact> types are constructed.

Resources in Metabase are URI's that consist of a scheme and scheme
specific information.  For example, a standard URI framework for a
CPAN distribution is defined by the L<URI::cpan> class.

  cpan:///distfile/RJBS/URI-cpan-1.000.tar.gz

Metabase::Resource is a factory class for resource descriptors. It provide
a common interface to extract scheme-specific indexing metadata from a
scheme-specific resource subclass.

For example, the L<Metabase::Resource::cpan> class will deconstruct the example
above this into a Metabase resource metadata structure with the following
elements:

  type         => Metabase-Resource-cpan-distfile
  dist_file    => RJBS/URI-cpan-1.000.tar.gz
  cpan_id      => RJBS
  dist_name    => URI-cpan
  dist_version => 1.000

Only the C<type> field is mandatory for all resources.  The other fields are
all specific to Metabase::Resource::cpan.

=head1 COMMON METHODS

=head2 new

  my $resource = Metabase::Resource->new(
    'cpan:///distfile/RJBS/Metabase-Fact-0.001.tar.gz',
  );

Takes a single resource string argument and constructs a new Resource object
from a resource subtype determined by the URI scheme.  Throws an error if the
required resource subclass is not available.

=head2 resource

Returns the string used to initialize the resource object.

=head2 scheme

Returns a string containing the scheme.

=head2 _cache (private)

Returns a hash reference for subclasses to use to store data derived from
the C<content> string.

=head1 OVERLOADING

Resources have stringification overloaded to call C<content>.  Equality
(==) and inequality (!=) are overloaded to perform string comparison instead.

=head1 SUBCLASSING AND SUBCLASS METHODS

Metabase::Resource relies on subclasses to implement scheme-specific parsing
of the URI into relevant index metadata.

Subclasses SHOULD NOT implement a C<new> constructor, as the Metabase::Resource
constructor will load the subclass, construct the object, bless the object
into the subclass, and then call C<validate> on the object.  Subclasses
MAY store structured data derived from the content string during validation.

Subclasses SHOULD use the C<content> method to access the resource string and
the C<scheme> method to access the scheme.  Subclasses MAY use the C<_cache>
accessor to store derived metadata data. Subclasses MUST provide a
C<metadata_types> method to return data types for all elements stored
in C<_cache>.

All subclasses MUST implement the C<validate>, C<metadata> and
C<metadata_types> methods, as described below.

All methods MUST throw an exception if an error occurs.

=head2 validate

  $resource->validate

This method is called by the constructor.  It SHOULD return true if the
resource string is valid according to scheme-specific rules.  It MUST die if
the resource string is invalid.

=head2 metadata

  $meta = $resource->metadata;

This method MUST return a hash reference with resource-specific indexing
metadata for the Resource.  The key MUST be the name of the field for indexing.
The C<scheme> key MUST be present and the C<scheme> value MUST be identical to
the string from the C<scheme> accessor.  Other keys SHOULD provide dimensions
to differentiate one resource from another in the context of C<scheme>.  If a
scheme has subcategories, the key C<type> SHOULD be used for the subcategory.
Values MUST be simple scalars, not references.

Here is a hypothetical example of a C<metadata> function for a metabase user
resource like 'metabase:user:ec2726a4-070c-11df-a2e0-0018f34ec37c':

  sub metadata {
    my $self = shift;
    my ($uuid) = $self =~ m{\Ametabase:user:(.+)\z};
    return {
      scheme  => 'metabase',
      type    => 'user',
      user    => $uuid,
    }
  }

Field names should be valid perl identifiers, consisting of alphanumeric
characters or underscores.  Hyphens and periods are allowed, but are not
recommended.

=head2 metadata_types

  my $typemap = $resource->metadata_types;

This method is used to identify the datatypes of keys in the data structure
provided by C<metadata>.  It MUST return a hash reference.  It SHOULD contain
a key for every key that could appear in the data structure generated
by C<metadata> and provide a value corresponding to a datatype for each
key.  It MAY contain keys that do not always appear in the result of
C<metadata>.

Data types are loosely based on L<Data::RX>.  Type SHOULD be one of the
following:

  '//str' -- indicates a value that should be compared stringwise
  '//num' -- indicates a value that should be compared numerically

Here is a hypothetical example of a C<metadata_types> function for a metabase
user resource like 'metabase:user:ec2726a4-070c-11df-a2e0-0018f34ec37c':

  sub metadata_types {
    return {
      scheme  => '//str',
      type    => '//str',
      user    => '//str',
    }
  }

Consumers of C<metadata_types> SHOULD assume that any C<metadata> key not
found in the result of C<metadata_types> is a '//str' resource.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

H.Merijn Brand <hmbrand@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
