# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use strict;
use warnings;

package Mail::Message::TransferEnc::Base64;
use vars '$VERSION';
$VERSION = '3.003';

use base 'Mail::Message::TransferEnc';

use MIME::Base64;


sub name() { 'base64' }

#------------------------------------------

sub check($@)
{   my ($self, $body, %args) = @_;
    $body;
}

#------------------------------------------


sub decode($@)
{   my ($self, $body, %args) = @_;

    my $lines = decode_base64($body->string);
    unless($lines)
    {   $body->transferEncoding('none');
        return $body;
    }
 
    my $bodytype
      = defined $args{result_type} ? $args{result_type}
      : $body->isBinary            ? 'Mail::Message::Body::File'
      :                              ref $body;

    $bodytype->new
     ( based_on          => $body
     , transfer_encoding => 'none'
     , data              => $lines
     );
}

#------------------------------------------

sub encode($@)
{   my ($self, $body, %args) = @_;

    my $bodytype = $args{result_type} || ref $body;

    $bodytype->new
     ( based_on          => $body
     , checked           => 1
     , transfer_encoding => 'base64'
     , data              => encode_base64($body->string)
     );
}

#------------------------------------------

1;
