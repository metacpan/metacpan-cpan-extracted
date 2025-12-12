# This code is part of Perl distribution Mail-Box-POP3 version 4.000.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::POP3s;{
our $VERSION = '4.000';
}

use parent 'Mail::Box::POP3';

use strict;
use warnings;

use Log::Report  'mail-box-pop3';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{server_port} ||= 995;
	$self->SUPER::init($args);
	$self;
}

sub type() {'pop3s'}

#--------------------

sub popClient(%)
{	my $self = shift;
	$self->SUPER::popClient(@_, use_ssl => 1);
}

1;
