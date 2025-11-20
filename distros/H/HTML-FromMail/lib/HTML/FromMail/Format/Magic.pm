# This code is part of Perl distribution HTML-FromMail version 3.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package HTML::FromMail::Format::Magic;{
our $VERSION = '3.00';
}

use base 'HTML::FromMail::Format';

use strict;
use warnings;

use Carp;

BEGIN
{	eval { require Template::Magic };
	$@ and die "Install Bundle::Template::Magic for this formatter\n";
}

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;
	$self;
}

sub export($@)
{	my ($self, %args) = @_;

	my $magic = $self->{HFFM_magic} = Template::Magic->new(
		markers       => 'HTML',
		zone_handlers => sub { $self->lookupTemplate(\%args, @_) },
	);

	open my($out), ">", $args{output}
		or $self->log(ERROR => "Cannot write to $args{output}: $!"), return;

	my $oldout = select $out;
	$magic->print($args{input});
	select $oldout;

	close $out;
	$self;
}



sub magic() { $_[0]->{HFFM_magic} }


sub lookupTemplate($$)
{	my ($self, $args, $zone) = @_;

	# Lookup the method to be called.
	my $method = 'html' . ucfirst($zone->id);
	my $prod   = $args->{producer};
	return undef unless $prod->can($method);

	# Split zone attributes into hash.  Added to %$args.
	my $param = $zone->attributes || '';
	$param =~ s/^\s+//;
	$param =~ s/\s+$//;

	my %args  = (%$args, zone => $zone);
	if(length $param)
	{	foreach my $pair (split /\s*\,\s*/, $param)
		{	my ($k, $v) = split /\s*\=\>\s*/, $pair, 2;
			$args{$k} = $v;
		}
	}

	my $value = $prod->$method($args{object}, \%args);
	$zone->value = $value if defined $value;
}

our $msg_zone;  # hack
sub containerText($)
{	my ($self, $args) = @_;
	my $zone = $args->{zone};
	$msg_zone = $zone if $zone->id eq 'message';  # hack
	$zone->content;
}

sub processText($$)
{	my ($self, $text, $args) = @_;
	my $zone = $args->{zone};

	# this hack is needed to get things to work :(
	# but this will not work in the future.
	$zone->_s = $msg_zone->_s;
	$zone->_e = $msg_zone->_e;
	$zone->merge;
}

sub lookup($$)
{	my ($self, $what, $args) = @_;
	my $zone  = $args->{zone} or confess;
	$zone->lookup($what);
}

sub onFinalToken($)
{	my ($self, $args) = @_;
	my $zone = $args->{zone} or confess;
	! defined $zone->content;
}

1;
