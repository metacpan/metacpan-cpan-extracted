# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::TransferEnc::QuotedPrint;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::TransferEnc';

use strict;
use warnings;

use MIME::QuotedPrint;


sub name() { 'quoted-printable' }

sub check($@)
{   my ($self, $body, %args) = @_;
    $body;
}


sub decode($@)
{   my ($self, $body, %args) = @_;

    my $bodytype = $args{result_type} || ref $body;

    $bodytype->new
     ( based_on          => $body
     , transfer_encoding => 'none'
     , data              => decode_qp($body->string)
     );
}


sub encode($@)
{   my ($self, $body, %args) = @_;

    my $bodytype = $args{result_type} || ref $body;

    $bodytype->new
     ( based_on          => $body
     , transfer_encoding => 'quoted-printable'
     , data              => encode_qp($body->string)
     );
}

1;
