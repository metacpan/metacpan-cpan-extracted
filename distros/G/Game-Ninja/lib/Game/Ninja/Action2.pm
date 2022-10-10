sub new {
	### This Action uses 2 other Actions such as HitAction, HittedAction
	### instead of functors as in Action.pm

	### NOTE that both actions can be at the same time to care 
	### for defense, god mode etc. Actions' functors can e.g. use 
	### the Metropolis algorithm in this codebase.

	### hitaction is what you hit with and hittedaction is the action
	### on which you get hit

	my ($class, $entity1, $entity2, $hitaction, $hittedaction) = @_;

	$self = { playerentity => $entity1, adversaryentity => $entity2,
		hitaction => $hitaction, hittedaction => $hittedaction, };

	bless $self, $class;
};

1;
