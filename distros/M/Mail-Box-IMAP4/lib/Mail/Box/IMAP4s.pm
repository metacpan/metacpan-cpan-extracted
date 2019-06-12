# Copyrights 2001-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box-IMAP4.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::IMAP4s;
use vars '$VERSION';
$VERSION = '3.006';

use base 'Mail::Box::IMAP4';

use strict;
use warnings;

use IO::Socket::IP;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);


sub init($)
{   my ($self, $args) = @_;
    $args->{server_port} = 993;
	$args->{starttls}    = 0;
    $self->SUPER::init($args);
}

sub type() {'imap4s'}


sub createTransporter($@)
{   my ($self, $class, %args) = @_;
    $args{starttls} = 0;
    $args{ssl} ||= { SSL_verify_mode => SSL_VERIFY_NONE };
    $self->SUPER::createTransporter($class, %args);
}

1;
