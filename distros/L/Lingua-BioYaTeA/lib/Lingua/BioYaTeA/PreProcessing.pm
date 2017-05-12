package Lingua::BioYaTeA::PreProcessing;

use strict;
use warnings;
use utf8;

use Lingua::YaTeA::Corpus;

# use Data::Dumper;

=encoding utf8

=head1 NAME

Lingua::BioYaTeA::PreProcessing - Perl extension for preprocessing BioYaTeA input.

=head1 SYNOPSIS

use Lingua::BioYaTeA::PreProcessing;

$preProc = Lingua::BioYaTeA::PreProcessing->new();
open($fh, ">t/example_output_preprocessing-new.ttg") or ($fh = *STDERR);
$preProc->process_file("t/example_input_preprocessing.ttg", $fh);
close($fh);

=head1 DESCRIPTION


The module implements an extension for the pre-processing of the
TreeTagger output in order to improve the extraction of both terms
containing prepositional phrases (with C<TO> and C<AT> prepositions) and
terms containing participles (past participles C<-ED> and gerunds C<-ING>).

Context-based rules are applied to the POS tags either to trigger the
extraction of relevant structures or to prevent the extraction of
irrelevant ones. The modified file becomes a new input file for
BioYaTeA.

The input and output files are in the TreeTagger format.

=head1 METHODS

=head2 new()

    new();

The method creates a pre-processing component of BioYaTeA and loads
the additional resources (stop verbs, stop participles, stop words)
the rewritting patrerns (all are currently hardcoded), and returns the
created object.

The pre-processing object is defined with 4 attributes: the list of
stop verbs C<stopVerbs>, the list of stop participles
C<stopParticiples>, the list of stop words C<stoplist> and the list of
rewritting patterns C<patterns>.

=head2 getStopVerbs()

    getStopVerbs($form);

This method returns the attribute C<stopVerbs> or the specific value
associated to form C<$form>.

=head2 existsInStopVerbs()

    existsInStopVerbs($form);

This method indicates if the form C<$form> exists in the list of stop
verbs (C<stopVerbs> attribute).

=head2 loadStopVerbs()

    loadStopVerbs($form);

This method loads the list of stop verbs in the attribute
C<stopVerbs> and returns the attribute.

=head2 getStopParticiples()

    getStopParticiples($form);

This method returns the attribute C<stopParticiples> or the specific value
associated to form C<$form>.

=head2 existsInStopParticiples()

    existsInStopParticiples($form);

This method indicates if the form C<$form> exists in the list of stop
participles (C<stopParticiples> attribute).

=head2 loadStopParticiples()

    loadStopParticiples($form);

This method loads the list of stop participles in the attribute
C<stopParticiples> and returns the attribute.


=head2 getStopList()

    getStopList($form);

This method returns the attribute C<stopList> or the specific value
associated to form C<$form>.

=head2 existsInStopList()

    existsInStopList($form);

This method indicates if the form C<$form> exists in the list of stop
words (C<stopList> attribute).

=head2 loadStopList()

    loadStopList($form);

This method loads the list of stop words in the attribute
C<stopList> and returns the attribute.


=head2 compile1()

    compile1($pattern, $result);

This method performs the first step of the compilation of the pattern
C<$pattern> by generating the related regular expression and creating
the related pattern structure. This structure is composed 4 fields:
the pattern itself (C<root>), the array of predicates (C<predicates>),
the array of named groups (C<namedgroup>) and the regular expression.
The array of predicates are functions which will be used for
checking the Part-of-speech tags or the form of the words.


The second argument is not set at the fist call.
The method returns the resulting structure (an array reference).

=head2 compile2()

    compile2($result, $child_pattern);

This method performs the second step of the compilation of the
patterns. Patterns have been already processed by the method
C<compile1> and represented in the structure C<$result>. This step
generates the regular expression (field C<re>).

The second argument is not set at the fist call.

=head2 compile()

    compile($pattern);

This method compiles the pattern C<$pattern> in order to have the
relevant represenation and the corresponding regular expression into a
array structure C<$result>. This structure is returned.

=head2 translate()

    translate($compiledpattern, $sequence);

This method applies the compiled pattern (C<$compiledpattern>) to the
sequence C<sequence> into a string and return it. The string provides
information associated to various elements of the pattern (it depends
on the pattern).

=head2 match()

    match($compiledpattern, $sequence);

This method applies the pattern C<$compiledpattern> to the token
sequence C<$sequence> and merges the information in order to correct
the part-of-speech tag associated to some words. Any rewriting
operation is recorded in a array which is returned.

=head2 pred()

    pred($predicate, $quantifier);

The method returns the structure defining a predicate. The structure
is composed of 3 fields: the type of structure (here "C<predicate>"),
the function associated to the predicate (field C<predicate>) and is
set with C<$predicate>), and the quantifier associated to the
predicate (field C<quantifier>) which is set with C<$quantifier>.

=head2 group()

    group($children, $quantifier);

This method returns the structure defining a group of predicates. The
structure is composed of 3 fields: the type of structure (here
"C<group>"), the list of predicates (field C<children>) and is set
with C<$children>), and the quantifier associated to the child list
(field C<quantifier>) which is set with C<$quantifier>.

=head2 named()

    named($name, $children, $quantifier);

This method returns the structure defining a named group of
predicates. The structure is composed of 4 fields: the type of
structure (here "C<group>"), the name associated to the group (field
C<name>) which is set with C<$name>, the list of predicates (field
C<children>) and is set with C<$children>), and the quantifier
associated to the child list (field C<quantifier>) which is set with
C<$quantifier>.


=head2 is_ing()

    is_ing($word);

This method indicates if the word terminates by C<ing> and is not in
the list of stop words.
o
=head2 patterns()

    patterns();

This method returns the list of patterns associated to the current
object (field C<patterns>).

=head2 setPattern1()

    setPattern1();

This method sets the pattern 1.

=head2 getPattern1()

    getPattern1();

This method returns the pattern 1.

=head2 setPattern2()

    setPattern2();

This method sets the pattern 2.

=head2 getPattern2()

    getPattern2();

This method returns the pattern 2.

=head2 setPattern3()

    setPattern3();

This method sets the pattern 3.

=head2 getPattern3()

    getPattern3();

This method returns the pattern 3.

=head2 setPattern4()

    setPattern4();

This method sets the pattern 4.

=head2 getPattern4()

    getPattern4();

This method returns the pattern 4.

=head2 setPattern5()

    setPattern5();

This method sets the pattern 5.

=head2 getPattern5()

    getPattern5();

This method returns the pattern 5.

=head2 setPattern6()

    setPattern6();

This method sets the pattern 6.

=head2 getPattern6()

    getPattern6();

This method returns the pattern 6.

=head2 setPattern7()

    setPattern7();

This method sets the pattern 7.

=head2 getPattern7()

    getPattern7();

This method returns the pattern 7.

=head2 setPattern8()

    setPattern8();

This method sets the pattern 8.

=head2 getPattern8()

    getPattern8();

This method returns the pattern 8.

=head2 setPattern9()

    setPattern9();

This method sets the pattern 9.

=head2 getPattern9()

    getPattern9();

This method returns the pattern 9.

=head2 setPattern10()

    setPattern10();

This method sets the pattern 10.

=head2 getPattern10()

    getPattern10();

This method returns the pattern 10.

=head2 not_sent()

    not_sent($element);

This method indicates whether the part-of-speech of element
C<$element> is a mark of sentence end.

=head2 is_to()

    is_to($element);

This method indicates whether the form of element
C<$element> is the preposition C<to>.

=head2 process_sentence()

    process_sentence($sentence, $fh);

This method processes the sentence C<$sentence> in order to correct
the part-of-speech tags if necessary, and print the corrected sentence
in the file handle C<$fh> (the output respects the TreeTagger format).

=head2 process_file()

    process_file($file, $fhout);

The method performs the correction process on the file
C<$file>. The output will be printed in the file handle C<$fhout>.
C<$file> is the filename of the file to process.

=head1 SEE ALSO

Documentation of Lingua::BioYaTeA and Lingua::YaTeA

=head1 AUTHORS

Wiktoria Golik <wiktoria.golik@jouy.inra.fr>, Zorana Ratkovic <Zorana.Ratkovic@jouy.inra.fr>, Robert Bossy <Robert.Bossy@jouy.inra.fr>, Claire Nédellec <claire.nedellec@jouy.inra.fr>, Thierry Hamon <thierry.hamon@univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2012 Wiktoria Golik, Zorana Ratkovic, Robert Bossy, Claire Nédellec and Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

our $VERSION='0.1';

sub new {
    my ($class, ) = @_;

    my $this = {
	'stopVerbs' => undef,
	'stopParticiples' => undef,
	'stopList' => undef,
	'patterns' => [],
    };

    bless $this, $class;

    $this->loadStopVerbs;
    $this->loadStopParticiples;
    $this->loadStopList;

    $this->setPattern1;
    $this->setPattern2;
    $this->setPattern3;
    $this->setPattern4;
    $this->setPattern5;
    $this->setPattern6;
    $this->setPattern7;
    $this->setPattern8;
    $this->setPattern9;
    $this->setPattern10;

    return($this);
}

sub getStopVerbs {
    my ($self, $form)= @_;
    
    if (defined $form) {
	return($self->{'stopVerbs'}->{$form});
    }

    return($self->{'stopVerbs'});
}

sub existsInStopVerbs {
    my ($self, $form)= @_;
    
    return(exists($self->getStopVerbs->{$form}));
}


sub loadStopVerbs {
    my ($self, )= @_;

    if (!defined $self->{'stopVerbs'}) {
	$self->{'stopVerbs'} = {
	    'be' => 1,
	    'became' => 1,
	    'bind' => 1,
	    'find' => 1,
	    'gain' => 1,
	    'grow' => 1,
	    'inhibit' => 1,
	    'isolate' => 1,
	    'keep' => 1,
	    'live' => 1,
	    'oxidize' => 1,
	    'see' => 1,
	    'swim' => 1,
	    'synthesize' => 1
	};
    }

    return($self->{'stopVerbs'});
}

sub getStopParticiples {
    my ($self, $form)= @_;

    if (defined $form) {
	return($self->{'stopParticiples'}->{$form});
    }

    return($self->{'stopParticiples'});
}

sub existsInStopParticiples {
    my ($self, $form)= @_;

    return(exists($self->getStopParticiples->{$form}));
}

sub loadStopParticiples {
    my ($self, )= @_;

    if (!defined $self->{'stopParticiples'}) {
	$self->{'stopParticiples'} = {
	    'attached' => 1,
	    'bound' => 1,
	    'designed' => 1,
	    'exposed' => 1,
	    'intended' => 1,
	    'known' => 1,
		       'related' => 1
	};
    }
    return($self->{'stopParticiples'});
}

sub getStopList {
    my ($self, $form)= @_;

    if (defined $form) {
	return($self->{'stopList'}->{$form});
    }

    return($self->{'stopList'});
}

sub existsInStopList {
    my ($self, $form)= @_;

    return(exists($self->getStopList->{$form}));
}

sub loadStopList {
    my ($self, )= @_;

    if (!defined $self->{'stopList'}) {
	$self->{'stopList'} = {
	    'being' => 1,
	    'collecting' => 1,
	    'concerning' => 1,
	    'considering' => 1,
	    'containing' => 1,
	    'dividing' => 1,
	    'during' => 1,
	    'enhancing' => 1,
	    'excluding' => 1,
	    'getting' => 1,
	    'having' => 1,
	    'including' => 1,
	    'indicating' => 1,
	    'involving' => 1,
	    'leaving' => 1,
	    'using' => 1
	};
    }
    return($self->{'stopList'});
}

sub compile1 {
    my ($self, $clause, $result) = @_;

    my $type;
    if (!(defined $result)) {
	$result = {
	    'root' => $clause,
	    'predicates' => [],
	    'namedgroups' => [],
	    're' => ''
	};
    }

    $type = $clause->{'type'};
    if ($type eq 'predicate') {
	$clause->{'predindex'} = scalar @{$result->{'predicates'}};
	push @{$result->{'predicates'}}, $clause;
    }
    elsif ($type eq 'group') {
	if (exists $clause->{'name'}) {
	    $clause->{'nameindex'} = scalar @{$result->{'namedgroups'}};
	    push @{$result->{'namedgroups'}}, $clause->{'name'};
	}
	for my $child (@{$clause->{'children'}}) {
	    $self->compile1($child, $result);
	}
    }
    return $result;
}

# my $TRUE = 'Y';

sub _TRUE {
    my ($self) = @_;

    return('Y');
}

# my $TOK = '_';

sub _TOK {
    my ($self) = @_;

    return('_');
}

# my $FALSE = 'n';

sub _FALSE {
    my ($self) = @_;

    return('n');
}

sub compile2 {
    my ($self, $compiled, $clause) = @_;

    my $type;

    if (!(defined $clause)) {
	$clause = $compiled->{'root'};
	$compiled->{'re'} = '';
    }

    $type = $clause->{'type'};
    if ($type eq 'predicate') {
	my @preds = @{$compiled->{'predicates'}};
	my $lenm1 = scalar @preds - 1;
	my $index = $clause->{'predindex'};
	$compiled->{'re'} .= $self->_TOK . ('.'x$index) . $self->_TRUE . ('.'x($lenm1 - $index));
    }
    elsif ($type eq 'group') {
	if (exists $clause->{'name'}) {
	    $compiled->{'re'} .= '(';
	}
	else {
	    $compiled->{'re'} .= '(?:';
	}
	for my $child (@{$clause->{'children'}}) {
	    $self->compile2($compiled, $child);
	}
	$compiled->{'re'} .= ')';	
    }
    $compiled->{'re'} .= $clause->{'quantifier'};
}

sub compile {
    my ($self, $pattern) = @_;

    my $result = $self->compile1($pattern);
    $self->compile2($result);

    return $result;
}

sub translate {
    my ($self, $compiled, $sequence) = @_;

    my $result = '';
    # print STDERR "compiled/translate: " . Dumper($compiled) . "\n";
    if (defined $compiled) {
	my @preds = @{$compiled->{'predicates'}};
	for my $item (@$sequence) {
	    $result .= $self->_TOK;
	    for my $p (@preds) {
		if (&{$p->{'predicate'}}($self,$item)) {
		    $result .= $self->_TRUE;
		}
		else {
		    $result .= $self->_FALSE;
		}
	    }
	}
    }
    # warn "Result: $result\n";
    return $result;
}

sub match {
    my ($self, $compiled, $sequence) = @_;

    my @result = ();
    # print STDERR "compiled/match: " . Dumper($compiled) . "\n";

    if (defined $compiled) {
	my $translated = $self->translate($compiled, $sequence);
	my $re = $compiled->{'re'};
	my $len = 1 + scalar @{$compiled->{'predicates'}};
	while ($translated =~ /$re/g) {
	    my %m = ( '' => [$-[0]/$len, $+[0]/$len] );
	    my $i = 1;
	    for my $n (@{$compiled->{'namedgroups'}}) {
		my $pos = [ $-[$i]/$len, $+[$i]/$len ];
		$m{$n} = $pos;
		$i++;
	    }
	    push @result, \%m;
	}
    }
    # warn "ARRAY(result): " . join("/", @result) . "\n";
    return \@result;
}


sub pred {
    my ($self, $predicate, $quantifier) = @_;

    if (!(defined $quantifier)) {
	$quantifier = '';
    }
    return {
	'type' => 'predicate',
	'predicate' => $predicate,
	'quantifier' => $quantifier
    };
}

sub group {
    my ($self, $children, $quantifier) = @_;

    if (!(defined $quantifier)) {
	$quantifier = '';
    }
    return {
	'type' => 'group',
	'children' => $children,
	'quantifier' => $quantifier
    };
}

sub named {
    my ($self, $name, $children, $quantifier) = @_;

    if (!(defined $quantifier)) {
	$quantifier = '';
    }
    return {
	'type' => 'group',
	'name' => $name,
	'children' => $children,
	'quantifier' => $quantifier
    };
}

sub is_ing {
    my ($self, $w) = @_;

    my $form = $w->{'form'};
    return ($form =~ /ing$/) && !($self->existsInStopList($form));
}

sub patterns {
    my ($self) = @_;

    return($self->{'patterns'});
}


sub setPattern1 {
    my ($self) = @_;
    
    $self->patterns->[0] = $self->compile(
	$self->group([
	    $self->pred(sub { my $pos = $_[1]->{'pos'}; return $pos eq 'DT' || $pos eq 'JJ' || $pos eq 'SENT'; }),
	    $self->group([$self->pred(sub { return $_[1]->{'pos'} eq 'JJ'; })], '*'),
	    $self->named('ing', [
		      $self->pred(\&is_ing)
		  ]),
	    $self->pred(sub { my $pos = $_[1]->{'pos'}; return $pos eq 'NN' || $pos eq 'NNS' || $pos eq 'NP' || $pos eq ','; }),
	      ])
	);
#    warn $self->patterns->[0] . "\n";
}

sub getPattern1 {
    my ($self) = @_;

    return($self->patterns->[0]);
}

sub setPattern2 {
    my ($self) = @_;
    
    $self->patterns->[1] = $self->compile(
    $self->group([
	$self->pred(sub { my $pos = $_[1]->{'pos'}; return $pos eq 'DT' || $pos eq 'JJ' || $pos eq 'SENT'; }),
	$self->group([$self->pred(sub { return $_[1]->{'pos'} eq 'JJ'; })], '*'),
	$self->named('ing', [
		  $self->pred(\&is_ing)
	      ]),
	$self->pred(sub { return $_[1]->{'pos'} eq 'JJ'; }),
	  ])
	);
}


sub getPattern2 {
    my ($self) = @_;

    return($self->patterns->[1]);
}


sub setPattern3 {
    my ($self) = @_;
    
    $self->patterns->[2] = $self->compile(
    $self->group([
	$self->pred(sub { return $_[1]->{'form'} eq 'of' }),
	$self->named('ing', [ $self->pred(\&is_ing) ]),
	$self->pred(sub { return $_[1]->{'pos'} =~ /^V/ || $_[1]->{'form'} eq ',' || $_[1]->{'form'} eq '.' })
		 ])
	);
}

sub getPattern3 {
    my ($self) = @_;

    return($self->patterns->[2]);
}

sub setPattern4 {
    my ($self) = @_;
    
    $self->patterns->[3] = $self->compile(
	$self->group([
	    $self->pred(sub { $_[1]->{'form'} eq 'of' }),
	    $self->named('ing', [ $self->pred(\&is_ing) ]),
	    $self->pred(sub { my $pos = $_[1]->{'pos'}; return $pos eq 'DT' || $pos eq 'JJ' || $pos eq 'PP' || $pos eq 'WDT' })	
		     ])
	);
}

sub getPattern4 {
    my ($self) = @_;

    return($self->patterns->[3]);
}


sub not_sent {
    my ($self, $element) = @_;

    return $element->{'pos'} ne 'SENT';
}

sub setPattern5 {
    my ($self) = @_;
    
    $self->patterns->[4] = $self->compile(
	$self->group([
	    $self->pred(sub { return $self->existsInStopVerbs($_[1]->{'lemma'}) }),
	    $self->group([$self->pred(\&not_sent)], '*'),
	    $self->named('at', [ $self->pred(sub { return $_[1]->{'form'} eq 'at' }) ])
		     ])
	);
}

sub getPattern5 {
    my ($self) = @_;

    return($self->patterns->[4]);
}



sub is_to {
    my ($self, $element) = @_;

    return $element->{'form'} eq 'to';
}

sub setPattern6 {
    my ($self) = @_;
    
    $self->patterns->[5] = $self->compile(
	$self->group([
	    $self->pred(sub { my $form = $_[1]->{'form'}; return $form eq 'from' || $form eq 'by' } ),
	    $self->group([$self->pred(\&not_sent)], '*'),
	    $self->named('to', [ $self->pred(\&is_to) ])
		     ])
	);
}

sub getPattern6 {
    my ($self) = @_;

    return($self->patterns->[5]);
}


sub setPattern7 {
    my ($self) = @_;
    
    $self->patterns->[6] = $self->compile(
	$self->group([
	    $self->pred(sub { return $_[1]->{'pos'} !~ /NN/; }),
	    $self->group([$self->pred(sub { return $_[1]->{'pos'} =~ /^V/; })], '*'),
	    $self->named('to', [ $self->pred(\&is_to) ])
		     ])
	);
}

sub getPattern7 {
    my ($self) = @_;

    return($self->patterns->[6]);
}


sub setPattern8 {
    my ($self) = @_;
    
    $self->patterns->[7] = $self->compile(
    $self->group([
	$self->pred(sub { my $pos = $_[1]->{'pos'}; return $pos =~ /^V/ && $pos ne 'VVN'; } ),
	$self->named('to', [$self->pred(\&is_to)])
	  ])
	);
}

sub getPattern8 {
    my ($self) = @_;

    return($self->patterns->[7]);
}


sub setPattern9 {
    my ($self) = @_;
    
    $self->patterns->[8] = $self->compile(
    $self->group([
	$self->pred(sub { return $_[1]->{'pos'} eq 'NN'; }),
	$self->pred(sub { return $_[1]->{'pos'} eq 'VVN' && !($self->existsInStopParticiples($_[1]->{'form'})) }),
	$self->named('to', [$self->pred(\&is_to)])
		 ])
	);
}

sub getPattern9 {
    my ($self) = @_;

    return($self->patterns->[8]);
}


sub setPattern10 {
    my ($self) = @_;
    
    $self->patterns->[9] = $self->compile(
	$self->group([
	    $self->named('ed', [$self->pred(sub { return $_[1]->{'form'} =~ /ed$/; })]),
	    $self->pred(sub { my $pos = $_[1]->{'pos'}; return $pos eq 'NN' || $pos eq 'NP' || $pos eq 'JJ' || $pos eq 'NNS'; })
		     ])
	);
}

sub getPattern10 {
    my ($self) = @_;

    return($self->patterns->[9]);
}


sub process_sentence {
    my ($self, $sentence, $fh) = @_;

    if (!defined $fh) {
	$fh = *STDOUT;
    }

    my $m;
    my $w;
    
    for $m (@{$self->match($self->getPattern1, $sentence)}) {
	$sentence->[$m->{'ing'}->[0]]->{'pos'} = 'NN';
    }

    for $m (@{$self->match($self->getPattern2, $sentence)}) {
	$sentence->[$m->{'ing'}->[0]]->{'pos'} = 'JJ';
    }

    for $m (@{$self->match($self->getPattern3, $sentence)}) {
	$sentence->[$m->{'ing'}->[0]]->{'pos'} = 'NN';
    }

    for $m (@{$self->match($self->getPattern4, $sentence)}) {
	$sentence->[$m->{'ing'}->[0]]->{'pos'} = 'VVG';
    }

    for $m (@{$self->match($self->getPattern5, $sentence)}) {
	$sentence->[$m->{'at'}->[0]]->{'pos'} = 'AT';
    }

    for $m (@{$self->match($self->getPattern6, $sentence)}) {
	$sentence->[$m->{'to'}->[0]]->{'pos'} = 'XXX';
    }

    for $m (@{$self->match($self->getPattern7, $sentence)}) {
	$sentence->[$m->{'to'}->[0]]->{'pos'} = 'XXX';
    }

    for $m (@{$self->match($self->getPattern8, $sentence)}) {
	$sentence->[$m->{'to'}->[0]]->{'pos'} = 'XXX';
    }

    for $m (@{$self->match($self->getPattern9, $sentence)}) {
	$sentence->[$m->{'to'}->[0]]->{'pos'} = 'XXX';
    }

    for $m (@{$self->match($self->getPattern10, $sentence)}) {
	$sentence->[$m->{'ed'}->[0]]->{'pos'} = 'JJ';
    }

    for $w (@$sentence) {
	print $fh $w->{'form'} . "\t" . $w->{'pos'} . "\t" . $w->{'lemma'} . "\n";
    }
}


sub process_file {
    my ($self, $file, $fhout) = @_;

    my $fhin = *STDIN;
    my $line;
    my $form;
    my $pos;
    my $lemma;

    my @sentence = ();
    if (defined $file) {
	open($fhin, $file) or die "No such file $file\"";
    } 
    while ($line = <$fhin>) {
#	warn ">$line";
	$line = &Lingua::YaTeA::Corpus::correctInputLine($line);
	# if ($@) {
	#     warn "no correction of the input lines\n";
	# }
	chomp $line;
	$form = undef;
	$pos = undef;
	$lemma = undef;
	if ($line !~ /^\s*$/o) {
	    ($form, $pos, $lemma) = split("\t", $line);
	    push @sentence, {'form'=>$form,'pos'=>$pos,'lemma'=>$lemma};
	    if ($pos eq 'SENT') {
		$self->process_sentence(\@sentence, $fhout);
		@sentence = ();
	    }
	}
    }
    if (scalar(@sentence) > 0) {
	$self->process_sentence(\@sentence, $fhout);
    }
    if (defined $file) {
	close($fhin);
    }
    return(1);
}

sub _printPatterns {
    my ($self, $fh) = @_;

    my $i;

    if (!defined $fh) {
	$fh = *STDOUT;
    }

    print $fh "Number of patterns: " . scalar(@{$self->patterns}) . "\n";
    for($i = 0; $i < scalar(@{$self->patterns}) ; $i++) {
    	print $fh join(':', %{$self->patterns->[$i]}) . "\n";
    	print $fh Dumper($self->patterns->[$i]) . "\n";
    }

}

1;
