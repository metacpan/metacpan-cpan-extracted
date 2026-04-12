package JSON::Schema::AsType;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::VERSION = '1.0.0';
# ABSTRACT: generates Type::Tiny types out of JSON schemas

use 5.14.0;

use feature 'signatures';

use strict;
use warnings;

use PerlX::Maybe;
use Type::Tiny;
use Type::Tiny::Class;
use Scalar::Util    qw/ looks_like_number /;
use List::Util      qw/ reduce pairmap pairs /;
use List::MoreUtils qw/ any all none uniq zip /;
use Types::Standard
  qw/InstanceOf HashRef StrictNum Any Str ArrayRef Int Object slurpy Dict Optional slurpy /;
use Type::Utils;
use Clone 'clone';
use URI;
use Module::Runtime qw/ use_module /;

use Moose::Util qw/ apply_all_roles ensure_all_roles /;

use JSON;
use Type::Utils qw( class_type );

use Moose;
use MooseX::MungeHas 'is_ro';

with 'JSON::Schema::AsType::Registry';
with 'JSON::Schema::AsType::Type';

no warnings 'uninitialized';

our $strict_string = 1;

our @DRAFT_VERSIONS = ( 3, 4, 6, 7, '2019-09', '2020-12' );

has draft => (
    is      => 'ro',
    lazy    => 1,
    default => sub($self) {
        return $self->parent_schema->draft if $self->parent_schema;
        return $DRAFT_VERSIONS[-1];
    },
    isa => enum( \@DRAFT_VERSIONS ),
);

has metaschema => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->fetch( sprintf "https://json-schema.org/draft-%02d/schema",
            $_[0]->draft );
    },
);

has schema => (
    predicate => 'has_schema',
    is        => 'ro',
    lazy      => 1,
    default   => sub {
        return +{};
        my $self = shift;

        my $uri = $self->uri or die "schema or uri required";

        return $self->fetch($uri)->schema;
    },
);

sub _schema_trigger { }

has parent_schema => ( clearer => 1, );

has strict_string => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return $self->parent_schema->strict_string if $self->parent_schema;

        return $JSON::Schema::AsType::strict_string;
    },
);

our %VOCABULARY;

has vocabularies => (
    is      => 'ro',
    lazy    => 1,
    default => sub($self) {

        return [] unless $self->metaschema;

        my $v = $self->metaschema->schema->{'$vocabulary'} or return [];

        return [ pairmap { ($a) x !!$b } %$v ];
    }
);

sub add_vocabulary( $self, $vocab ) {
    push $self->vocabularies->@*, $vocab;
    ensure_all_roles( $self, $vocab );
}

sub vocabulary_role( $self, $url ) {
    $VOCABULARY{$url};
}

has uri => (
    is  => 'ro',
    isa => class_type( { class => 'URI' } )->plus_constructors( Str, "new", ),
    coerce  => 1,
    trigger => sub {
        my ( $self, $uri ) = @_;
        return if $uri->fragment;
    }
);

sub sub_schema( $self, $subschema, $uri ) {

    $uri = $self->resolve_uri($uri) if $uri;

    JSON::Schema::AsType->new(
        draft         => $self->draft,
        schema        => $subschema,
        parent_schema => $self,
        registry      => $self->registry,
        strict_string => $self->strict_string,
        fetch_remote  => $self->fetch_remote,
        maybe uri     => $uri
    );

}

sub all_active_keywords($self) {
    return grep { exists $self->schema->{$_} } $self->all_keywords;
}

sub all_keywords {
    my $self = shift;

    # 'id' has to be first
    return sort { $a eq 'id' ? -1 : $b eq 'id' ? 1 : $a cmp $b }
      map { /^_keyword_(.*)/ } $self->meta->get_method_list;
}

sub has_keyword( $self, $keyword ) {
    my $method = "_keyword_$keyword";
    return $self->can($method);
}

sub _process_keyword {
    my ( $self, $keyword ) = @_;

    my $value = $self->schema->{$keyword};

    my $method = "_keyword_$keyword";

    $self->$method($value);
}

sub resolve_reference {
    my ( $self, $ref ) = @_;

    my $uri = $self->resolve_uri($ref);

    my $schema = $self->fetch($uri) or die "couldn't retrieve schema $uri\n";

    return $schema;
}

sub _unescape_ref {
    my ( $self, $ref ) = @_;

    $ref =~ s/~0/~/g;
    $ref =~ s!~1!/!g;
    $ref =~ s!%25!%!g;
    $ref =~ s!%22!"!g;

    $ref;
}

sub _escape_ref {
    my ( $self, $ref ) = @_;

    $ref =~ s/~/~0/g;
    $ref =~ s!/!~1!g;
    $ref =~ s!%!%25!g;
    $ref =~ s!"!%22!g;

    $ref;
}

sub BUILD {
    my $self = shift;

    use_module( 'JSON::Schema::AsType::Draft' . $self->draft =~ s/-/_/r )
      ->meta->rebless_instance($self);

    # make it available early for the potential $refs
    $self->register_schema( $self->uri, $self ) if $self->uri;

    # TODO move the role into a trait, which should take care of this
    $self->_schema_trigger( $self->schema ) if $self->has_schema;

    my @roles =
      map { $self->vocabulary_role($_) } $self->vocabularies->@*;

    ensure_all_roles( $self, @roles ) if @roles;

    $self->_after_build if $self->can('_after_build');

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType - generates Type::Tiny types out of JSON schemas

=head1 VERSION

version 1.0.0

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

    my $schema = JSON::Schema::AsType->new( 
		schema => $json_schema 
	);

The class constructor. Accepts the following arguments.

=over

=item schema => \%schema

The JSON schema to compile, as a hashref. 

If not given, will be retrieved from C<uri>. 

An error will be thrown is neither C<schema> nor C<uri> is given.

=item uri => $uri

Optional uri associated with the schema. If not provided, a local 
uri C<http://254.0.0.1:$port> will be assigned to the schema.

=item draft => $version

The version of the JSON-Schema specification to use. Accepts C<3>, C<4>,
C<6>, C<7>, C<2019-09>, and C<2020-12>. Defaults to C<2020-12>. 

=item fetch_remote => $boolean 

If sets to true, allows C<fetch> to retrieve remote schemas. 

=item registry => $registry 

	JSON::Schema::AsType->new(
		schema => {
			'$id' => 'http://localhost/foo',
			$ref => 'bar',
		}
		registry => {
			'http://localhost/bar' => {
				type => 'string'
			}
		}
	);

Registry of schemas that can be used by the current schema. 

=back

=head2 metaschema 

Returns the metaschema of the current schema, based on its C<draft> version.

=head2 uri

Returns the URI of the schema, as a L<URI> object.

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

=head2 validate_explain_schema

Like C<validate_explain>, but validates the schema itself against its specification.

=head2 draft

Returns the draft version used by the object.

=head2 schema

Returns the JSON schema, as a hashref.

=head2 fetch( $url )

Fetches the schema at the given C<$url> and returns it as a 
L<JSON::Schema::AsType> object. 

=head2 resolve_reference( $ref )

    my $sub_schema = $schema->resolve_reference( '#/properties/foo' );

    print $sub_schema->check( $struct );

Returns the L<JSON::Schema::AsType> object associated with the 
type referenced by C<$ref>.

=head2 add_vocabulary($vocabulary_role) 

	$schema->add_vocabulary('Anagram');

Adds a vocabulary to the schema. C<$vocabulary_role> is the name of a role
implementing the vocabulary keywords and behaviors. See the section C<ADDING A
VOCABULARY> for more details.

=head1 ADDING A VOCABULARY 

Vocabularies have been introduced in draft 2019-09 of JSON Schema, but 
they are available in all draft versions in JSON::Schema::AsType. They are,
basically, sets of keywords and behaviors that we want our schema to have
access to. For JSON::Schema::AsType, they are implemented using roles. 

For example, let's say we want to implement a new C<anagram_of> keyword, which
would ensure that a string in the schema is an anagram of a provided word. We
could create the role C<Anagram>:

	package Anagram;

	use feature qw/ signatures module_true/;

	use Type::Tiny;
	use Types::Standard qw/ Str /;
		
	use Moose::Role;

	sub _normalize_word($word) {
		join '', sort split '', $word;
	}

	my $anagram_type = Type::Tiny->new( 
		name => 'Anagram',
		constraint_generator => sub($word) {
			$word = _normalize_word($word);

			return sub {
				_normalize_word($_) eq $word;
			}
		},
		deep_explanation => sub($type,$value,@) {
			my $p = $type->parameters->[0];
			[qq{"$value" is not an anagram of "$p"}];
		},
	);

	sub _keyword_anagram_of($self, $word ) {
		# don't check anagrams on non-strings
		return ~Str | $anagram_type->of($word)
	}

And then, to have a schema use it:

	my $schema = JSON::Schema::AsType->new(
		schema => {
			type => 'string',
			anagram_of => 'meat',
		}
	);

	print $schema->check('team');   # 1
	print $schema->check('tomato'); # undef

=head1 COMPLIANCE TO THE SPECS 

L<JSON::Schema::AsType> passes all the JSON schema test suites 
L<https://github.com/json-schema-org/JSON-Schema-Test-Suite> excepts 
for the following:

	drafts  |  test file / test 
	------- | ------------------
 	all     | const.json / float and integers are equal up to 64-bit representation limits
	2019-09 | ref.json / refs with relative uris and defs
	2019-09 | ref.json / relative refs with absolute uris and defs
	2020-12 | pattern.json / pattern with Unicode property escape requires unicode mode
	2020-12 | defs.json / * 
	2020-12 | unevaluatedItems / *
	2020-12 | unevaluatedProperties / * 
	2020-12 | dynamicRef / * 
	2020-12 | ref / *

=head2 Known limitations/design decisions 

=over

=item JSON Schema assumes a 64-bit representation of floats and integers, 
whereas L<JSON::Schema::AsType> adheres to whatever the local perl supports.

=item For C<pattern>s, L<JSON::Schema::AsType> assumes we always are in
unicode mode.

=item Some hairy C<ref> tests are failing for drafts C<2019-09> and
C<2020-12>. For most common uses, that shouldn't be a problem.

=back

=head1 SEE ALSO

=over

=item L<JSON::Schema>

=item L<JSV>

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
