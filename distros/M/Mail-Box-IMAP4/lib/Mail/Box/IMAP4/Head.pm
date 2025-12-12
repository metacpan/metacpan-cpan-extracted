# This code is part of Perl distribution Mail-Box-IMAP4 version 4.000.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::IMAP4::Head;{
our $VERSION = '4.000';
}

use base 'Mail::Message::Head';

use warnings;
use strict;

use Log::Report 'mail-box-imap4';

#--------------------

sub init($$)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBIH_c_fields} = $args->{cache_fields};
	$self;
}


sub get($;$)
{	my ($self, $name, $index) = @_;

	   if(not $self->{MBIH_c_fields}) { ; }
	elsif(wantarray)
	{	my @values = $self->SUPER::get(@_);
		return @values if @values;
	}
	else
	{	my $value  = $self->SUPER::get(@_);
		return $value  if defined $value;
	}

	# Something here, playing with ENVELOPE, may improve the performance
	# as well.
	my $imap   = $self->message->folder->transporter;
	my $uidl   = $self->message->unique;
	my @fields = $imap->getFields($uidl, $name);

	if(@fields && $self->{MBIH_c_fields})
	{	$self->addNoRealize($_) for @fields
	}

	defined $index ? $fields[$index] : wantarray ? @fields : $fields[0];
}

sub guessBodySize()  {undef}
sub guessTimestamp() {undef}

#--------------------

1;
