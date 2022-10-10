sub new {
	my $class = @_;

	### This Entity class should be overridden so it can hit or be 
	### hit. An Action may use its hit functionality
	$self = { hit => 0, hitted => 0,
		hitmethod => $hitf, tohitmethod => $tohitf, };

	bless $self, $class;
};

1;

