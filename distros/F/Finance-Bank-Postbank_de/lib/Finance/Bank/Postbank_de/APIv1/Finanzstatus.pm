package Finance::Bank::Postbank_de::APIv1::Finanzstatus;
use Moo;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
extends 'HAL::Resource';

use Finance::Bank::Postbank_de::APIv1::BusinessPartner;
use Finance::Bank::Postbank_de::APIv1::Message;

our $VERSION = '0.54';

=head1 NAME

Finance::Bank::Postbank_de::APIv1::Finanzstatus - Postbank Finanzstatus

=head1 SYNOPSIS

    my $finanzstatus = $postbank->navigate(
        class => 'Finance::Bank::Postbank_de::APIv1::Finanzstatus',
        path => ['banking_v1' => 'financialstatus']
    );

=cut

has [ 'businesspartners',
      'amount',
      'brokerageable',
      'hash',
      'md5Hash',
      'messages',
      'name',
      'selectUser',
      'teaserUrl'.
      'totalAmount',
] => ( is => 'ro' );

sub available_messages( $self ) {
    my $mb = $self->fetch_resource( 'messagebox' );
    $self->inflate_list(
        'Finance::Bank::Postbank_de::APIv1::Message',
        $mb->_embedded->{notificationDTOList}
    );
}

sub get_businesspartners( $self ) {
    $self->inflate_list(
        'Finance::Bank::Postbank_de::APIv1::BusinessPartner',
        $self->businesspartners
    );
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
