### parse tree of the GA lexer system

sub new {
	my $class = shift;

	$self = { root => parsetreenode->new(""), };

	bless $self, $class;
}

sub parse {
	### NOTE : $lexerscans is lexerscans.pm instance
	my ($self, $lexerscans) = @_;

	my @scannedwords = $lexerscans->{scannedwords};
	my $root = $self->{root};

	### system for having no parent in the parsetreenode.pm itself	
	my @parentnodes = ($self->{root});
	my $parentnodecounter = 0;
	my $currentnode = $self->{root};

	for (my $i = 0; $i < length(@scannedwords); $i++) {

		my $word = @scannedwords[$i];

		### NOTE : hard-coded doables and {, } in the parse tree
		### as bracein and braceout
		if ($word == "bracein") {
			my $node = parsetreenode->new("bracein");
			push(@parentnodes, $currentnode);
			$parentnodecounter++;
			$currentnode = @parentnodes[$parentnodecounter-1];
			$currentnode->add_child_node(\$node); ### adds to $currentnode's children
			next;
		} 
		if ($word == "braceout") {
			my $node = parsetreenode->new("braceout");
			$currentnode->add_child_node(\$node); ### adds to $currentnode's children
			$currentnode = @parentnodes[--$parentnodecounter];
		}	

		if (defined($word)) { ### NOTE : must be string also

			my $node = parsetreenode->new($word);
			$currentnode->add_child_node(\$node);

		}

	}
}

1;
