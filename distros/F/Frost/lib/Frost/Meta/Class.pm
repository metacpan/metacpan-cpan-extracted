package Frost::Meta::Class;

#	LIBS
#
use Moose::Role;

use Frost::Types;
use Frost::Util;

#	CLASS VARS
#
our $VERSION	= 0.63;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#
sub _construct_instance
{
	die "mutable is VERBOTEN";
}

#	PUBLIC ATTRIBUTES
#
has _readonly_attributes	=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);
has _transient_attributes	=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);
has _derived_attributes		=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);
has _virtual_attributes		=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);
has _index_attributes		=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);
has _unique_attributes		=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);
has _auto_id_attributes		=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);
has _auto_inc_attributes	=> ( is => 'ro', isa => 'HashRef',	lazy_build => 1	);

#	CONSTRUCTORS
#
sub _build__readonly_attributes	{ $_[0]->_build_features ( 'readonly'	);	}
sub _build__transient_attributes	{ $_[0]->_build_features ( 'transient'	);	}
sub _build__derived_attributes	{ $_[0]->_build_features ( 'derived'	);	}
sub _build__virtual_attributes	{ $_[0]->_build_features ( 'virtual'	);	}
sub _build__index_attributes		{ $_[0]->_build_features ( 'index'		);	}
sub _build__unique_attributes		{ $_[0]->_build_features ( 'unique'		);	}
sub _build__auto_id_attributes	{ $_[0]->_build_features ( 'auto_id'	);	}
sub _build__auto_inc_attributes	{ $_[0]->_build_features ( 'auto_inc'	);	}

#	DESTRUCTORS
#

#	PUBLIC METHODS
#
sub is_readonly	{ $_[0]->_is_feature ( $_[1], 'readonly'	);	}
sub is_transient	{ $_[0]->_is_feature ( $_[1], 'transient'	);	}
sub is_derived		{ $_[0]->_is_feature ( $_[1], 'derived'	);	}
sub is_virtual		{ $_[0]->_is_feature ( $_[1], 'virtual'	);	}
sub is_index		{ $_[0]->_is_feature ( $_[1], 'index'		);	}
sub is_unique		{ $_[0]->_is_feature ( $_[1], 'unique'		);	}
sub is_auto_id		{ $_[0]->_is_feature ( $_[1], 'auto_id'	);	}
sub is_auto_inc	{ $_[0]->_is_feature ( $_[1], 'auto_inc'	);	}

around add_attribute => sub
{
	my $next	= shift;
	my $self	= shift;

	my $attr	= ( blessed $_[0] && $_[0]->isa ( 'Class::MOP::Attribute' ) ? true : false );

	return $self->$next ( @_ )		if $attr;

	my ( $name, @params )	= @_;

	my %options	= ( ( scalar @params == 1 and ref($params[0]) eq 'HASH' ) ? %{$params[0]} : @params );

	##IS_DEBUG and DEBUG __PACKAGE__, '->add_attribute start', Dump [ $name, \%options ], [qw( name options )];

	my $base_name	= $name;

	$base_name	=~ s/^\+//;

	if ( $base_name !~ /^( id )$/x )
	{
		( exists $options{auto_id}		and $options{auto_id} )		and die "Attribute $base_name can not be auto_id";
		( exists $options{auto_inc}	and $options{auto_inc} )	and die "Attribute $base_name can not be auto_inc";
	}

	if ( $base_name =~ /^( id )$/x )
	{
		( exists $options{transient}	and $options{transient}	)	and die "Attribute $base_name can not be transient";
		( exists $options{derived}		and $options{derived}	)	and die "Attribute $base_name can not be derived";
		( exists $options{virtual}		and $options{virtual}	)	and die "Attribute $base_name can not be virtual";
		( exists $options{index}		and $options{index}		)	and die "Attribute $base_name can not be indexed";

		(
			( exists $options{auto_id}		and $options{auto_id} )
			and
			( exists $options{auto_inc}	and $options{auto_inc} )
		)																			and die "Attribute $base_name can not be auto_id and auto_inc";

		if ( exists $options{auto_id}	and $options{auto_id} )
		{
			( exists $options{isa} )										and die "Auto-Id: Illegal inherited options => (isa)";
			( exists $options{lazy} )										and die "Auto-Id: Illegal inherited options => (lazy)";
			( exists $options{lazy_build} )								and die "Auto-Id: Illegal inherited options => (lazy_build)";
			( exists $options{default} )									and die "Auto-Id: Illegal inherited options => (default)";

			$options{isa}			= 'Frost::UniqueStringId';
		}

		if ( exists $options{auto_inc}	and $options{auto_inc} )
		{
			( exists $options{isa} )										and die "Auto-Inc: Illegal inherited options => (isa)";
			( exists $options{lazy} )										and die "Auto-Inc: Illegal inherited options => (lazy)";
			( exists $options{lazy_build} )								and die "Auto-Inc: Illegal inherited options => (lazy_build)";
			( exists $options{default} )									and die "Auto-Inc: Illegal inherited options => (default)";

			$options{isa}			= 'Frost::Natural';
		}

		unless ( $options{definition_context}->{package} eq 'Frost::Locum' )
		{
			( exists $options{is} )											and die "Illegal inherited options => (is)";
			( exists $options{required} )									and die "Illegal inherited options => (required)";

			$options{is}			= 'ro'			unless $name =~ /^\+/;	#	needed by Moose...
			$options{required}	= true;
			$options{isa}			= 'Frost::UniqueId'	unless exists $options{isa};

			$self->_check_index_constraint ( $name, $options{isa} );
		}
	}

	if ( $base_name =~ /^( asylum | _status | _dirty | real_class )$/x )
	{
		( $options{definition_context}->{package} eq 'Frost::Locum' )
				or die "Attribute $base_name redefined";
	}

	if ( exists $options{derived} and $options{derived} )
	{
		( exists $options{is} and $options{is} ne 'ro' )
												and die "Derived attribute $name is read-only by default";
		( exists $options{virtual} )	and die "Attribute $name can only be derived or virtual";
		( exists $options{init_arg} )	and die "Derived attribute $name can not have an init_arg";

		$options{is}			= 'ro';
		$options{virtual}		= true;
		$options{init_arg}	= undef;

		$options{lazy_build}	= true		unless exists $options{default};
	}
	else
	{
		$options{derived}		= false;
	}

	if ( exists $options{virtual} and $options{virtual} )
	{
		$options{is}			||= 'ro';

		( $options{is} =~ /^(ro|rw)$/ )	or die "Attribute $name must have at least a read-only accessor";
	}
	else
	{
		$options{virtual}		= false;
	}

	if ( exists $options{transient} and $options{transient} )
	{
		$options{is}			||= 'ro';

		( $options{is} =~ /^(ro|rw)$/ )	or die "Attribute $name must have at least a read-only accessor";
	}
	else
	{
		$options{transient}	= false;
	}

	if ( exists $options{index} and $options{index} )
	{
		( $options{derived} )			and die "Derived attribute $name can not be indexed";
		( $options{virtual} )			and die "Virtual attribute $name can not be indexed";
		( $options{transient} )			and die "Transient attribute $name can not be indexed";

		( $options{index} =~ /^(1|unique)$/ )
			or die "I do not understand this option (index => " . $options{index} . ") on attribute ($name)";

		$self->_check_index_constraint ( $name, $options{isa} );

		$options{is}			||= 'ro';

		( $options{is} =~ /^(ro|rw)$/ )	or die "Attribute $name must have at least a read-only accessor";
	}
	else
	{
		$options{index}	= false;
	}

	##IS_DEBUG and DEBUG "add_attribute done\n", Dumper $name, \%options;
	##IS_DEBUG and DEBUG "add_attribute done";

	$attr	= $self->$next ( $name, %options );

#	local $Data::Dumper::Deparse		= 1;
#
#	#IS_DEBUG and DEBUG "add_attribute done $name", Dumper $attr		if $name eq 'num';
#
#	die 'BANANE'		if $name eq 'num';
#
#	#IS_DEBUG and DEBUG "add_attribute done $name", Dumper $attr		if $name eq '_dirty';

	##IS_DEBUG and DEBUG "add_attribute done $name";

	return $attr;
};

#	PRIVATE METHODS
#
sub _build_features
{
	my ( $self, $feature )	= @_;

	my $class	= $self->name;

	my $hashes	=
	{
		readonly		=> {},
		transient	=> {},
		derived		=> {},
		virtual		=> {},
		index			=> {},
		unique		=> {},
		auto_id		=> {},
		auto_inc		=> {},
	};

	foreach my $attr ( $class->meta->get_all_attributes() )
	{
		my $key		= $class . '|' . $attr->name;

		$hashes->{readonly	}->{$key}	= true		if $attr->is_readonly;
		$hashes->{transient	}->{$key}	= true		if $attr->is_transient;
		$hashes->{derived		}->{$key}	= true		if $attr->is_derived;
		$hashes->{virtual		}->{$key}	= true		if $attr->is_virtual;
		$hashes->{index		}->{$key}	= true		if $attr->is_index;
		$hashes->{unique		}->{$key}	= true		if $attr->is_unique;
		$hashes->{auto_id		}->{$key}	= true		if $attr->is_auto_id;
		$hashes->{auto_inc	}->{$key}	= true		if $attr->is_auto_inc;
	}

	foreach my $key ( keys %$hashes )
	{
		next		if $key eq $feature;

		$self->{$key}	= $hashes->{$key};
	}

	##IS_DEBUG and DEBUG Dumper $hashes, $self;

	return $hashes->{$feature};
}

sub _is_feature
{
	my ( $self, $attr_name, $feature )	= @_;

	my $class	= $self->name;
	my $key		= $class . '|' . $attr_name;

	my $method	= '_' . $feature . '_attributes';

	my $result	= $self->$method()->{$key} || false;

	return $result;
}

sub _check_index_constraint
{
	my ( $self, $attr_name, $option_isa )	= @_;

	#IS_DEBUG and DEBUG Dump [ $attr_name, $option_isa ], [qw( attr_name option_isa )];

	my ( $type_constraint_name, $constraint, $id_type_ok );

	if ( $option_isa )
	{
		$type_constraint_name		= Moose::Util::TypeConstraints::normalize_type_constraint_name ( $option_isa );
	}

	if ( $type_constraint_name )
	{
		$constraint = Moose::Util::TypeConstraints::find_type_constraint ( $type_constraint_name );
	}

	#local $Data::Dumper::Deparse		= 1;
	##IS_DEBUG and DEBUG 'XXXXXXXXXXXXX 1 ', Dumper $type_constraint_name, $constraint;

	if ( $constraint )
	{
		$id_type_ok	= (
								$constraint->is_a_type_of ( 'Num' ) or
								$constraint->is_a_type_of ( 'Str' ) or
								$constraint->is_a_type_of ( 'Frost::UniqueId' )
							);
	}

	unless ( $id_type_ok )
	{
		if ( $constraint )
		{
			while ( $constraint	= $constraint->parent )
			{
				#IS_DEBUG and DEBUG 'checking ', $constraint->name;
				##IS_DEBUG and DEBUG 'XXXXXXXXXXXXX 2 ', Dumper $type_constraint_name, $constraint;

				$id_type_ok	= (
										$constraint->is_a_type_of ( 'Num' ) or
										$constraint->is_a_type_of ( 'Str' ) or
										$constraint->is_a_type_of ( 'Frost::UniqueId' )
									);

				last	if $id_type_ok;
			}
		}
	}

	( $id_type_ok )	or die
								(
									( $attr_name eq 'id' ? 'Attribute' : 'Indexed attribute' )
									. " $attr_name\'s isa => '"
									. ( defined $option_isa ? $option_isa : 'undef' )
									. "' does not inherit from 'Num', 'Str' or 'Frost::UniqueId'"
								);

	return $id_type_ok;
}

#	CALLBACKS
#

#	IMMUTABLE
#
sub make_mutable
{
	die "mutable is VERBOTEN";
}

no Moose::Role;

#	__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__

=head1 NAME

Frost::Meta::Class - The Root

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=head1 CLASS METHODS

=head2 Frost::Meta::Class->_construct_instance ( @_ )

Dies with "mutable is VERBOTEN"

=head1 PUBLIC ATTRIBUTES

=head2 _readonly_attributes

=head2 _transient_attributes

=head2 _derived_attributes

=head2 _virtual_attributes

=head2 _index_attributes

=head2 _unique_attributes

=head2 _auto_id_attributes

=head2 _auto_inc_attributes

=head1 PRIVATE ATTRIBUTES

=head1 CONSTRUCTORS

=head2 _build__readonly_attributes

=head2 _build__transient_attributes

=head2 _build__derived_attributes

=head2 _build__virtual_attributes

=head2 _build__index_attributes

=head2 _build__unique_attributes

=head2 _build__auto_id_attributes

=head2 _build__auto_inc_attributes

=head1 DESTRUCTORS

=head2 DEMOLISH

=head1 PUBLIC METHODS

=head2 is_readonly

=head2 is_transient

=head2 is_derived

=head2 is_virtual

=head2 is_index

=head2 is_unique

=head2 is_auto_id

=head2 is_auto_inc

=head2 add_attribute

=head1 PRIVATE METHODS

=head2 _build_features

=head2 _is_feature

=head2 _check_index_constraint

=for comment CALLBACKS

=head1 IMMUTABLE

=head2 make_mutable

Dies with "mutable is VERBOTEN"

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
