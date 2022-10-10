sub new {
	### an Action is based around 2 entities and has several
	### hitting functors, one one which entity1 is hit and another
	### on which it is hit
	### entity2 is on which you hit with entity1

	### NOTE that both actions can be at the same time to care 
	### for defense, god mode etc. Actions' functors can e.g. use 
	### the Metropolis algorithm in this codebase wrapped in the functor.

	my ($class, $entity1, $entity2, $hitf, $tohitf) = @_;

	$self = { playerentity => $entity1, adversaryentity => $entity2,
		hitmethod => $hitf, tohitmethod => $tohitf, };

	bless $self, $class;
};

1;
