use 5.006;
use strict;
use warnings;

package Metabase::Fact;

our $VERSION = '0.025';

use Carp ();
use Data::GUID guid_string => { -as => '_guid' };
use JSON::MaybeXS ();
use Metabase::Resource;

#--------------------------------------------------------------------------#
# main API methods -- shouldn't be overridden
#--------------------------------------------------------------------------#

# We originally used Params::Validate, but only for
# required/optional/disallowed, and it was Yet Another Prereq for what
# needed to be a very small set of libraries.  Sadly, we've rolled our
# own... -- rjbs, 2009-03-30
sub __validate_args {
    my ( $self, $args, $spec ) = @_;
    my $hash =
        ( @$args == 1 and ref $args->[0] ) ? { %{ $args->[0] } }
      : ( @$args == 0 ) ? {}
      :                   {@$args};

    my @errors;

    for my $key ( keys %$hash ) {
        push @errors, qq{unknown argument "$key" when constructing $self}
          unless exists $spec->{$key};
    }

    for my $key ( grep { $spec->{$_} } keys %$spec ) {
        push @errors, qq{missing required argument "$key" when constructing $self}
          unless defined $hash->{$key};
    }

    Carp::confess( join qq{\n}, @errors ) if @errors;

    return $hash;
}

my $hex     = '[0-9a-f]';
my $guid_re = qr(\A$hex{8}-$hex{4}-$hex{4}-$hex{4}-$hex{12}\z)i;

sub __validate_guid {
    my ( $class, $string ) = @_;
    if ( $string !~ $guid_re ) {
        Carp::confess("'$string' is not formatted as a GUID string");
    }
    return lc $string;
}

sub validate_resource {
    my ( $self, $uri ) = @_;
    # Metabase::Resource->new dies if invalid
    my $obj = Metabase::Resource->new($uri);
    if ( !( ref($obj) && $obj->isa("Metabase::Resource") ) ) {
        Carp::confess("Could not validate '$uri' as a Metabase::Resource");
    }
    return $obj;
}

sub new {
    my ( $class, @args ) = @_;
    my $args = $class->__validate_args(
        \@args,
        {
            content  => 1,
            resource => 1, # where to validate? -- dagolden, 2009-03-31
            # still optional so we can manipulate anon facts -- dagolden, 2009-05-12
            creator => 0,
            # helpful for constructing facts with non-random guids
            guid => 0,
        },
    );

    # create the object
    my $self = $class->_init_guts($args);

    # validate content
    eval { $self->validate_content };
    if ($@) {
        Carp::confess("$class object content invalid: $@");
    }

    return $self;
}

sub _zulu_datetime {
    my ( $y, $mo, $d, $h, $mi, $s ) = (gmtime)[ reverse 0 .. 5 ];
    return
      sprintf( "%4d-%02d-%02dT%02d:%02d:%02dZ", 1900 + $y, 1 + $mo, $d, $h, $mi, $s );
}

sub _bool { return $_[0] ? 1 : 0 }

# used for both new() and from_struct() -- in the former case
# only content, resource, guid and creator could exist; in
# the latter case, all fields would exist
sub _init_guts {
    my ( $class, $args ) = @_;

    # confirm type
    $args->{type} = $class->type
      unless defined $args->{type};

    Carp::confess("illegal type ($args->{type}) for $class")
      if $args->{type} ne $class->type;

    # if restoring from_struct, we must cope with older schemas
    $args->{schema_version} = $class->default_schema_version
      unless defined $args->{schema_version};

    $class->upgrade_fact($args)
      if $args->{schema_version} != $class->default_schema_version;

    # initialize guid if not provided
    if ( !defined $args->{guid} ) {
        $args->{guid} = lc _guid();
    }

    # initialize the object
    my $self = bless {}, $class;

    $self->{content} = $args->{content};

    my $meta = $self->{metadata} = { core => {} };
    $meta->{core}{guid}           = $class->__validate_guid( $args->{guid} );
    $meta->{core}{creation_time}  = $args->{creation_time} || _zulu_datetime();
    $meta->{core}{update_time}    = $meta->{core}{creation_time};
    $meta->{core}{schema_version} = $args->{schema_version};
    $meta->{core}{type}           = $self->type;
    $meta->{core}{valid}          = _bool( defined $args->{valid} ? $args->{valid} : 1 );

    # validate creator via mutator if given
    $self->set_creator( $args->{creator} ) if defined $args->{creator};

    # validate resource field
    $meta->{core}{resource} = $self->validate_resource( $args->{resource} );

    return $self;
}

# Content accessor
sub content { $_[0]->{content} }

# Accessors for core metadata

sub creation_time  { $_[0]->{metadata}{core}{creation_time} }
sub guid           { $_[0]->{metadata}{core}{guid} }
sub resource       { $_[0]->{metadata}{core}{resource} }
sub schema_version { $_[0]->{metadata}{core}{schema_version} }

# Creator can be set once after the fact is created

sub creator { $_[0]->{metadata}{core}{creator} }

sub set_creator {
    my ( $self, $uri ) = @_;

    Carp::confess("can't set creator; it is already set")
      if $self->creator;

    # validate $uri
    my $obj = Metabase::Resource->new($uri);
    unless ( $obj->type eq 'Metabase-Resource-metabase-user' ) {
        Carp::confess( "creator must be a Metabase User Profile resource URI of\n"
              . "the form 'metabase:user:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'" );
    }

    $self->{metadata}{core}{creator} = $obj;
}

# update_time can always be modified

sub update_time { $_[0]->{metadata}{core}{update_time} }

sub touch {
    my ($self) = @_;
    $self->{metadata}{core}{update_time} = _zulu_datetime();
}

# valid can be modified

sub valid { $_[0]->{metadata}{core}{valid} }

sub set_valid {
    my ( $self, $val ) = @_;
    $self->{metadata}{core}{valid} = _bool($val);
}

# metadata structure accessors

sub core_metadata {
    my $self = shift;
    return { %{ $self->{metadata}{core} } };
}

sub core_metadata_types {
    return {
        creation_time  => '//str',
        creator        => '//str',
        guid           => '//str',
        resource       => '//str',
        schema_version => '//num',
        type           => '//str',
        update_time    => '//str',
        valid          => '//bool',
    };
}

sub resource_metadata {
    my $self = shift;
    $self->{metadata}{resource} ||= $self->resource->metadata;
    return { %{ $self->{metadata}{resource} } };
}

sub resource_metadata_types {
    my $self = shift;
    return $self->resource->metadata_types;
}

# persistence routines

# Class might not be in its own file -- check if method can resolve
# or else try to load it
my $id_re    = qr/[_a-z]+/i;
my $class_re = qr/^$id_re(?:::$id_re)*$/;

sub _load_fact_class {
    my ( $class, $fact_class ) = @_;
    unless ( defined $fact_class ) {
        Carp::confess "Can't load undef as a module";
    }
    unless ( $fact_class =~ $class_re ) {
        Carp::confess "'$fact_class' does not look like a class name";
    }
    unless ( $fact_class->can('type') ) {
        eval "require $fact_class; 1" ## no critic
          or Carp::confess "Could not load fact class $fact_class\: $@";
    }
    return 1;
}

sub as_struct {
    my ($self) = @_;

    # turn Metabase::Resources back into URI strings
    my $core = { %{ $self->core_metadata } };
    $core->{resource} = $core->{resource}->resource;
    $core->{creator} = $core->{creator}->resource if exists $core->{creator};

    return {
        content  => $self->content_as_bytes,
        metadata => {
            # We only provide core metadata here, not resource or content metadata,
            # because we use as_struct for serialized transmission.  The remote that
            # receives the transmission should reconstruct the metadata for itself,
            # as it is more likely to have an improved metadata producer. -- rjbs,
            # 2009-06-24
            core => $core,
        }
    };
}

sub from_struct {
    my ( $class, $struct ) = @_;

    # Might be called as Metabase::Fact->from_struct($struct), so we
    # need to find and load the actual fact class
    my $fact_class = $class->class_from_type( $struct->{metadata}{core}{type} );
    $class->_load_fact_class($fact_class);

    my $metadata  = $struct->{metadata};
    my $core_meta = $metadata->{core};

    # transform struct into content and core metadata arguments the way they
    # would be given to new, then validate these and get an object from
    # _init_guts
    my @args = (
        ( map { $_ => $core_meta->{$_} } keys %$core_meta ),
        content => $fact_class->content_from_bytes( $struct->{content} ),
    );

    my $args = $fact_class->__validate_args(
        \@args,
        {
            # when thawing, all of these must be provided
            content        => 1,
            creation_time  => 1,
            guid           => 1,
            resource       => 1,
            schema_version => 1,
            type           => 1,
            valid          => 1,
            # still optional so we can manipulate anon facts -- dagolden, 2009-05-12
            creator     => 0,
            update_time => 0,
        },
    );

    my $self = $fact_class->_init_guts($args);

    return $self;
}

sub as_json {
    my ($self) = @_;
    return JSON::MaybeXS->new(ascii => 1)->encode( $self->as_struct );
}

sub from_json {
    my ( $class, $string ) = @_;
    my $struct = eval { JSON::MaybeXS->new(ascii => 1)->decode($string) }
      or Carp::confess "Error decoding JSON:\n$@";
    return $class->from_struct($struct);
}

sub save {
    my ( $self, $filename ) = @_;
    my $class = ref($self);
    open my $fh, ">", $filename
      or Carp::confess "Error saving $class to '$filename'\: $!";
    print {$fh} scalar $self->as_json;
    close $fh;
    return 1;
}

sub load {
    my ( $class, $filename ) = @_;
    open my $fh, "<", $filename
      or Carp::confess "Error loading fact from '$filename'\: $!";
    my $string = do { local $/; <$fh> };
    close $fh;
    return $class->from_json($string);
}

#--------------------------------------------------------------------------#
# utilities for all facts to do class/type conversions
#--------------------------------------------------------------------------#

# type_from_class
sub type {
    my $self = shift;
    my $type = ref $self || $self;

    $type =~ s{::}{-}g;
    return $type;
}

# XXX: I'm not really excited about having this in here. -- rjbs, 2009-03-28
# XXX: Need it ->type for symmetry.  Make it private? -- dagolden, 2009-03-31
sub class_from_type {
    my ( undef, $type ) = @_;
    Carp::confess "can't get class from undef type" unless defined $type;
    $type =~ s/-/::/g;
    return $type;
}

#--------------------------------------------------------------------------#
# class methods
#--------------------------------------------------------------------------#

# schema_version recorded in 'version' attribution during ->new
# if format of content changes, class module should increment schema version
# to check: if ( $obj->version != $class->schema_version ) ...

# XXX should this be a fatal abstract?  Forcing classes to be
# explicit about schema versions? Annoying, but correct -- dagolden, 2009-03-31
sub default_schema_version { 1 }

#--------------------------------------------------------------------------#
# abstract methods -- mostly fatal
#--------------------------------------------------------------------------#

sub content_metadata { return +{} }

sub content_metadata_types { return +{} }

sub upgrade_fact {
    my ($self) = @_;
    Carp::confess "Detected a schema mismatch, but upgrade_fact not implemented by "
      . ( ref $self || $self );
}

sub content_as_bytes {
    my ( $self, $content ) = @_;
    Carp::confess "content_as_bytes not implemented by " . ( ref $self || $self );
}

sub content_from_bytes {
    my ( $self, $bytes ) = @_;
    Carp::confess "content_from_bytes not implemented by " . ( ref $self || $self );
}

sub validate_content {
    my ( $self, $content ) = @_;
    Carp::confess "validate_content not implemented by " . ( ref $self || $self );
}

1;

# ABSTRACT: base class for Metabase Facts

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Fact - base class for Metabase Facts

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  # defining the fact class
  package MyFact;
  use Metabase::Fact::Hash;
  our @ISA = qw/Metabase::Fact::Hash/;

  # using the fact class
  my $fact = TestReport->new(
    resource   => 'RJBS/Metabase-Fact-0.001.tar.gz',
    content    => {
      status => 'FAIL',
      time   => 3029,
    },
  );

  $client->send_fact($fact);

=head1 DESCRIPTION

L<Metabase> is a framework for associating content and metadata with arbitrary
resources.  A Metabase can be used to store test reports, reviews, coverage
analysis reports, reports on static analysis of coding style, or anything else
for which datatypes are constructed.

Metabase::Fact is a base class for Facts (really opinions or analyses)
that can be sent to or retrieved from a Metabase repository.

=head2 Structure of a Fact object

A Fact object associates a C<content> attribute with a C<resource> attribute
and a C<creator> attribute.

The C<resource> attribute must be in a URI format that can be validated via a
L<Metabase::Resource> subclass.  The C<content> attribute is an opaque scalar
with subclass-specific meaning.  The C<creator> attribute is a URI with a
"metabase:user" scheme and type (see L<Metabase::Resource::metabase>).

Facts have three sets of metadata associate with them.  Metadata are generally
for use in indexing, searching and managing Facts.

=over

=item *

C<core metadata> describe universal properties of all Facts and are used
to submit, store, manage and retrieve Facts within the Metabase framework.

=item *

C<resource metadata> describe index properties derived from the C<resource>
attribute.  (As these can be regenerated from the C<resource> -- which is part
of C<core metadata> -- they are not stored with a serialized Fact.)

=item *

C<content metadata> describe index properties derived from the C<content>
attribute.  (As these can be regenerated from the C<content> -- which is part
of C<core metadata> -- they are not stored with a serialized Fact.)

=back

Each of the three metadata sets has an associated accessor: C<core_metadata>,
C<resource_metadata> and C<content_metadata>.

Each of the three sets also has an accessor that returns a hashref with a data
type for each possible element in the set: C<core_metadata_types>,
C<resource_metadata_types> and C<content_metadata_types>.

Data types are loosely based on L<Data::RX>.  For example:

  '//str'  -- indicates a value that should be compared stringwise
  '//num'  -- indicates a value that should be compared numerically
  '//bool' -- indicates a valut that is true or false

When searching on metadata, you must join the set name to the metadata
element name with a period character.  For example:

  core.guid
  core.creator
  core.resource
  resource.scheme
  content.size
  content.score

=head1 ATTRIBUTES

Unless otherwise noted, all attributes are read-only and are either provided as
arguments to the constructor or are generated during construction.  All
attributes (except C<content>) are also part of C<core metadata>.

=head2 Arguments provided to new

=head3 content (required)

A reference to the actual information associated with the fact.
The exact form of the content is up to each Fact class to determine.

=head3 resource (required)

The canonical resource (URI) the Fact relates to.  For CPAN distributions, this
would be a C<cpan:///distfile/...> URI.  (See L<URI::cpan>.)  The associated
accessor returns a Metabase::Resource subclass.

=head3 creator (optional)

A L<Metabase::User::Profile> URI that indicates the creator of the Fact.  If
not set during Fact creation, it will be set by the Metabase when a Fact is
submitted based on the submitter Profile.  The C<set_creator> mutator may be
called to set C<creator>, but only if it is not previously set.  The associated
accessor returns a Metabase::Resource subclass or C<undef> if the creator
has not been set.

=head3 guid (optional)

The Fact object's Globally Unique IDentifier.  This is generated automatically
if not provided.  Generally, users should not provide a C<guid> argument, but
it is permitted for use in special cases where a non-random C<guid> is necessary.

=head2 Generated during construction

These attributes are generated automatically during the call to C<new>.

=head3 type

The class name, with double-colons converted to dashes to be more
URI-friendly.  e.g.  C<Metabase::Fact> would be C<Metabase-Fact>.

=head3 schema_version

The C<schema_version> of the Fact subclass that created the object. This may or
may not be the same as the current C<schema_version> of the class if newer
versions of the class have been released since the object was created.

=head3 creation_time

Fact creation time in UTC expressed in extended ISO 8601 format with a
"Z" (Zulu) suffix.  For example:

  2010-01-10T12:34:56Z

=head3 update_time

When the fact was created, stored or otherwise updated, expressed an ISO 8601
UTC format as with C<creation_time>.  The C<touch> method may be called
at any time to update the value to the current time.  This attribute generally
only has local significance within a particular Metabase repository. For
example, it may be used to sort Facts by when they were stored or changed in a
Metabase.

=head3 valid

A boolean value indicating whether the fact is considered valid.  It defaults
to true.  The C<set_valid> method may be called to change the C<valid>
property, for example, to mark a fact invalid rather than deleting it.  The
value of C<valid> is always normalized to return "1" for true and "0" for false.

=head1 CONSTRUCTOR

=head2 new

  $fact = MyFact->new(
    resource => 'AUTHORID/Foo-Bar-1.23.tar.gz',
    content => $content_structure,
  );

Constructs a new Fact. The C<resource> and C<content> attributes are required.
No other attributes should be provided to C<new> except C<creator>.

=head1 CLASS METHODS

=head2 type

  $type = MyFact->type;

The C<type> accessor may also be called as a class method.

=head2 class_from_type

  $class = MyFact->class_from_type( $type );

A utility function to invert the operation of the C<type> method.

=head2 upgrade_fact

  MyFact->upgrade_fact( $struct );

This method will be called when initializing a fact from a data structure that
claims to be of a schema version other than the schema version reported by the
loaded class's C<default_schema_version> method.  It will be passed the hashref
of args being used to initialized the fact object (generally the output of
C<as_struct> from an older version), and should alter that hash in place.

=head2 default_schema_version

  $version = MyFact->default_schema_version;

Defaults to 1.  Subclasses should override this method if they make a
backwards-incompatible change to the internals of the content attribute.
Schema version numbers should be monotonically-increasing integers.  The
default schema version is used to set an objects schema_version attribution
on creation.

=head1 PERSISTENCE METHODS

The following methods are implemented by Metabase::Fact and subclasses
generally should not need to override them.

=head2 save

  $fact->save($filename);

This method writes out the fact to a file in JSON format.  If the file cannot
be written, an exception is raised.  If the save is successful, a true value is
returned.  Internally, it calls C<as_json>.

=head2 load

  my $fact = Metabase::Fact->load($filename);

This method loads a fact from a JSON format file and returns it.  If the
file cannot be read or is not valid JSON, and exception is thrown.
Internally, it calls C<from_json>.

=head2 as_json

This returns a JSON string containing the serialized object.  Internally, it
calls C<as_struct>.

=head2 from_json

This method regenerates a fact from a JSON string generated by
C<as_json>.  Internally, it calls C<from_struct>.

=head2 as_struct

This returns a simple data structure that represents the fact and can be used
for transmission over the wire.  It serializes the content and core metadata,
but not other metadata, which should be recomputed by the receiving end.

=head2 from_struct

  my $fact = Metabase::Fact->from_struct( $struct );

This takes the output of the C<as_struct> method and reconstitutes a Fact
object.  If the class the struct represents is not loaded, C<from_struct>
will attempt to load the class or will throw an error.

=head1 OBJECT METHODS

The following methods are implemented by Metabase::Fact and subclasses
generally should not need to override them.

=head2 core_metadata

This returns a hashref containing the fact's core metadata.  This includes
things like the guid, creation time, described resource, and so on.

=head2 core_metadata_types

This returns a hashref of types for each core metadata element

=head2 resource_metadata

This method returns metadata describing the resource.

=head2 resource_metadata_types

This returns a hashref of types for each resource metadata element

=head2 set_creator

  $fact->set_creator($profile_uri);

This method sets the C<creator> core metadata for the core metadata for the
fact.  If the fact's C<creator> is already set, an exception will be thrown.

=head2 set_valid

  $fact->set_valid(0);

This method sets the C<valid> core metadata to a boolean value.

=head2 touch

  $fact->touch

This method sets the C<update_time> core metadata for the core metadata for the
fact to the current time in ISO 8601 UTC format with a trailing "Z" (Zulu)
suffice.

=head1 ABSTRACT METHODS

Methods marked as F<required> must be implemented by a Fact subclass.  (The
version in Metabase::Fact will die with an error if called.)

In the documentation below, the terms F<must>, F<must not>, F<should>, etc.
have their usual RFC 2119 meanings.

These methods MUST throw an exception if an error occurs.

=head2 content_as_bytes

B<required>

  $string = $fact->content_as_bytes;

This method MUST serialize a Fact's content as bytes in a scalar and return it.
The method for serialization is up to the individual fact class to determine.
Some common subclasses are available to handle serialization for common data
types.  See L<Metabase::Fact::Hash> and L<Metabase::Fact::String>.

=head2 content_from_bytes

B<required>

  $content = $fact->content_from_bytes( $string );
  $content = $fact->content_from_bytes( \$string );

Given a scalar, this method MUST regenerate and return the original content
data structure.  It MUST accept either a string or string reference as an
argument.  It MUST NOT overwrite the Fact's content attribute directly.

=head2 content_metadata

B<optional>

  $content_meta = $fact->content_metadata;

If provided, this method MUST return a hash reference with content-specific
indexing metadata. The key MUST be the name of the field for indexing and
SHOULD provide dimensions to differentiate one set of content from another.
Values MUST be simple scalars, not references.

Here is a hypothetical example of C<content_metadata> for an image fact:

  sub content_metadata {
    my $self = shift;
    return {
      width   => _compute_width  ( $self->content ),
      height  => _compute_height ( $self->content ),
      caption => _extract_caption( $self->content ),
    }
  }

Field names should be valid perl identifiers, consisting of alphanumeric
characters or underscores.  Hyphens and periods are allowed, but are not
recommended.

=head2 content_metadata_types

B<optional>

  my $typemap = $fact->content_metadata_types;

This method is used to identify the datatypes of keys in the data structure
provided by C<content_metadata>.  If provided, it MUST return a hash reference.
It SHOULD contain a key for every key that could appear in the data structure
generated by C<content_metadata> and provide a value corresponding to a
datatype for each key.  It MAY contain keys that do not always appear in the
result of C<content_metadata>.

Data types are loosely based on L<Data::RX>.  Type SHOULD be one of the
following:

  '//str' -- indicates a value that should be compared stringwise
  '//num' -- indicates a value that should be compared numerically
  '//bool' -- indicates a boolean value where "1" is true and "0" is false

Here is a hypothetical example of C<content_metadata_types> for an image fact:

  sub content_metadata_types {
    return {
      width   => '//num',
      height  => '//num',
      caption => '//str',
    }
  }

Consumers of C<content_metadata_types> SHOULD assume that any
C<content_metadata> key not found in the result of C<content_metadata_types> is
a '//str' resource.

=head2 validate_content

B<required>

 eval { $fact->validate_content };

This method SHOULD check for the validity of content within the Fact.  It
MUST throw an exception if the fact content is invalid.  (The return value is
ignored.)

=head2 validate_resource

B<optional>

 eval { $fact->validate_resource };

This method SHOULD check whether the resource type is relevant for the Fact
subclass.  It SHOULD use L<Metabase::Resource> to create a resource object and
evaluate the resource object scheme and type.  It MUST throw an exception if
the resource type is invalid.  Otherwise, it MUST return a valid
Metabase::Resource subclass.  For example:

  sub validate_resource {
    my ($self) = @_;
    # Metabase::Resource->new dies if invalid
    my $obj = Metabase::Resource->new($self->resource);
    if ($obj->scheme eq 'cpan' && $obj->type eq 'distfile') {
      return $obj;
    }
    else {
      my $fact_type = $self->type;
      Carp::confess("'$resource' does not apply to '$fact_type'");
    }
  }

The default C<validate_resource> accepts any resource that can initialize
a C<Metabase::Resource> object.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Metabase-Fact/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Metabase-Fact>

  git clone https://github.com/dagolden/Metabase-Fact.git

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

H.Merijn Brand <hmbrand@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords David Steinbrunner Karen Etheridge Nathan Gary Glenn Randy Stauner

=over 4

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Nathan Gary Glenn <nglenn@cpan.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
