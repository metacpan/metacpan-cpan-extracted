package JSON::Schema::AsType;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: generates Type::Tiny types out of JSON schemas
$JSON::Schema::AsType::VERSION = '0.4.2';
use 5.14.0;

use strict;
use warnings;

use Type::Tiny;
use Type::Tiny::Class;
use Scalar::Util qw/ looks_like_number /;
use List::Util qw/ reduce pairmap pairs /;
use List::MoreUtils qw/ any all none uniq zip /;
use Types::Standard qw/InstanceOf HashRef StrictNum Any Str ArrayRef Int Object slurpy Dict Optional slurpy /; 
use Type::Utils;
use LWP::Simple;
use Clone 'clone';
use URI;
use Class::Load qw/ load_class /;

use Moose::Util qw/ apply_all_roles /;

use JSON;

use Moose;

use MooseX::MungeHas 'is_ro';
use MooseX::ClassAttribute;

no warnings 'uninitialized';

our $strict_string = 1;

class_has schema_registry => (
    is => 'ro',
    lazy => 1,
    default => sub { +{} },
    traits => [ 'Hash' ],
    handles => {
        all_schemas       => 'elements',
        all_schema_uris       => 'keys',
        registered_schema => 'get',
        register_schema   => 'set',
    },
);

around register_schema => sub {
    # TODO Use a type instead to coerce into canonical
    my( $orig, $self, $uri, $schema ) = @_;
    $uri =~ s/#$//;
    $orig->($self,$uri,$schema);
};

has type => ( 
    is => 'rwp',
    handles => [ qw/ check validate validate_explain / ], 
    builder => 1, 
    lazy => 1 
);

has draft_version => (
    is => 'ro',
    lazy => 1,
    default => sub { 
        $_[0]->has_specification ? $_[0]->specification  =~ /(\d+)/ && $1 
            : eval { $_[0]->parent_schema->draft_version } || 4;
    },
    isa => enum([ 3, 4, 6 ]),
);

has spec => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->fetch( sprintf "http://json-schema.org/draft-%02d/schema", $_[0]->draft_version );
    },
);

has schema => ( 
    predicate => 'has_schema',
    lazy => 1,
    default => sub {
        my $self = shift;
            
        my $uri = $self->uri or die "schema or uri required";

        return $self->fetch($uri)->schema;
    },
);

has parent_schema => (
    clearer => 1,
);

has strict_string => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self  = shift;

        $self->parent_schema->strict_string if $self->parent_schema;

        return $JSON::Schema::AsType::strict_string;
    },
);

sub fetch {
    my( $self, $url ) = @_;

    unless ( $url =~ m#^\w+://# ) { # doesn't look like an uri
        my $id =$self->uri;
        $id =~ s#[^/]*$##;
        $url = $id . $url;
            # such that the 'id's can cascade
        if ( my $p = $self->parent_schema ) {
            return $p->fetch( $url );
        }
    }

    $url = URI->new($url);
    $url->path( $url->path =~ y#/#/#sr );
    $url = $url->canonical;

    if ( my $schema = $self->registered_schema($url) ) {
        return $schema;
    }

    my $schema = eval { from_json LWP::Simple::get($url) };

    $DB::single = not ref $schema;
    

    die "couldn't get schema from '$url'\n" unless ref $schema eq 'HASH';

    return $self->register_schema( $url => $self->new( uri => $url, schema => $schema ) );
}

has uri => (
    is => 'rw',
    trigger => sub {
        my( $self, $uri ) = @_;
        $self->register_schema($uri,$self);
        $self->clear_parent_schema;
} );

has references => sub { 
    +{}
};

has specification => (
    predicate => 1,
    is => 'ro',
    lazy => 1,
    default => sub { 
        return 'draft'.$_[0]->draft_version;
        eval { $_[0]->parent_schema->specification } || 'draft4' },
    isa => enum 'JsonSchemaSpecification', [ qw/ draft3 draft4 draft6 / ],
);

sub specification_schema {
    my $self = shift;

    $self->spec->schema;
}

sub validate_schema {
    my $self = shift;
    $self->spec->validate($self->schema);
}

sub validate_explain_schema {
    my $self = shift;
    $self->spec->validate_explain($self->schema);
}

sub root_schema {
    my $self = shift;
    eval { $self->parent_schema->root_schema } || $self;
}

sub is_root_schema {
    my $self = shift;
    return not $self->parent_schema;
}

sub sub_schema {
    my( $self, $subschema ) = @_;
    $self->new( schema => $subschema, parent_schema => $self );
}

sub absolute_id {
    my( $self, $new_id ) = @_;

    return $new_id if $new_id =~ m#://#; # looks absolute to me

    my $base = $self->ancestor_uri;

    $base =~ s#[^/]+$##;

    return $base . $new_id;
}

sub _build_type {
    my $self = shift;

    $self->_set_type('');

    my @types =
        grep { $_ and $_->name ne 'Any' }
        map  { $self->_process_keyword($_) } 
             $self->all_keywords;

    return @types ? reduce { $a & $b } @types : Any
}

sub all_keywords {
    my $self = shift;

    return sort map { /^_keyword_(.*)/ } $self->meta->get_method_list;
}

sub _process_keyword {
    my( $self, $keyword ) = @_;

    return unless exists $self->schema->{$keyword};

    my $value = $self->schema->{$keyword};

    my $method = "_keyword_$keyword";

    $self->$method($value);
}

# returns the first defined parent uri
sub ancestor_uri {
    my $self = shift;
    
    return $self->uri || eval{ $self->parent_schema->ancestor_uri };
}


sub resolve_reference {
    my( $self, $ref ) = @_;

    $ref = join '/', '#', map { $self->_escape_ref($_) } @$ref
        if ref $ref;

    if ( $ref =~ s/^([^#]+)// ) {
        my $base = $1;
        unless( $base =~ m#://# ) {
            my $base_uri = $self->ancestor_uri;
            $base_uri =~ s#[^/]+$##;
            $base =  $base_uri . $base;
        }
        return $self->fetch($base)->resolve_reference($ref);
    }

    $self = $self->root_schema;
    return $self if $ref eq '#';
    
    $ref =~ s/^#//;

#    return $self->references->{$ref} if $self->references->{$ref};

    my $s = $self->schema;

    my @refs = map { $self->_unescape_ref($_) } grep { length $_ } split '/', $ref;

    while( @refs ) {
        my $ref = shift @refs;
        my $is_array = ref $s eq 'ARRAY';

        $s = $is_array ? $s->[$ref] : $s->{$ref} or last;

        if( ref $s eq 'HASH' ) {
            if( my $local_id = $s->{id} || $s->{'$id'} ) {
                my $id  = $self->absolute_id($local_id);
                $self = $self->fetch( $self->absolute_id($id) );
                
                return $self->resolve_reference(\@refs);
            }
        }

    }

    return ( 
        ( ref $s eq 'HASH' or ref $s eq 'JSON::PP::Boolean' ) 
            ?  $self->sub_schema($s) 
            : Any );

}

sub _unescape_ref {
    my( $self, $ref ) = @_;

    $ref =~ s/~0/~/g;
    $ref =~ s!~1!/!g;
    $ref =~ s!%25!%!g;

    $ref;
}

sub _escape_ref {
    my( $self, $ref ) = @_;

    $ref =~ s/~/~0/g;
    $ref =~ s!/!~1!g;
    $ref =~ s!%!%25!g;

    $ref;
}

sub _add_reference {
    my( $self, $path, $schema ) = @_;

    $path = join '/', '#', map { $self->_escape_ref($_) } @$path
        if ref $path;

    $self->references->{$path} = $schema;
}

sub _add_to_type {
    my( $self, $t ) = @_;

    if( my $already = $self->type ) {
        $t = $already & $t;
    }

    $self->_set_type( $t );
}

sub BUILD {
    my $self = shift;
    # TODO rename specification to  draft_version 
    # and have specifications renamed to spec
    apply_all_roles( $self, 'JSON::Schema::AsType::' . ucfirst $self->specification );

    # TODO move the role into a trait, which should take care of this
    $self->type if $self->has_schema;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType - generates Type::Tiny types out of JSON schemas

=head1 VERSION

version 0.4.2

=head1 SYNOPSIS

    use JSON::Schema::AsType;

    my $schema = JSON::Schema::AsType->new( schema => {
            properties => {
                foo => { type => 'integer' },
                bar => { type => 'object' },
            },
    });

    print 'valid' if $schema->check({ foo => 1, bar => { two => 2 } }); # prints 'valid'

    print $schema->validate_explain({ foo => 'potato', bar => { two => 2 } });

=head1 DESCRIPTION

This module takes in a JSON Schema (L<http://json-schema.org/>) and turns it into a
L<Type::Tiny> type.

=head2 Strings and Numbers

By default, C<JSON::Schema::AsType> follows the 
JSON schema specs and distinguish between strings and 
numbers.

    value    String?  Number?
      "a"      yes      no 
       1       no       yes
      "1"      yes      no

If you want the usual Perl
behavior and considers the JSON schema type C<String>
to be a superset of C<Number>. That is:

    value    String?  Number?
      "a"      yes      no 
       1       yes      yes
      "1"      yes      yes

Then you can set the object's attribute C<strict_string> to C<0>. 
Setting the global variable C<$JSON::Schema::AsType::strict_string> to C<0>
will work too, but that's deprecated and will eventually go away.

=head1 METHODS

=head2 new( %args )

    my $schema = JSON::Schema::AsType->new( schema => $my_schema );

The class constructor. Accepts the following arguments.

=over

=item schema => \%schema

The JSON schema to compile, as a hashref. 

If not given, will be retrieved from C<uri>. 

An error will be thrown is neither C<schema> nor C<uri> is given.

=item uri => $uri

Optional uri associated with the schema. 

If provided, the schema will also 
be added to a schema cache. There is currently no way to prevent this. 
If this is an issue for you, you can manipulate the cache by accessing 
C<%JSON::Schema::AsType::EXTERNAL_SCHEMAS> directly.

=item draft_version => $version

The version of the JSON-Schema specification to use. Accepts C<3>  or C<4>,
defaults to '4'. 

=back

=head2 type

Returns the compiled L<Type::Tiny> type.

=head2 check( $struct )

Returns C<true> if C<$struct> is valid as per the schema.

=head2 validate( $struct )

Returns a short explanation if C<$struct> didn't validate, nothing otherwise.

=head2 validate_explain( $struct )

Returns a log explanation if C<$struct> didn't validate, nothing otherwise.

=head2 validate_schema

Like C<validate>, but validates the schema itself against its specification.

    print $schema->validate_schema;

    # equivalent to

    print $schema->specification_schema->validate($schema);

=head2 validate_explain_schema

Like C<validate_explain>, but validates the schema itself against its specification.

=head2 draft_version

Returns the draft version used by the object.

=head2 spec 

Returns the L<JSON::Schema::AsType> object associated with the
specs of this object's schema. 

I.e., if the current object is a draft4 schema, C<spec> will
return the schema definining draft4.

=head2 schema

Returns the JSON schema, as a hashref.

=head2 parent_schema 

Returns the L<JSON::Schema::AsType> object for the parent schema, or
C<undef> is the current schema is the top-level one.

=head2 fetch( $url )

Fetches the schema at the given C<$url>. If already present, it will use the schema in
the cache. If not, the newly fetched schema will be added to the cache.

=head2 uri 

Returns the uri associated with the schema, if any.

=head2 specification

Returns the JSON Schema specification used by the object.

=head2 specification_schema

Returns the L<JSON::Schema::AsType> object representing the schema of 
the current object's specification.

=head2 root_schema

Returns the top-level schema including this schema.

=head2 is_root_schema

Returns C<true> if this schema is a top-level
schema.

=head2 resolve_reference( $ref )

    my $sub_schema = $schema->resolve_reference( '#/properties/foo' );

    print $sub_schema->check( $struct );

Returns the L<JSON::Schema::AsType> object associated with the 
type referenced by C<$ref>.

=head1 SEE ALSO

=over

=item L<JSON::Schema>

=item L<JSV>

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
