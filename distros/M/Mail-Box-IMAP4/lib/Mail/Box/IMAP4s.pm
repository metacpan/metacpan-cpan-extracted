# This code is part of Perl distribution Mail-Box-IMAP4 version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::IMAP4s;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::IMAP4';

use strict;
use warnings;

use Log::Report     'mail-box-imap4', import => [];

use IO::Socket::SSL qw/SSL_VERIFY_NONE/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{server_port} = 993;
	$args->{starttls}    = 0;
	$self->SUPER::init($args);
}

sub type() {'imap4s'}

sub createTransporter($@)
{	my ($self, $class, %args) = @_;
	$args{starttls} = 0;
	$args{ssl} ||= +{ SSL_verify_mode => SSL_VERIFY_NONE };
	$self->SUPER::createTransporter($class, %args);
}

1;
