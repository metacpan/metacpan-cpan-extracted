# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::TransferEnc;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Reporter';

use strict;
use warnings;


my %encoder =
 ( base64 => 'Mail::Message::TransferEnc::Base64'
 , '7bit' => 'Mail::Message::TransferEnc::SevenBit'
 , '8bit' => 'Mail::Message::TransferEnc::EightBit'
 , 'quoted-printable' => 'Mail::Message::TransferEnc::QuotedPrint'
 );

#------------------------------------------

 
sub create($@)
{   my ($class, $type) = (shift, shift);

    my $encoder = $encoder{lc $type};
    unless($encoder)
    {   $class->new(@_)->log(WARNING => "No decoder for transfer encoding $type.");
        return;
    }

    eval "require $encoder";
    if($@)
    {   $class->new(@_)->log(ERROR =>
            "Decoder for transfer encoding $type does not work:\n$@");
        return;
    }

    $encoder->new(@_);
}


sub addTransferEncoder($$)
{   my ($class, $type, $encoderclass) = @_;
    $encoder{lc $type} = $encoderclass;
    $class;
}


sub name {shift->notImplemented}

#------------------------------------------

sub check($@) {shift->notImplemented}


sub decode($@) {shift->notImplemented}


sub encode($) {shift->notImplemented}

#------------------------------------------

1;
