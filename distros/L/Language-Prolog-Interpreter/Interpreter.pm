#! perl -w
package Language::Prolog::Interpreter;
our $VERSION = "0.021";

=head1 NAME

Prolog Interpreter alpha 0.02

=head1 SYNOPSIS

	Language::Prolog::Interpreter->readFile('E:/src/PROLOG/flamenco.pr');

or

	$a = <<'EOPROLOG';
	parent(john,sally).
	parent(john,joe).
	parent(mary,joe).
	parent(phil,beau).
	parent(jane,john).
	grandparent(X,Z) :-parent(X,Y),parent(Y,Z).
	EOPROLOG
	;
	while ($a) {
		eval 'Language::Prolog::Interpreter->readStatement(\$a)';
		$@ && die $@,$a,"\n";
		$a=~s/^\s*//;
	}

	# Above is same as
	# eval 'Language::Prolog::Interpreter->readFile($pathtomyfile)';

	$a = '?- grandparent(GPARENT,GCHILD).';
	print $a,"\n";
	$Q = Language::Prolog::Interpreter->readStatement(\$a);
	while($Q->query()) {
		print "found solutions\n";
		print 'GPARENT = ',$Q->variableResult('GPARENT'),"\n";
		print 'GCHILD = ',$Q->variableResult('GCHILD'),"\n\n";
	}
	print "no more solutions\n\n";

	$a = 'member(A,[A|_]).';
	$b = 'member(A,[_|B]) :- member(A,B).'; #Classic member
	Language::Prolog::Interpreter->readStatement(\$a);
	Language::Prolog::Interpreter->readStatement(\$b);

	$a = '?- member(c(V),[a(a),b(b),c(c),d(d),c(q)]).';
	print $a,"\n";
	$Q = Language::Prolog::Interpreter->readStatement(\$a);
	while($Q->query()) {
		print "found solutions\n";
		print 'V = ',$Q->variableResult('V'),"\n\n";
	}
	print "no more solutions\n\n";

=head1 DESCRIPTION

A simple interpreter which doesn't allow infix operators (except for C<:-> and C<,>, both of which are built in).

=head2 SYNTAX

There are three possible statements:

=over 4

=item 1. Clauses

A single B<clause> ending in a statement terminator (C<.>).

This gets added to the database.

=item 2. Rules

A single B<rule> ending in a statement terminator (C<.>).

This gets added to the store.

=item 3. Queries

The he B<query> characters C<?->, followed by a comma separated list of clauses, ending in a statement terminator (C<.>).

This creates and returns a query.

=item Comments

Multi-line comments are Java-like, taking the form C</** ... **/>.

Single-line/end-of-line comments are donnated by C<%>.

=item Whitespace

Whitespace is ignored everywhere except in single quoted atoms

=back

=cut


our $VARIABLE_REGEX = '[A-Z_]\w*';
our $SIMPLE_ATOM_REGEX = '[a-z]\w*';


sub readStatement { my($self,$string_ref) = @_;
	$$string_ref =~ s/^\s*//;
	return undef if $$string_ref eq '';
    my $statement;

    if ($$string_ref =~ s/^\?\-//) {
		return $self->readQuery($string_ref);
    } else {
		$statement = $self->readClauseOrRule($string_ref);
		$$string_ref =~ s/^\s*//;
		if ($$string_ref =~ s/^\.//) {
		    $statement->_addToStore();
		    return undef;
		} else {
		    die "Error - statement terminator is missing";
		}
    }
}

sub readQuery {
    my($self,$string_ref) = @_;
    my(@clauses,$variables);
    $variables = {};

    for(;;) {
		push(@clauses,$self->readClause($string_ref,$variables));
		if ($$string_ref =~ s/\s*\,//) {
		    next;
		} elsif ($$string_ref =~ s/\s*\.//) {
		    return Language::Prolog::Query->newQuery($variables,@clauses);
		} else {
		    die "Error - statement terminator is missing";
		}
    }
}


=head2 TERMS

Terms are:-

=item Lists1:

Comma separated lists of terms enclosed in square brackets

	e.g [Term1,Term2]

=item Lists2:

As List1, but final term is a variable separated by a '|'

	e.g [Term1,Term2|Variable]

=item Atoms1:

sequence of characters/digits/underscore (i.e C<\w> character class) starting with a lower case character.

	e.g. this_Is_An_Atom

=item Atoms1:

any sequence of characters enclosed in single quotes (')

	e.g. 'This is another atom!'

=item Variables:

sequence of characters/digits/underscore (i.e C<\w> character class) starting with an upper case character or underscore

	e.g. This_is_a_var, _and_this, _90

=item Clauses:

an Atom1 immediately followed by a left bracket, C<(>, followed by a comma separated list of terms, terminating in a right bracket.

	e.g clause(one), clause2(a,hello,'More !',[a,b,c])

=item Rules:

A Clause, followed by optional whitespace, followed by C<:->, followed by optional whitespace, followed by a list of clauses separated by commas.

=cut

sub readTerm {
    my($self,$string_ref,$variables) = @_;
    if(!defined($variables)) {$variables = {};}
    my($term);

    # Delete whitespace
    $$string_ref =~ s/\s*//;

    if ($$string_ref =~ m/^\[/) {
		$term = $self->readList($string_ref,$variables);
    } elsif ($$string_ref =~ s/^('[^']+')//) {           #'
        $term = Language::Prolog::Term->newAtom($1);
    } elsif ($$string_ref =~ m/^$SIMPLE_ATOM_REGEX\(/o) {
		$term = $self->readClauseOrRule($string_ref,$variables);
    } elsif ($$string_ref =~ s/^($SIMPLE_ATOM_REGEX)//o) {
		$term = Language::Prolog::Term->newAtom($1);
    } elsif ($$string_ref =~ s/^($VARIABLE_REGEX)//o) {
		$term = $self->variable($variables,$1);
    } else {
		die "Term not recognized";
    }

#    $$string_ref =~ s/^\s*\.// ||
#        die "Statement terminator (.) expected but not found";
    return $term;
}

sub variable {
    my($self,$variables,$string) = @_;
    my $new;
    $variables = {} if not defined($variables);
    if (!$variables->{$string}) {
		$new = Language::Prolog::Term->newVariable($string);
		$variables->{$string} = $new;
    } else {
		$new = Language::Prolog::Term->newVariable($string);
		$new->unify($variables->{$string}) ||
		die "Error - cannot specify variables to match recursively";
    }
    return $new;
}


sub readList {
    my($self,$string_ref,$variables) = @_;
    my(@terms);

    ($$string_ref =~ s/^\s*\[//) || die "Not a list";

    return Language::Prolog::Term->newList() if $$string_ref =~ s/^\s*\]//;

    for (;;) {
		$$string_ref =~ s/^\s*//;
		push(@terms,$self->readTerm($string_ref,$variables));
		if ($$string_ref =~ s/^\s*,//) {
			next;
		} elsif ($$string_ref =~ s/^\s*\]//) {
			return Language::Prolog::Term->newList(@terms);
		} elsif ($$string_ref =~ s/^\s*\|\s*($VARIABLE_REGEX)\s*\]//o) {
			return Language::Prolog::Term->newVarList(@terms,
				$self->variable($variables,$1));
		} else {
			die "Term not recognized";
		}
	}
}

sub readClauseOrRule {
    my($self,$string_ref,$variables) = @_;

    $variables = {} if not defined($variables);

    my $head = $self->readClause($string_ref,$variables);
    if ($$string_ref =~ s/^\s*:-//) {
	my(@tail);
	for (;;) {
	    $$string_ref =~ s/^\s*//;

	    push(@tail,$self->readClause($string_ref,$variables));

	    if ($$string_ref =~ s/^,//) {
			next;
	    } else {
			return Language::Prolog::Term->newRule($head,@tail);
	    }
	}
    } else {
		return $head;
    }
}

sub readClause {
    my($self,$string_ref,$variables) = @_;
    my(@terms);

	$$string_ref =~ s/^\s*//;

    if ($$string_ref =~ s/^($SIMPLE_ATOM_REGEX)\(//o) {
		push(@terms,Language::Prolog::Term->newAtom($1));
		for (;;) {
			$$string_ref =~ s/^\s*//;

			push(@terms,$self->readTerm($string_ref,$variables));

			if ($$string_ref =~ s/^\s*,//) {
				next;
			} elsif ($$string_ref =~ s/^\s*\)//) {
				return Language::Prolog::Term->newClause(@terms);
			} else {
				die "Term not recognized";
			}
		}
    } elsif ($$string_ref =~ s/^($SIMPLE_ATOM_REGEX)\b//o) {
		return Language::Prolog::Term->newClause(
			   Language::Prolog::Term->newAtom($1)
		);
    } else {
		warn "Not a clause:- \n>>\n$$string_ref\n<<";
		use Carp;
		confess;
    }
}


#
# This is one of Lee's subs.
#
sub readFile { my ($self,$path)=(shift,shift);
	die "readFile requires a file path to read from." if not defined $path;
	warn "No such file at <$path>" and return undef if not -e $path;

	open IN,$path or die "Couldn't open path <$path>:\n$!";
		@_ = <IN>;
	close IN;
	my $file = join "\n",@_;

	#
	# Strip comments
	#
	$file =~ s| \Q/**\E .*? \*?\Q*/\E ||sgx;	# Remove multiline comments. /**..**/ or /**..*/
	$file =~ s|\%.*?\n||g;						# Remove single-line comments
	$file =~ s|\n||sg;

	#
	# Make the file into lines of clauses (terminated with a full-stop) for processing.
	# Will not terminate with brackets [] or () or single-quotes, ''.
	# Any character escaped with \ is ignored.
	#
	my ($c,$q,$clauses);
	my @clauses;
	my $b=0;
	for (my $i=0; $i<length($file); $i++){
		my $c = substr($file,$i,1);					# Does this increase speed?
		if ($c eq '\\'){ $clauses .= $c; next }		# Don't set quote flag if escaped quote
		if ($c eq "'" ) { $q = not $q }				# Invert quote flag
		if ($c =~ /^[(\[]$/){ ++$b }				# Stack of open brackets
		if ($c =~ /^[)\]]$/){ --$b }				# Stack of closed brackets
		if ($c eq "." and not $q and $b==0) {
			$clauses .= "$c\n";						# Add \n to .
			push @clauses,$clauses;
			next;
		}
		$clauses .= $c;								# Store result
	}

	foreach (@clauses) {
		eval 'Language::Prolog::Interpreter->readStatement(\$file)';
		$@ && die $@,$file,"\n";
		$file=~s/^\s*//;
	}

}

1;

=head1 AUTHOR

Jack Shirazi.

Since Mr Shirzai seems to have vanished, updated by Lee Goddard <lgoddard@cpan.org> to support file parsing, single- and multi-line comments, and multi-ilne clauses.

=head1 COPYRIGHT

Copyright (C) 1995, Jack Shirazi. All Rights Reserved.

Updates Copyright (C) 2001, Lee Goddard.  All Rights Reserved.

Usage is under the same terms as for Perl itself.

=cut
