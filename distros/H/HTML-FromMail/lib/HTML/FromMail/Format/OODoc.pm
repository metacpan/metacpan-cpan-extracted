# This code is part of Perl distribution HTML-FromMail version 3.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Format::OODoc;{
our $VERSION = '3.01';
}

use base 'HTML::FromMail::Format';

use strict;
use warnings;

use Carp;
use OODoc::Template    ();

#--------------------

#-----------

sub oodoc() { $_[0]->{HFFM_oodoc} }

#-----------

sub expand($$$$)
{	my ($self, $args, $tag, $attrs, $textref) = @_;

	# Lookup the method to be called.
	my $method = 'html' . ucfirst($tag);
	my $prod   = $args->{producer};

	$prod->can($method) or return undef;

	my %info  = (%$args, %$attrs, textref => $textref);
	$prod->$method($args->{object}, \%info);
}

sub export($@)
{	my ($self, %args) = @_;

	my $oodoc  = $self->{HFFM_oodoc} = OODoc::Template->new;

	my $output = $args{output};
	open my($out), ">", $output
		or $self->log(ERROR => "Cannot write to $output: $!"), return;

	my $input  = $args{input};
	open my($in), "<", $input
		or $self->log(ERROR => "Cannot open template file $input: $!"), return;

	my $template = join '', <$in>;
	close $in;

	my %defaults = (
		DYNAMIC => sub { $self->expand(\%args, @_) },
	);

	my $oldout   = select $out;
	$oodoc->parse($template, \%defaults);
	select $oldout;

	close $out;
	$self;
}

sub containerText($)
{	my ($self, $args) = @_;
	my $textref = $args->{textref};
	defined $textref ? $$textref : undef;
}

sub processText($$)
{	my ($self, $text, $args) = @_;
	$self->oodoc->parse($text, {});
}

sub lookup($$)
{	my ($self, $what, $args) = @_;
	$self->oodoc->valueFor($what);
}

sub onFinalToken($)
{	my ($self, $args) = @_;
	not (defined $args->{textref} && defined ${$args->{textref}});
}

1;
