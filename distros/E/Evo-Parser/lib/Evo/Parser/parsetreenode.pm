### parse tree node of the GA lexer system

sub new {
	### $s is the syntax of a parse tree node
	my ($class, $s) = shift;

	$self = { str => $s, children => (), nchildren => 0, };

	bless $self, $class;
}

sub add_child_node {
	### noderef is a constructed node as a reference
	my ($self, $noderef) = @_;

	push(${$noderef}, $self->{children});
	$self->{nichildren}++;
}

### returns a node reference
sub search_in_node {
	my ($self, $stringdata) = @_;

	for (my $i = 0; $i < length($self->{children}); $i++) {

		if ($self->{children}[$i]->str == $self->{str}) {
			return \$self->{children}[$i];
		}

	}

	return undef;	
}

1;
