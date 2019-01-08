package Finance::Bank::Postbank_de::APIv1::Message;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

our $VERSION = '0.56';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Finanzstatus - Postbank Finanzstatus

=head1 SYNOPSIS

=cut

has [ 
 'productType',
 'notificationId',
 'iban',
 'deletionDate',
 'messages',
 'deleteable',
 'confirmationLimitDate',
 'receiptDate',
 'confirmationDate',
 'postalDispatchDate',
 'priority',
 'accountDescription',
 'type', # 'EBS', 'CAMPAIGN', 'SIGNAL', 'SETTLEMENT', ...
 'subject',
 'state', # 'NEW', 'READ'
] => ( is => 'ro' );

sub attachments_future( $self ) {
    $self->fetch_resource_future( 'attachements' )
}
    
sub attachments( $self ) {
    $self->attachments_future->get
}

sub confirm( $self ) {
    die "confirm() is not implemented yet";
    $self->ua->post( $self->resource_url( 'confirm' ))
}

1;
=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Finance-Bank-Postbank_de>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-Postbank_de>
or via mail to L<finance-bank-postbank_de-Bugs@rt.cpan.org>.

=head1 COPYRIGHT (c)

Copyright 2003-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
