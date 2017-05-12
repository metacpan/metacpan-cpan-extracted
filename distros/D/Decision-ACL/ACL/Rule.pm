package Decision::ACL::Rule;


use strict;
use Carp;
use Data::Dumper;

use Decision::ACL::Constants qw(:rule);

use constant DEBUG_LEVEL => 0;
				
sub new
{
	my $parent = shift;
	my $args = shift;

	croak "No arguments to new()" if not defined $args;
	croak "Arguments to new() is not a hashref" if !UNIVERSAL::isa($args, 'HASH');
	croak "No fields specified for new()" if not defined $args->{fields};
	croak "Fields argument is not a hashref" if !UNIVERSAL::isa($args->{fields}, 'HASH');

	my $self = {};
	bless $self, $parent;

	$self->Now($args->{now});
	$self->Action($args->{action});
	$self->Fields($args->{fields});

	return $self;
}

sub Fields
{
	my $self = shift;
	my $fields = shift;

	if(defined $fields && (UNIVERSAL::isa($fields, 'HASH')))
	{
		foreach my $field (keys %$fields)
		{
			$self->{_fields}->{$field} = $fields->{$field};
			$self->{_fields}->{$field} = uc $fields->{$field} if $fields->{$field} eq 'all';
		}
		$self->{_fields_loaded} = 1;
	}

	return $self->{_fields} || {};
}

sub Now
{
	my $self = shift;
	my $flag = shift;

	if(not defined $flag) { return $self->{_now}; }
	if($flag == 1) { $self->{_now} = 1; }
	elsif($flag == 0) { $self->{_now} = 0; }
	return $self->{_now};
}


sub Action
{
	my $self = shift;
	my $action = shift;

	if(defined $action && ($action =~ /^ALLOW$/i 
						|| $action =~ /^DENY$/i
						|| $action =~ /^PERMIT$/i
						|| $action =~ /^BLOCK$/i))
	{
		$self->{_action} = $action;
		return $self->{_action};
	}
	return $self->{_action};
}


sub Control 
{
	my $self = shift;
	my $args = shift;

	croak "Rule parameters not specified" if(!$self->{_fields_loaded});
	croak "Rule action is not set" if(!$self->Action());
	croak "Nothing to control" if(!$args);
	croak "Arguments to control() is not a hashref" if !UNIVERSAL::isa($args, 'HASH');

	# Applying our action...	
	# - Check if we are concerned
	# - If so, apply our action
	my $concern_status = $self->Concerned($args);

	print STDERR "Concerned -> $concern_status\n" if $self->DEBUG_LEVEL();

	#It's ours, apply.
	if($concern_status != ACL_RULE_UNCONCERNED)
	{		
		print STDERR "We are concerned, action is '". $self->Action()."'\n" if $self->DEBUG_LEVEL();;
		return ACL_RULE_ALLOW if($self->Action() =~ /^ALLOW$/i 
							  || $self->Action() =~ /^PERMIT/i);
		return ACL_RULE_DENY if($self->Action() =~ /^DENY$/i
							 || $self->ACtion() =~ /^BLOCK$/i);
	}	
	
	return ACL_RULE_UNCONCERNED;
}
	
sub Concerned
{
	my $self = shift;
	my $args = shift;
	
	croak "No args to concern with" if (!$args);

	#Foreach field of this rule, check to see if we are concerned.
	foreach my $field (keys %{$self->Fields()})
	{
		my $field_value = $self->Fields()->{$field};
		print STDERR "$field control (".$field_value.")->" if $self->DEBUG_LEVEL();;
	
		return ACL_RULE_UNCONCERNED if(
						$field_value ne $args->{$field}
						&& $field_value
						&& $field_value ne 'ALL'
						&& $args->{$field} ne 'ALL'
						&& $args->{$field});
		print STDERR " 1\n" if $self->DEBUG_LEVEL();;
	}

	return ACL_RULE_CONCERNED;
}

666;
