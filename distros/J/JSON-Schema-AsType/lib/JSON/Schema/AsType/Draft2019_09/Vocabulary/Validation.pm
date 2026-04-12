package JSON::Schema::AsType::Draft2019_09::Vocabulary::Validation;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2019_09::Vocabulary::Validation::VERSION = '1.0.0';
# ABSTRACT: Validation vocabulary for draft 2019-09 schemas


use 5.42.0;
use warnings;

use feature         qw/ module_true /;
use Types::Standard qw/Any/;
use List::Util      qw/ pairmap /;

use Moose::Role;

use JSON::Schema::AsType::Draft2019_09::Types qw/
  DependentRequired
  DependentSchemas
  UnevaluatedProperties
  UnevaluatedItems
  /;

with 'JSON::Schema::AsType::Draft7::Keywords' => { -exclude => [] };

__PACKAGE__->meta->add_method(
    '_keyword_$recursiveRef' => sub {
        my ( $self, $ref ) = @_;

        my $schema;

        return Type::Tiny->new(
            name         => 'RecursiveRef',
            display_name => "RecursiveRef($ref)",
            constraint   => sub {

                my $v = $_;

                my $anchor;
                my $parent = $self;

                my $first_id;

                while ( $parent = $parent->parent_schema ) {

                    # warn "===> ".$parent->uri, "\n";
                    # warn "anchor: ", $anchor && $anchor->uri, "\n";
                    # warn "first ", $first_id && $first_id->uri, "\n";
                    if (    $parent->schema->{'$id'}
                        and !$parent->schema->{'$recursiveAnchor'}
                        and not $first_id ) {
                        $first_id = $parent;
                        last;
                    }
                    $anchor = $parent
                      if $parent->schema->{'$recursiveAnchor'};
                }

                # warn "anchor: ", $anchor && $anchor->uri, "\n";
                # warn "first ", $first_id && $first_id->uri, "\n";

                if ( !$anchor ) {
                    if ($first_id) {
                        return $first_id->check($v);
                    }
                    my $method = '_keyword_$ref';
                    my $type   = $self->$method($ref);
                    $type = $type->base_type if $type->can('base_type');
                    return $type->check($v);
                }

                # use DDP; p $anchor->schema;
                # warn "checking for $v\n";
                return $anchor->base_type->check($v);
            },
        );
    }
);

sub _keyword_dependentRequired {
    my ( $self, $depends ) = @_;

    DependentRequired [$depends];
}

sub _keyword_dependentSchemas {
    my ( $self, $depends ) = @_;

    my %depends =
      pairmap {
        $a => $self->sub_schema( $b, "#./dependentSchema/$a" )->base_type }
      %$depends;

    DependentSchemas [ \%depends ];
}

sub _keyword_unevaluatedProperties( $self, $subschema ) {
    my $schema = $self->sub_schema( $subschema, '#./unevaluatedProperties' );

    return UnevaluatedProperties [ $schema->base_type ];

}

sub _keyword_unevaluatedItems( $self, $subschema ) {
    my $schema = $self->sub_schema( $subschema, '#./unevaluatedItems' );

    return UnevaluatedItems [ $schema->base_type ];

}

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft2019_09::Vocabulary::Validation - Validation vocabulary for draft 2019-09 schemas

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION

This role is not intended to be used directly. It is used internally
by L<JSON::Schema::AsType> objects.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
