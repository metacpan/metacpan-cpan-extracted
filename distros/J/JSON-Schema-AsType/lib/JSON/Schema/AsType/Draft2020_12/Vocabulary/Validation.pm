package JSON::Schema::AsType::Draft2020_12::Vocabulary::Validation;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2020_12::Vocabulary::Validation::VERSION = '1.0.0';
# ABSTRACT: Validation vocabulary for draft 2020-12 schemas


use 5.42.0;
use warnings;

use feature         qw/ module_true signatures /;
use Types::Standard qw/Any ArrayRef /;
use List::Util      qw/ pairmap /;

use Moose::Role;

use JSON::Schema::AsType::Draft4::Types       qw/ Boolean /;
use JSON::Schema::AsType::Draft2019_09::Types qw/ /;
use JSON::Schema::AsType::Draft2020_12::Types qw/ MinContains MaxContains /;

use JSON::Schema::AsType::Annotations;
use JSON::Schema::AsType::Draft6::Keywords;

with 'JSON::Schema::AsType::Draft2019_09::Vocabulary::Validation' =>
  { -excludes => [ map { "_keyword_$_" } qw/items contains/ ] };

sub _keyword_minContains( $self, $min ) {
    return Any unless $self->schema->{contains};
    return ~ArrayRef | MinContains [$min];
}

sub _keyword_maxContains( $self, $min ) {
    return Any unless $self->schema->{contains};
    return ~ArrayRef | MaxContains [$min];
}

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft2020_12::Vocabulary::Validation - Validation vocabulary for draft 2020-12 schemas

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
