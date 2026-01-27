# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Head;{
our $VERSION = '4.03';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/mistake/ ];

use Mail::Message::Head::Complete;
use Mail::Message::Field::Fast;

use Scalar::Util   qw/weaken/;

#--------------------

use overload
	qq("") => 'string_unless_carp',
	bool   => 'isEmpty';

# To satisfy overload in static resolving.
sub toString() { $_[0]->load->toString }
sub string()   { $_[0]->load->string }

sub string_unless_carp()
{	my $self = shift;
	(caller)[0] eq 'Carp' or return $self->toString;

	my $class = ref $self =~ s/^Mail::Message/MM/r;
	"$class object";
}

#--------------------

sub new(@)
{	my $class = shift;
	$class eq __PACKAGE__ ? Mail::Message::Head::Complete->new(@_) : $class->SUPER::new(@_);
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->message($args->{message}) if defined $args->{message};
	$self->{MMH_field_type} = $args->{field_type} if $args->{field_type};
	$self->{MMH_fields}     = {};
	$self->{MMH_order}      = [];
	$self->{MMH_modified}   = $args->{modified} || 0;
	$self;
}


sub build(@)
{	shift;
	Mail::Message::Head::Complete->build(@_);
}

#--------------------

sub isDelayed { 1 }


sub modified(;$)
{	my $self = shift;
	return $self->isModified unless @_;
	$self->{MMH_modified} = shift;
}


sub isModified() { $_[0]->{MMH_modified} }


sub isEmpty { scalar keys %{ $_[0]->{MMH_fields}} }


sub message(;$)
{	my $self = shift;
	if(@_)
	{	$self->{MMH_message} = shift;
		weaken($self->{MMH_message});
	}

	$self->{MMH_message};
}


sub orderedFields() { grep defined, @{ $_[0]->{MMH_order}} }


sub knownNames() { keys %{ $_[0]->{MMH_fields}} }

#--------------------

sub get($;$)
{	my $known = shift->{MMH_fields};
	my $value = $known->{lc(shift)};
	my $index = shift;

	if(defined $index)
	{	return ! defined $value   ? undef
		  : ref $value eq 'ARRAY' ? $value->[$index]
		  : $index == 0           ? $value
		  :    undef;
	}

	if(wantarray)
	{	return ! defined $value   ? ()
		  : ref $value eq 'ARRAY' ? @$value
		  :    ($value);
	}

	    ! defined $value      ? undef
	  : ref $value eq 'ARRAY' ? $value->[-1]
	  :    $value;
}

sub get_all(@) { my @all = shift->get(@_) }   # compatibility, force list
sub setField($$) {shift->add(@_)} # compatibility


sub study($;$)
{	my $self = shift;
	return map $_->study, $self->get(@_)
		if wantarray;

	my $got  = $self->get(@_);
	defined $got ? $got->study : undef;
}

#--------------------


sub isMultipart()
{	my $type = $_[0]->get('Content-Type', 0);
	$type && scalar $type->body =~ m[^multipart/]i;
}

#--------------------

sub read($)
{	my ($self, $parser) = @_;

	my @fields = $parser->readHeader;
	@$self{ qw/MMH_begin MMH_end/ } = (shift @fields, shift @fields);

	my $type   = $self->{MMH_field_type} // 'Mail::Message::Field::Fast';

	$self->addNoRealize( $type->new(@$_) ) for @fields;
	$self;
}


#  Warning: fields are added in addResentGroup() as well!
sub addOrderedFields(@)
{	my $order = shift->{MMH_order};
	foreach (@_)
	{	push @$order, $_;
		weaken( $order->[-1] );
	}
	@_;
}


sub load($) { $_[0] }


sub fileLocation()
{	my $self = shift;
	@$self{ qw/MMH_begin MMH_end/ };
}


sub moveLocation($)
{	my ($self, $dist) = @_;
	$self->{MMH_begin} -= $dist;
	$self->{MMH_end}   -= $dist;
	$self;
}


sub setNoRealize($)
{	my ($self, $field) = @_;

	my $known = $self->{MMH_fields};
	my $name  = $field->name;

	$self->addOrderedFields($field);
	$known->{$name} = $field;
	$field;
}


sub addNoRealize($)
{	my ($self, $field) = @_;

	my $known = $self->{MMH_fields};
	my $name  = $field->name;

	$self->addOrderedFields($field);

	if(defined $known->{$name})
	{	if(ref $known->{$name} eq 'ARRAY') { push @{$known->{$name}}, $field }
		else { $known->{$name} = [ $known->{$name}, $field ] }
	}
	else
	{	$known->{$name} = $field;
	}

	$field;
}

#--------------------

1;
