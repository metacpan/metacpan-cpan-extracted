use strict;
use warnings;

package MetaPOD::Format::JSON::inherits::v1;
BEGIN {
  $MetaPOD::Format::JSON::inherits::v1::AUTHORITY = 'cpan:KENTNL';
}
{
  $MetaPOD::Format::JSON::inherits::v1::VERSION = '0.3.0';
}

# ABSTRACT: Implementation of JSON/inherits format component


use Moo::Role;
use Carp qw(croak);


sub add_inherits {
  my ( $self, $inherits, $result ) = @_;
  if ( defined $inherits and not ref $inherits ) {
    return $result->add_inherits($inherits);
  }
  if ( defined $inherits and ref $inherits eq 'ARRAY' ) {
    return $result->add_inherits( @{$inherits} );
  }
  croak 'Unsupported reftype ' . ref $inherits;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Format::JSON::inherits::v1 - Implementation of JSON/inherits format component

=head1 VERSION

version 0.3.0

=head1 METHODS

=head2 C<add_inherits>

Spec v1 C<inherits> Implementation

    $impl->add_inherits( $data->{inherits} , $metapod_result );

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Format::JSON::inherits::v1",
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
