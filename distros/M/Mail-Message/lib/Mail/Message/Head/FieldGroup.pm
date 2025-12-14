# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Head::FieldGroup;{
our $VERSION = '4.01';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/trace/ ];

use Scalar::Util  qw/blessed/;

#--------------------

sub new(@)
{	my $class = shift;

	my @fields;
	push @fields, shift while blessed $_[0];

	$class->SUPER::new(@_, fields => \@fields);
}

sub init($$)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	my $head = $self->{MMHF_head} = $args->{head} || Mail::Message::Head::Partial->new;

	$self->add($_)                            # add specified object fields
		for @{$args->{fields}};

	$self->add($_, delete $args->{$_})        # add key-value paired fields
		for grep m/^[A-Z]/, keys %$args;

	$self->{MMHF_version}  = $args->{version}  if defined $args->{version};
	$self->{MMHF_software} = $args->{software} if defined $args->{software};
	$self->{MMHF_type}     = $args->{type}     if defined $args->{type};
	$self->{MMHF_fns}      = [];
	$self;
}


sub implementedTypes() { $_[0]->notImplemented }


sub from($) { $_[0]->notImplemented }


sub clone()
{	my $self = shift;
	my $clone = bless %$self, ref $self;
	$clone->{MMHF_fns} = [ $self->fieldNames ];
	$clone;
}

#--------------------

sub head() { $_[0]->{MMHF_head} }


sub attach($)
{	my ($self, $head) = @_;
	$head->add($_->clone) for $self->fields;
	$self;
}


sub delete()
{	my $self = shift;
	my $head = $self->head;
	$head->removeField($_) for $self->fields;
	$self;
}


sub add(@)
{	my $self = shift;
	my $field = $self->head->add(@_) or return ();
	push @{$self->{MMHF_fns}}, $field->name;
	$self;
}


sub fields()
{	my $self = shift;
	my $head = $self->head;
	map $head->get($_), $self->fieldNames;
}


sub fieldNames() { @{ $_[0]->{MMHF_fns}} }


sub addFields(@)
{	my $self = shift;
	my $head = $self->head;

	push @{$self->{MMHF_fns}}, @_;
	@_;
}

#--------------------

sub version() { $_[0]->{MMHF_version} }


sub software() { $_[0]->{MMHF_software} }


sub type() { $_[0]->{MMHF_type} }

#--------------------

sub detected($$$)
{	my $self = shift;
	@$self{ qw/MMHF_type MMHF_software MMHF_version/ } = @_;
}


sub collectFields(;$) { $_[0]->notImplemented }

#--------------------

sub print(;$)
{	my $self = shift;
	my $out  = shift || select;
	$_->print($out) for $self->fields;
}


sub details()
{	my $self     = shift;
	my $type     = $self->type || 'Unknown';

	my $software = $self->software;
	undef $software if defined($software) && $type eq $software;
	my $version  = $self->version;
	my $release  = defined $software
	  ? (defined $version ? " ($software $version)" : " ($software)")
	  : (defined $version ? " ($version)"           : '');

	my $fields   = scalar $self->fields;
	"$type $release, $fields fields";
}

1;
