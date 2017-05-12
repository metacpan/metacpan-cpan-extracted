package FormValidator::Simple::Plugin::NetAddr::MAC;

use 5.008005;
use strict;
use warnings;

use NetAddr::MAC;
use FormValidator::Simple::Constants;

# ABSTRACT: MAC Address validation

our $VERSION = "0.01";
our @CARP_NOT = qw(NetAddr::MAC);

sub NETADDR_MAC {
    my ($self, $params, $args) = @_;

    return eval { NetAddr::MAC->new( mac => $params->[0], die_on_error => 1 ) } ? TRUE : FALSE;
}

sub NETADDR_MAC_LOCAL {
    my ($self, $params, $args) = @_;

    return eval { NetAddr::MAC->new( mac => $params->[0], die_on_error => 1 )->is_local } ? TRUE : FALSE;
}

sub NETADDR_MAC_UNIVERSAL {
    my ($self, $params, $args) = @_;

    return eval { NetAddr::MAC->new( mac => $params->[0], die_on_error => 1 )->is_universal } ? TRUE : FALSE;
}

1;

__END__

=encoding utf-8

=head1 NAME

FormValidator::Simple::Plugin::NetAddr::MAC - MAC Address validation

=head1 SYNOPSIS

  use FormValidator::Simple qw(NetAddr::MAC);

  my $result = FormValidator::Simple->check( $req => [
      mac => [ 'NOT_BLANK', 'NETADDR_MAC' ],
  ] );

=head1 DESCRIPTION

This module adds MAC Address validation commands to FormValidator::Simple.

=head1 VALIDATION COMMANDS

=over 4

=item NETADDR_MAC

Checks for a single MAC address format.

=cut

=item NETADDR_MAC_LOCAL

Checks for a single MAC address format and locally administered.

=cut

=item NETADDR_MAC_UNIVERSAL

Checks for a single MAC address format and universally administered.

=cut

=back

=head1 DEPENDENCY

L<NetAddr::MAC>

=head1 SEE ALSO

L<FormValidator::Simple>

=head1 REPOSITORY

https://github.com/ryochin/p5-formvalidator-simple-plugin-netaddr-mac

=head1 AUTHOR

Ryo Okamoto E<lt>ryo@aquahill.netE<gt>

=head1 LICENSE

Copyright (C) Ryo Okamoto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
