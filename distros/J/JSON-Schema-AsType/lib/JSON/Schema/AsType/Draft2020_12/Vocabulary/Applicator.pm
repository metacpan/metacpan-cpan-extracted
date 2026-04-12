package JSON::Schema::AsType::Draft2020_12::Vocabulary::Applicator;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2020_12::Vocabulary::Applicator::VERSION = '1.0.0';
# ABSTRACT: Draft 2020-12 Applicator vocabulary


use 5.42.0;
use warnings;

use feature qw/ module_true /;

use Moose::Role;

use Types::Standard qw/ Any ArrayRef /;
use JSON::Schema::AsType::Annotations;
use JSON::Schema::AsType::Draft4::Types       qw/ Boolean /;
use JSON::Schema::AsType::Draft2019_09::Types qw/ /;
use JSON::Schema::AsType::Draft2020_12::Types qw/ PrefixItems Items Contains/;

use JSON::Schema::AsType::Draft6::Keywords;

with 'JSON::Schema::AsType::Draft2019_09::Vocabulary::Applicator' =>
  { -excludes => [ map { "_keyword_$_" } qw/ contains items/ ] };

sub _keyword_prefixItems ( $self, $items, $keyword = 'prefixItems' ) {

    if ( Boolean->check($items) ) {
        return if $items;
        return PrefixItems [JSON::false];
    }

    if ( ref $items eq 'HASH' ) {
        my $type = $self->sub_schema( $items, "#./$keyword" )->type;

        return PrefixItems [$type];
    }

    # TODO forward declaration not workie
    my @types;
    my $i = 0;
    for (@$items) {
        push @types, $self->sub_schema( $_, "#./$keyword/" . $i++ )->type;
    }

    return PrefixItems [ \@types ];
}

sub _keyword_items {
    my ( $self, $s ) = @_;

    my $schema = $self->sub_schema( $s, '#./items' );

    # items is schema => additionalItems does nothing
    return Any if ref $self->schema->{prefixItems} eq 'HASH';

    my $to_skip = ( $self->schema->{prefixItems} || [] )->@*;

    return ~ArrayRef | Items [ $to_skip, $schema ];

}

sub _keyword_contains( $self, $schema ) {

    my $type = $self->sub_schema( $schema, '#./contains' )->type;

    my $contains = sub {
        my $v = $_;
        add_annotation( 'contains',
            grep { $type->check( $v->[$_] ) } 0 .. $_->$#* );
        return 1;
    };

    $contains = Contains [$type] & $contains
      unless exists $self->schema->{minContains}
      and $self->schema->{minContains} == 0;

    return ~ArrayRef | $contains;

}

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft2020_12::Vocabulary::Applicator - Draft 2020-12 Applicator vocabulary

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. 

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
