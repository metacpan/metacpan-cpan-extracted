
use strict;
use warnings;

package MetaPOD::Format::JSON::namespace::v1;
BEGIN {
  $MetaPOD::Format::JSON::namespace::v1::AUTHORITY = 'cpan:KENTNL';
}
{
  $MetaPOD::Format::JSON::namespace::v1::VERSION = '0.3.0';
}

# ABSTRACT: Implementation of JSON/namespace format component


use Moo::Role;


sub add_namespace {
  my ( $self, $namespace, $result ) = @_;
  return $result->set_namespace($namespace);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Format::JSON::namespace::v1 - Implementation of JSON/namespace format component

=head1 VERSION

version 0.3.0

=head1 METHODS

=head2 C<add_namespace>

Spec V1 C<namespace> Implementation

    $impl->add_namespace( $data->{namespace} , $metapod_result );

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Format::JSON::namespace::v1",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
