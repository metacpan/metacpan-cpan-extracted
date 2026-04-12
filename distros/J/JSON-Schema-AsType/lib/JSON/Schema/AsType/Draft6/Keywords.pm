package JSON::Schema::AsType::Draft6::Keywords;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft6::Keywords::VERSION = '1.0.0';
# ABSTRACT: Role processing draft6 JSON Schema


use 5.42.0;
use warnings;

use feature qw/ signatures/;

use Moose::Role;

use Type::Utils;
use Scalar::Util    qw/ looks_like_number /;
use List::Util      qw/ reduce pairmap pairs /;
use List::MoreUtils qw/ any all none uniq zip /;
use Types::Standard
  qw/InstanceOf HashRef StrictNum Any Str ArrayRef Int slurpy Dict Optional slurpy /;

use JSON;

use JSON::Schema::AsType;

use JSON::Schema::AsType::Draft6::Types '-all';

with 'JSON::Schema::AsType::Draft4::Keywords';

override _build_type => sub {
    my $self = shift;

    return super() if ref $self->schema eq 'HASH';

    return ( ( $self->schema eq JSON::true ) ? Any : ~Any );

};

sub _keyword_const {
    my $self = shift;

    $self->_keyword_enum( [@_] );
}

sub _keyword_contains {
    my ( $self, $type ) = @_;

    my $min = $self->schema->{minContains} // 1;       # for 2019-09
    my $max = $self->schema->{maxContains} // 9E99;    # for 2019-09

    if ( JSON::is_bool($type) ) {
        if ($type) {
            $min = 1;
        }
        else {
            $max = 0;
        }
    }

    return Contains [ $self->sub_schema( $type, '#./contains' )->type, $min,
        $max ];

}

sub _keyword_exclusiveMaximum {
    my ( $self, $maximum ) = @_;

    ExclusiveMaximum [$maximum];
}

sub _keyword_exclusiveMinimum {
    my ( $self, $maximum ) = @_;

    ExclusiveMinimum [$maximum];
}

sub _keyword_propertyNames {
    my ( $self, $schema ) = @_;

    PropertyNames [ $self->sub_schema( $schema, '#./propertyNames' )->type ];
}

sub _keyword_items( $self, $items, $keyword = 'items' ) {

    if ( Boolean->check($items) ) {
        return if $items;
        return Items [JSON::false];
    }

    if ( ref $items eq 'HASH' ) {
        my $type = $self->sub_schema( $items, "#./$keyword" )->type;

        return Items [$type];
    }

    # TODO forward declaration not workie
    my @types;
    my $i = 0;
    for (@$items) {
        push @types, $self->sub_schema( $_, "#./$keyword/" . $i++ )->type;
    }

    return Items [ \@types ];
}

sub _keyword_dependencies {
    my ( $self, $dependencies ) = @_;

    return Dependencies [
        pairmap {
              $a => ( ref $b eq 'HASH' or ref $b eq 'JSON::PP::Boolean' )
            ? $self->sub_schema( $b, '#./dependencies/' . $a )
            : $b
          } %$dependencies
    ];

}

__PACKAGE__->meta->add_method(
    '_keyword_$id' => sub {
        my $self = shift;
        $self->_keyword_id(@_);
    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft6::Keywords - Role processing draft6 JSON Schema

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
