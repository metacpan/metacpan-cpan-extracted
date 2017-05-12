package Elastic::Model::0_90::Result;
$Elastic::Model::0_90::Result::VERSION = '0.52';
use Moose;
extends 'Elastic::Model::Result';

use Carp;
use Elastic::Model::Types qw(UID);
use MooseX::Types::Moose qw(HashRef Maybe Num Bool);

use namespace::autoclean;

around BUILDARGS => sub {
    my $orig   = shift;
    my $class  = shift;
    my $params = ref $_[0] eq 'HASH' ? shift : {@_};
    my $fields = $params->{result}{fields};
    for ( keys %$fields ) {
        next if substr( $_, 0, 1 ) eq '_';
        $fields->{$_} = [ $fields->{$_} ]
            unless ref $fields->{$_} eq 'ARRAY';
    }
    return $class->$orig($params);
};

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::0_90::Result - A 0.90.x compatibility class for Elastic::Model::Result

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::0_90::Result> converts the values in C<fields>
into arrays, in the same way that they are returned in Elasticsearch
1.x.

See L<Elastic::Manual::Delta> for more information about enabling
the 0.90.x compatibility mode.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A 0.90.x compatibility class for Elastic::Model::Result

