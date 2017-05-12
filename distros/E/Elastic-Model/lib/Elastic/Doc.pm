package Elastic::Doc;
$Elastic::Doc::VERSION = '0.52';
use Moose();
use Moose::Exporter;
use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    with_meta       => [ 'has_mapping', 'apply_field_settings' ],
    class_metaroles => {
        class     => ['Elastic::Model::Meta::Class::Doc'],
        attribute => ['Elastic::Model::Trait::Field'],
    },
    also => 'Moose',
);

#===================================
sub init_meta {
#===================================
    shift;
    my $meta = Moose->init_meta(@_);
    Moose::Util::apply_all_roles( $meta, 'Elastic::Model::Role::Doc' );
}

#===================================
sub has_mapping { shift->mapping(@_) }
#===================================

#===================================
sub apply_field_settings {
#===================================
    my $meta = shift;

    if ( @_ == 1 and $_[0] eq '-exclude' ) {
        for ( $meta->get_all_attributes ) {
            next
                if $_->does('Elastic::Model::Trait::Field')
                or $_->does('Elastic::Model::Trait::Exclude');
            Moose::Util::apply_all_roles( $_,
                'Elastic::Model::Trait::Exclude' );
        }
        return;
    }

    my %settings = @_ == 1 ? %{ shift() } : @_;
    for my $name ( keys %settings ) {
        my $attr = $meta->get_attribute($name)
            or die "Couldn't find attr ($name) in class ("
            . $meta->name
            . ") in apply_field_settings()";
        Moose::Util::ensure_all_roles( $attr,
            'Elastic::Model::Trait::Field' );
        my $params = $settings{$name};
        for ( keys %$params ) {
            $attr->$_( $params->{$_} );
        }
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Doc - Adds Elastic::Model functionality to your object classes

=head1 VERSION

version 0.52

=head1 SYNOPSIS

=head2 Simple class definition

    package MyApp::User;

    use Elastic::Doc;

    has 'name' => (
        is  => 'rw',
        isa => 'Str'
    );

    no Elastic::Doc;

=head2 More complex class definition

    package MyApp::User;

    use Elastic::Doc;

    has_mapping {
        _ttl => {                       # delete documents/object after 2 hours
            enabled => 1,
            default => '2h'
        }
    };

    has 'user' => (
        is  => 'ro',
        isa => 'MyApp::User'
    );

    has 'title' => (
        is       => 'rw',
        isa      => 'Str',
        analyzer => 'edge_ngrams'       # use custom analyzer
    );

    has 'body' => (
        is       => 'rw',
        isa      => 'Str',
        analyzer => 'english',          # use builtin analyzer
    );

    has 'created' => (
        is       => 'ro',
        isa      => 'DateTime',
        default  => sub { DateTime->new }
    );

    has 'tag' => (
        is      => 'ro',
        isa     => 'Str',
        index   => 'not_analyzed'       # index exact value
    );

    no Elastic::Doc;

=head1 DESCRIPTION

Elastic::Doc prepares your object classes (eg C<MyApp::User>) for storage in
Elasticsearch, by:

=over

=item *

applying L<Elastic::Model::Role::Doc> to your class and
L<Elastic::Model::Meta::Doc> to its metaclass

=item *

adding keywords to your attribute declarations, to give you control over how
they are indexed (see L<Elastic::Manual::Attributes>)

=item *

wrapping your accessors to allow auto-inflation of embedded objects (see
L<Elastic::Model::Meta::Instance>).

=item *

exporting the L</"has_mapping"> function to allow you to customize the
special "meta-fields" in the type mapping in Elasticsearch

=back

=head1 INTRODUCTION TO Elastic::Model

If you are not familiar with L<Elastic::Model>, you should start by reading
L<Elastic::Manual::Intro>.

The rest of the documentation on this page explains how to use the
L<Elastic::Doc> module itself.

=head1 EXPORTED FUNCTIONS

=head2 has_mapping

C<has_mapping> can be used to customize the special "meta-fields" (ie not
attr/field-specific) in the type mapping. For instance:

    has_mapping {
        _source => {
            includes    => ['path1.*','path2.*'],
            excludes    => ['path3.*']
        },
        _ttl => {
            enabled     => 1,
            default     => '2h'
        },
        numeric_detection   => 1,
        date_detection      => 0,
    };

B<Warning:> Use C<has_mapping> with caution. L<Elastic::Model> requires
certain settings to be active to work correctly.

See the "Fields" section in L<Mapping|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-fields.html> and
L<Root object type|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-root-object-type.html>
for more information about what options can be configured.

=head2 apply_field_settings

    package MyApp::User;

    use Elastic::Doc;
    with 'MyApp::Role::Foo';

    apply_field_settings {
        field_1 => { type    => 'string' },
        field_2 => { exclude => 1        }
    };

When you apply a role to your Elastic::Doc class, you may not be able to
configure the attributes directly in the role (eg if the role comes from
CPAN).

You can use C<apply_field_settings> in your doc class to add any of the
settings specified in L<Elastic::Manual::Attributes>.  Alternatively,
if you don't want any of the imported attributes to be persisted to
Elasticsearch, then you can specify:

    apply_field_settings '-exclude';

B<Note:> the C<-exclude> is applied to all attributes applied thus far, which
don't already do L<Elastic::Model::Trait::Field>. So you
can then apply other roles and have another C<apply_field_settings> statement
later in your module.

If you DO have access to the role, then the preferred way to configure
attributes is with the C<ElasticField> trait:

    package MyApp::Role::Foo;

    use Moose::Role;

    has 'name' => (
        traits  => ['ElasticField'],
        is      => 'rw',
        index   => 'not_analyzed'
    );

C<ElasticField> is the short name for L<Elastic::Model::Trait::Field>.

=head1 SEE ALSO

=over

=item *

L<Elastic::Model::Role::Doc>

=item *

L<Elastic::Model>

=item *

L<Elastic::Meta::Trait::Field>

=item *

L<Elastic::Model::TypeMap::Default>

=item *

L<Elastic::Model::TypeMap::Moose>

=item *

L<Elastic::Model::TypeMap::Objects>

=item *

L<Elastic::Model::TypeMap::Structured>

=item *

L<Elastic::Model::TypeMap::ES>

=item *

L<Elastic::Model::TypeMap::Common>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Adds Elastic::Model functionality to your object classes


