package JSON::Schema::AsType::Draft7::Keywords;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft7::Keywords::VERSION = '1.0.0';
# ABSTRACT: Role processing draft7 JSON Schema


use strict;
use warnings;

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

use JSON::Schema::AsType::Draft7::Types qw/ If /;

with 'JSON::Schema::AsType::Draft6::Keywords';

sub _keyword_if {
    my ( $self, $if ) = @_;

    $if = $self->sub_schema( $if, '#./if' )->base_type;

    my @clauses = map {
        defined $self->schema->{$_}
          ? $self->sub_schema( $self->schema->{$_}, "#./$_" )->base_type
          : Any
    } qw/ then else/;

    return If [ $if, @clauses ];

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft7::Keywords - Role processing draft7 JSON Schema

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
