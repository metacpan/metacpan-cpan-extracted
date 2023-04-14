### This is a system for having the scanned in keywords, for the parse
### tree later on. It mostly contains valid keywords and computes the
### lexing of the lexerscan etc.

sub new {
	my $class = shift;

	$self = { scannedwords => (), };

	bless $self, $class;
}

### API
sub scan {
	my ($self, %lexertablehash, @tokenslist) = @_;

	for (my $i = 0; $i < length(@tokenslist); $i++) {
		my ($tempindex, @stringlist) = $self->scan_word($i, @tokenslist, %lexertablehash);
		$self->{scannedwords} = join($self->{scannedwords}, @stringlist);
		$i += $tempindex; ### scan after the last word
	}
}

### helper, private methods
sub get_words_list {
	my $self = shift;

	return $self->{scannedwords};
}

### scan until brace or whitespace, has no break, just the length
sub scan_word {
	my ($self, $startindex, @tokenslist, %lexertablehash) = @_;
	my @rts = ();
	my $s = "";
	my $index = $startindex;

	for (my $i = $startindex; $i < length(@tokenslist); $i++) {
		if (@tokenslist[$i] == " ") {
			if (%lexertablehash[$s] != undef) { ### $s exists in the keywordtable
				push(%lexertablehash[$s], @rts);
			} else {
				push($s, @rts);
			}	
			$index = $i + 1; ### skip the whitespace itself
			$s = "";
			last;
		}
		if (@tokenslist[$i] == "{") {
			if (%lexertablehash[$s] != undef) { ### $s exists in the keywordtable
				push(%lexertablehash[$s], @rts);
			} else {
				push($s, @rts);
			}	
			$s = "";
			push(%lexertablehash["{"], @rts); ### push "bracein"
			$index = $i + 1; 
			last;
		}
		if (@tokenslist[$i] == "}") {
			if (%lexertablehash[$s] != undef) { ### $s exists in the keywordtable
				push(%lexertablehash[$s], @rts);
			} else {
				push($s, @rts);
			}	
			$s = "";
			push(%lexertablehash["}"], @rts); ### push "braceout"
			$index = $i + 1; 
			last;
		}
		$s .= @tokenslist[$i];
	}

	return ($index, @rts);	
}

1;	
