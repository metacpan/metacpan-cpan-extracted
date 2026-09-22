package IO::K8s::CertManager::V1::OrderStatus;
# ABSTRACT: OrderStatus
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authorizations => ['+IO::K8s::CertManager::V1::ACMEAuthorization'];
k8s certificate    => Str;
k8s failureTime    => Time;
k8s finalizeURL    => Str;
k8s reason         => Str;
k8s state          => Str, { enum => [qw(valid ready pending processing invalid expired errored)] };
k8s url            => Str;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::OrderStatus - OrderStatus

=head1 VERSION

version 1.108

=head2 authorizations

Authorizations contains data returned from the ACME server on what
authorizations must be completed in order to validate the DNS names
specified on the Order.

=head2 certificate

Certificate is a copy of the PEM encoded certificate for this Order.
This field will be populated after the order has been successfully
finalized with the ACME server, and the order has transitioned to the
'valid' state.

=head2 failureTime

FailureTime stores the time that this order failed.
This is used to influence garbage collection and back-off.

=head2 finalizeURL

FinalizeURL of the Order.
This is used to obtain certificates for this order once it has been completed.

=head2 reason

Reason optionally provides more information about a why the order is in
the current state.

=head2 state

State contains the current state of this Order resource.
States 'success' and 'expired' are 'final'

=head2 url

URL of the Order.
This will initially be empty when the resource is first created.
The Order controller will populate this field when the Order is first processed.
This field will be immutable after it is initially set.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
