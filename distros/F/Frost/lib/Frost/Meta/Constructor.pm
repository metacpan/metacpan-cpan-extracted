package Frost::Meta::Constructor;

#	LIBS
#
use Moose::Role;

use Frost::Util;

#	CLASS VARS
#
our $VERSION	= 0.62;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#	PUBLIC ATTRIBUTES
#

#	PRIVATE ATTRIBUTES
#

#	CONSTRUCTORS
#

#	DESTRUCTORS
#

#	PUBLIC METHODS
#

#	PRIVATE METHODS
#
around '_generate_instance' => sub
{
	my $next									= shift;
	my ( $self, $var, $class_var )	= @_;

	my $plain_instance	= $self->$next ( $var, $class_var );

	#	Order of attributes / params is unpredictable!
	#	So we have to make shure, that db and id are set first - and in this order!
	#
	my $id_index;
	my $am_index;

	my $default_initializers	= '';

	my @attributes	= @{ $self->_attributes || [] };

	for ( my $i = 0; $i < @attributes; $i++ )
	{
		my $attr		= $attributes[$i];

		$id_index	= $i		if $attr->name eq 'id';
		$am_index	= $i		if $attr->name eq 'asylum';

#		last		if defined $id_index and defined $am_index;

#	see Locum::_populate_defaults...
#
#		next	if $attr->name eq 'id';
#		next	if $attr->name eq 'asylum';
#		next	if $attr->name eq '_status';
#		next	if $attr->name eq '_dirty';
#
#		if ( $attr->is_transient )
#		{
#	    	if ( ( $attr->has_default || $attr->has_builder ) && ! $attr->is_lazy )
#	    	{
#	    		$default_initializers	||= ";\n"	if $default_initializers;
#	    		$default_initializers	.= $self->_generate_slot_initializer ( $i );
#	    	}
#		}
#
#	now inline...
	}

	my $id_initializer		= $self->_generate_slot_initializer ( $id_index );
	my $am_initializer		= $self->_generate_slot_initializer ( $am_index );

	my $status_exists			= "'" . STATUS_EXISTS . "'";

	my $populate_defaults	= $self->_generate_populate_defaults();

	my $code		=<<"EOT";

$plain_instance;		#	my $var = ...

#::DEBUG 'AA XXXXXXXXXXXXXXXXXXX', ::Dumper $var\->{id}, $var;

$am_initializer;		#	order!

#::DEBUG 'BB XXXXXXXXXXXXXXXXXXX', ::Dumper $var\->{id}, $var;

$id_initializer;		#	sets _status as well... see Frost::Locum->_evoke 'id'

#::DEBUG 'CC XXXXXXXXXXXXXXXXXXX', ::Dumper $var\->{id}, $var;

{
	if ( $var\->{_status} eq $status_exists )
	{
#		$default_initializers;
#		$var\->_populate_defaults();

my \$was_dirty	= $var\->_evoke ( "_dirty" );

$populate_defaults;

$var->_silence ( "_dirty", 0 )	unless \$was_dirty;

		return $var;
	}

	#::DEBUG 'DD XXXXXXXXXXXXXXXXXXX MISSING', ::Dumper $var\->{id}, $var;

	#	continue with
	#	_generate_slot_initializers
	#	_generate_triggers
	#	_generate_BUILDALL
}

EOT

	#DEBUG "\n============================\n", $code, "\n============================\n";

	return $code;
};

sub _generate_populate_defaults
{
	my ( $self )	= @_;

	return
	(
		join ";\n" => map
		{
			$self->_generate_populate_default ( $_ )
		}
		0 .. ( @ { $self->_attributes } - 1 )
	) . ";\n";
}

sub _generate_populate_default
{
	my $self		= shift;
	my $index	= shift;

	my $attr			= $self->_attributes->[$index];

	my $is_moose	= $attr->isa('Moose::Meta::Attribute'); # XXX FIXME

	my $slot			= $attr->name;

	my $header		= '## ' . $slot;

	return $header			unless	( $attr->is_virtual or $attr->is_transient );
	return $header			if			( $slot =~ /^( asylum | _dirty | _status )$/x );
	return $header			unless	(($attr->has_default || $attr->has_builder) && !($is_moose && $attr->is_lazy));

	my @source		= ( $header );

	push @source => "unless ( \$instance->_exists ( '$slot' ) )";
	push @source => "{";

	my $default;

	if ( $attr->has_default )
	{
		$default		= $self->_generate_default_value ( $attr, $index );
	}
	else
	{
		my $builder	= $attr->builder;
		$default		= '$instance->' . $builder;
	}

	push @source	=> '{';	#	wrap this to avoid my $val overwrite warnings
	push @source	=> 'my $val = ' . $default . ';';
	push @source	=> $self->_generate_type_constraint_and_coercion ( $attr, $index )		if $is_moose;
	push @source	=> $self->_generate_slot_assignment ( $attr, '$val', $index );
	push @source	=> '}'; 	#	close - wrap this to avoid my $val overrite warnings

	push @source => "}";

   return join "\n" => @source;
}


#	CALLBACKS
#

#	IMMUTABLE
#
no Moose::Role;

#	__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__

=head1 NAME

Frost::Meta::Constructor - The Builder

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=for comment CLASS METHODS

=for comment PUBLIC ATTRIBUTES

=for comment PRIVATE ATTRIBUTES

=for comment CONSTRUCTORS

=for comment DESTRUCTORS

=for comment PUBLIC METHODS

=head1 PRIVATE METHODS

=head2 _generate_instance

=head2 _generate_populate_defaults

=head2 _generate_populate_default

=for comment CALLBACKS

=for comment IMMUTABLE

=head1 GETTING HELP

I'm reading the Moose mailing list frequently, so please ask your
questions there.

The mailing list is L<moose@perl.org>. You must be subscribed to send
a message. To subscribe, send an empty message to
L<moose-subscribe@perl.org>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs to me or the mailing list.

=head1 AUTHOR

Ernesto L<ernesto@dienstleistung-kultur.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Dienstleistung Kultur Ltd. & Co. KG

L<http://dienstleistung-kultur.de/frost/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
