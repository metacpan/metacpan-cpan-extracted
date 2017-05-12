package Elastic::Model::TypeMap::Common;
$Elastic::Model::TypeMap::Common::VERSION = '0.52';
use strict;
use warnings;

use Elastic::Model::TypeMap::Base qw(:all);
use namespace::autoclean;

#===================================
has_type 'DateTime',
#===================================
    deflate_via {'$val->set_time_zone("UTC")->iso8601'}, inflate_via {
    'do { my %args;'
        . '@args{ (qw(year month day hour minute second)) } = split /\D/, $val;'
        . 'DateTime->new(%args);' . '}';
    },

    map_via { type => 'date' };
1;

# ABSTRACT: Type maps for commonly used types

__END__

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::TypeMap::Common - Type maps for commonly used types

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::TypeMap::Common> provides mapping, inflation and deflation
for commonly used types.

=head1 TYPES

=head2 DateTime

Attributes with an C<< isa => 'DateTime' >> constraint are deflated to
ISO8601 format in UTC, eg C<2012-01-01T01:01:01>, and reinflated via
L<DateTime/"new">.  They are mapped as C<< { type => 'date' } >>.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
