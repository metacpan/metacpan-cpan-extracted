package Decision::ACL;

use strict;
use Carp;
use vars qw($VERSION);
$VERSION = '0.02';

use Decision::ACL::Constants qw(:rule);
use Decision::ACL::Rule;

use constant AUTO_DENY_NOW => 1;
use constant DIE_ON_MALFORMED_RULES => 1;
use constant DEBUG_LEVEL => 0;

sub new
{
	my ($classname, $args) = @_;

	my $self = {
			rules => [],
		};

	bless $self, $classname;

	return $self;
}

sub ControlFields
{
	my $self = shift;
	
	return $self->{control_fields};
}

sub PushRule
{
	my $self = shift;
	my $rule = shift;

	if(defined $rule)
	{
		if(UNIVERSAL::isa($rule, 'Decision::ACL::Rule'))
		{
			return push(@{$self->{rules}}, $rule) if $self->_VerifyRuleFields($rule);
		}
		else
		{
			croak "Attempt to push an object that !ISA Decision::ACL::Rule\n";
		}
	}
}

sub PopRule
{
	my $self = shift;
	return pop(@{$self->{rules}});
}

sub ShiftRule
{
	my $self = shift;
	return shift(@{$self->Rules()});
}

sub UnshiftRule
{
	my $self = shift;
	return unshift(@{$self->Rules()});
}


sub Rules
{
	my $self = shift;

	return $self->{rules};
}

sub RunACL
{
	my $self = shift;
	my $args = shift;

	$self->_VerifyControlArgs($args);
	
	my $rules = $self->Rules();

	my $allowed = 0;

	my $rule_count = 0;
	foreach my $rule (@$rules)
	{
		next if not defined $rule;
		$rule_count++;

		print STDERR "Asking rule $rule_count about: ".(join ',', map { "$_=".$args->{$_} } (keys %$args))."\n" if $self->DEBUG_LEVEL();

		my $rule_status = $rule->Control($args);

		print STDERR "Rule says -> $rule_status\n" if $self->DEBUG_LEVEL();
		next if($rule_status == ACL_RULE_UNCONCERNED);

		if($rule_status == ACL_RULE_ALLOW)	
		{
			$allowed++;
		}

		if($self->AUTO_DENY_NOW() && $rule_status == ACL_RULE_DENY)
		{
			print STDERR "Rule will auto deny now.\n" if $self->DEBUG_LEVEL();
			return ACL_RULE_DENY if($self->AUTO_DENY_NOW());
		}

		if($rule->Now() == 1)
		{
			print STDERR "Rule needs to act now.\n" if $self->DEBUG_LEVEL();
			return $rule_status;
		}	

	}

	if($allowed) { return ACL_RULE_ALLOW; }

	print STDERR "Denying by default.\n" if $self->DEBUG_LEVEL();
	return ACL_RULE_DENY;
}

sub _VerifyControlArgs
{
	my $self = shift;
	my $args = shift;

	foreach my $control_field (@{ $self->ControlFields() })	
	{
		next if $args->{$control_field};
		croak "Cannot run ACL, missing control field in arguments to RunACL() ($control_field)\n";
	}
	return 1;
}


sub _VerifyRuleFields
{
	my $self = shift;
	my $rule = shift;

	if($self->{_fields_loaded})
	{
		foreach my $field (@{ $self->ControlFields() })
		{
			next if exists $rule->Fields()->{$field};
			if($self->DIE_ON_MALFORMED_RULES())
			{	
				croak "Rule format does not match loaded control fields.\n";
			}
			return 0;
		}
	}
	else
	{
		my $control_fields = [];
		foreach my $field (keys %{ $rule->Fields() })
		{	
			push(@$control_fields, $field);
		}
		$self->{control_fields} = $control_fields;
		$self->{_fields_loaded} = 1;
	}
	return 1;
}	


666;	
__END__
