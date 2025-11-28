# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Search::SpamAssassin;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Search';

use strict;
use warnings;

use Mail::SpamAssassin;
use Mail::Message::Wrapper::SpamAssassin;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	$args->{in}  ||= 'MESSAGE';
	$args->{label} = 'spam' unless exists $args->{label};

	$self->SUPER::init($args);

	$self->{MBSS_rewrite_mail} = exists $args->{rewrite_mail} ? $args->{rewrite_mail} : 1;
	$self->{MBSS_sa} = $args->{spamassassin} // Mail::SpamAssassin->new($args->{sa_options} // {});
	$self;
}

#--------------------

sub assassinator() { $_[0]->{MBSS_sa} }


sub rewriteMail() { $_[0]->{MBSS_rewrite_mail} }

#--------------------

sub searchPart($)
{	my ($self, $message) = @_;
	my @details = ( message => $message );
	my $sa      = Mail::Message::Wrapper::SpamAssassin->new($message) or return;
	my $status  = $self->assassinator->check($sa);

	my $is_spam = $status->is_spam;
	$status->rewrite_mail if $self->rewriteMail;

	if($is_spam && (my $deliver = $self->deliver))
	{	$deliver->( +{ @details, status => $status } );
	}

	$is_spam;
}

sub inHead(@) { $_[0]->notImplemented }
sub inBody(@) { $_[0]->notImplemented }

1;
