use strict;
use warnings;

package MetaPOD::Format::JSON::interface::v1_1;
BEGIN {
  $MetaPOD::Format::JSON::interface::v1_1::AUTHORITY = 'cpan:KENTNL';
}
{
  $MetaPOD::Format::JSON::interface::v1_1::VERSION = '0.3.0';
}

# ABSTRACT: Implementation of JSON/interface format component


use Moo::Role;
use Carp qw(croak);


sub supported_interfaces {
  return qw( class role type_library exporter single_class function );
}


sub check_interface {
  my ( $self, @ifs ) = @_;
  my $supported = { map { ( $_, 1 ) } $self->supported_interfaces_v1_1 };
  for my $if (@ifs) {
    if ( not exists $supported->{$if} ) {
      croak("interface type $if unsupported in v1.1.0");
    }
  }
  return $self;
}


sub add_interface {
  my ( $self, $interface, $result ) = @_;
  if ( defined $interface and not ref $interface ) {
    return $result->add_interface($interface);
  }
  if ( defined $interface and ref $interface eq 'ARRAY' ) {
    return $result->add_interface( @{$interface} );
  }
  croak 'Unsupported reftype ' . ref $interface;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Format::JSON::interface::v1_1 - Implementation of JSON/interface format component

=head1 VERSION

version 0.3.0

=head1 METHODS

=head2 C<supported_interfaces>

Spec v1.1 C<interface> value list.

    my @valid_interface_tokens = __SOME_CLASS__->supported_interfaces

In this version, supported interfaces are:

    class role type_library exporter single_class function

=head2 C<check_interface>

Spec v1.1 C<interface> Implementation key checking routine

    __SOME_CLASS__->check_interface( $interface, $interface, $interface );

Simply goes C<bang> if C<$interface> is not in C<supported_interfaces_v1_1>

=head2 C<add_interface>

Spec v1.1 C<interface> Implementation

    __SOME_CLASS->add_interface( $data->{interface} , $metapod_result );

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Format::JSON::interface::v1_1",
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
