package Games::LatticeGenerator::ObjectDescribedByFacts;

use strict;
use warnings;
use AI::Prolog;
use Games::LatticeGenerator::ObjectWithName;
use Carp;
use Capture::Tiny ':all';
use base 'Games::LatticeGenerator::ObjectWithName';


=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new
{
	my $class = shift;
	my $this = $class->SUPER::new(@_);
	
	my $s = $class;
	$s =~ s/([\w]+::)+//;
	$$this{description} = <<DESCRIPTION;	
is_a_${s}($this).
DESCRIPTION

	return $this;
}

=head2 get_unique

Gets a list and returns it sorted and without duplicates.

=cut

sub get_unique
{
	my $this = shift;
	my %k;
	$k{$_} = 1 for @_;
	return sort keys %k;
}

=head2 get_description

=cut
sub get_description
{
	my $this = shift;
	croak "empty object" unless defined $this;
	return join("", $this->get_unique(map { "$_\n" } grep { $_ } sort split /\n/, $this->{description}));
}

our $common_knowledge = "";

=head2 get_solution

Uses Prolog to resolve print out all the variables satisfying the condition within the given knowledge (description).

=cut
sub get_solution
{
	my $this = shift;
	my $line = shift;
	my $original_code = $this->get_description();
	my $code = "";

	my $variable = shift;
	my $condition = shift;
	my $optional_context = shift;

	$optional_context = "" unless defined($optional_context);

	my $new_code = $original_code."\n".$optional_context;

	$code .= <<CODE;
$common_knowledge
$new_code
goal:- $condition, write($variable), nl, fail.
goal.
CODE

	my $p = AI::Prolog->new($code);
	
		
	my @result;
	
	if ($$this{debug})
	{
		@result = split /\n/, tee_stdout { $p->query("goal"); $p->results(); };
	}
	else
	{
		@result = split /\n/, capture_stdout { $p->query("goal"); $p->results(); };
	}
	return $this->get_unique(@result);		
}

=head2 get_solution_n

Uses Prolog to print out all the tuples of variables satisfying the condition.

=cut
sub get_solution_n
{
	my $this = shift;
	my $line = shift;
	my $original_code = $this->get_description();
	my $code = "";

	my $variables_ref = shift;
	my $condition = shift;
	my $optional_context = shift;

	$optional_context = "" unless defined($optional_context);

	my $new_code = $original_code."\n".$optional_context;

	my $write_the_variables = join(", write(' '), ", map { "write($_)" } @$variables_ref);

	$code .= <<CODE;
$common_knowledge
$new_code
goal:- $condition, $write_the_variables, nl, fail.
goal.
CODE
	
	my $p = AI::Prolog->new($code);

	my @result;
	
	if ($$this{debug})
	{
		@result = split /\n/, tee_stdout { $p->query("goal"); $p->results(); };
	}
	else
	{
		@result = split /\n/, capture_stdout { $p->query("goal"); $p->results(); };
	}

	return $this->get_unique(@result);
}

1;
