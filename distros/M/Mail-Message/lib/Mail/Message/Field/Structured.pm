# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Structured;{
our $VERSION = '3.019';
}

use base 'Mail::Message::Field::Full';

use strict;
use warnings;

use Mail::Message::Field::Attribute;
use Storable 'dclone';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->{MMFS_attrs} = {};
	$self->{MMFS_datum} = $args->{datum};

	$self->SUPER::init($args);

	my $attr = $args->{attributes} || [];
	$attr    = [ %$attr ] if ref $attr eq 'HASH';

	while(@$attr)
	{	my $name = shift @$attr;
		if(ref $name) { $self->attribute($name) }
		else          { $self->attribute($name, shift @$attr) }
	}

	$self;
}

sub clone() { dclone(shift) }

#--------------------

sub attribute($;$)
{	my ($self, $attr) = (shift, shift);
	my $name;
	if(ref $attr) { $name = $attr->name }
	elsif( !@_ )  { return $self->{MMFS_attrs}{lc $attr} }
	else
	{	$name = $attr;
		$attr = Mail::Message::Field::Attribute->new($name, @_);
	}

	delete $self->{MMFF_body};
	$self->{MMFS_attrs}{lc $name} = $attr;
}


sub attributes() { values %{$_[0]->{MMFS_attrs}} }
sub beautify()   { delete $_[0]->{MMFF_body} }


sub attrPairs() { map +($_->name, $_->value), $_[0]->attributes }

#--------------------

sub parse($)
{	my ($self, $string) = @_;

	for($string)
	{	# remove FWS, even within quoted strings
		s/\r?\n(\s)/$1/gs;
		s/\r?\n/ /gs;
		s/\s+$//;
	}

	my $datum = '';
	while(length $string && substr($string, 0, 1) ne ';')
	{	(undef, $string)  = $self->consumeComment($string);
		$datum .= $1 if $string =~ s/^([^;(]+)//;
	}
	$self->{MMFS_datum} = $datum;

	my $found = '';
	while($string =~ m/\S/)
	{	my $len = length $string;

		if($string =~ s/^\s*\;\s*// && length $found)
		{	my ($name) = $found =~ m/^([^*]+)\*/;
			if($name && (my $cont = $self->attribute($name)))
			{	$cont->addComponent($found);   # continuation
			}
			else
			{	my $attr = Mail::Message::Field::Attribute->new($found);
				$self->attribute($attr);
			}
			$found = '';
		}

		(undef, $string) = $self->consumeComment($string);
		$string =~ s/^\n//;
		(my $text, $string) = $self->consumePhrase($string);
		$found .= $text if defined $text;

		if(length($string) == $len)
		{	# nothing consumed, remove character to avoid endless loop
			$string =~ s/^\s*\S//;
		}
	}

	if(length $found)
	{	my ($name) = $found =~ m/^([^*]+)\*/;
		if($name && (my $cont = $self->attribute($name)))
		{	$cont->addComponent($found); # continuation
		}
		else
		{	my $attr = Mail::Message::Field::Attribute->new($found);
			$self->attribute($attr);
		}
	}

	1;
}

sub produceBody()
{	my $self  = shift;
	my $attrs = $self->{MMFS_attrs};
	my $datum = $self->{MMFS_datum};

	join '; ', ($datum // ''),
		map $_->string, @{$attrs}{sort keys %$attrs};
}


sub datum(@)
{	my $self = shift;
	@_ or return $self->{MMFS_datum};
	delete $self->{MMFF_body};
	$self->{MMFS_datum} = shift;
}

1;
