package Evo::Inference::InferenceParser;

sub new {
	my ($class) = @_;

	my $self = {
		delimiter => Delimiter->new,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub parse {
	my ($self, $cond, @condargs) = @_;

	return $cond->solve(@condargs);	
}

sub grep_char {
	my ($self, $string, $idx) = @_;
	my $fwchar = FlyweightCharacter->new; 
	my $s = $string[$i];

	$fwclause->set($s);
	return $fwchar;
}

sub grep_clause {
	my ($self, $string, $index, $delimiter) = @_;
	my $fwclause = FlyweightClause->new; 
	my $s = "";

	$self->{delimiter} = $delimiter;

	for (my $i = $index->get; $self->{delimiter} != $string[$i]; $i++) {

		$s .= $string[$i];

	}

	$fwclause->set($s);
	return $fwclause;
}

1;
