package Lingua::Align;

use 5.005;
use strict;

use vars qw($VERSION @ISA);
@ISA = qw();
$VERSION = '0.04';

sub new{
    my $class=shift;
    my %attr=@_;

    my $self={};
    bless $self,$class;

    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }

    return $self;
}

sub set_attr{
    my $self=shift;

    my %attr=@_;
    foreach (keys %attr){
	$self->{$_}=$attr{$_};
    }
}

sub align{}


sub store_features_used{
    my $self=shift;
    my ($model,$features)=@_;
    my $file=$model.'.feat';
    if (open F,">$file"){
	print F $features,"\n";
	close F;
    }
}

sub get_features_used{
    my $self=shift;
    my ($model)=@_;
    my $file=$model.'.feat';
    if (open F,"<$file"){
	my $features = <F>;
	chomp $features;
	close F;
	return $features;
    }
    return undef;
}



1;
__END__

=head1 NAME

Lingua::Align - Perl modules for the alignment of parallel corpora

=head1 SYNOPSIS

  # 1) train a tree aligner model on 100 sentences from train.xml
  #    and align the following 50 sentences and 
  #    store the result in align.xml
  # 2) evaluate the automatic alignment using the 
  #    gold standard links in train.xml
  
  treealign -n 100 -e 50 -f moses:catpos -a train.xml > align.xml
  treealigneval train.xml align.xml

=head1 DESCRIPTION

Lingua::Align contains modules for automatic tree alignment based on discriminative classification and alignment inference. More details about the tree aligner can be found in L<Lingua::Align::Trees>. The following gives a general overview and motivation of the problem of tree alignment.

=head2 What is tree alignment?

Lingua::Aligner is implemented to align syntactic parse trees to each other. It creates links between (hopefully corresponding) nodes in a source language tree and nodes in a target language tree. A tree can be represented in various formats, for example the famous Penn Treebank format:

 (NP 
   (DT THE)(NNP GARDEN)
   (PP (IN OF)
       (NP (NNP EDEN))))

Another common format is TigerXML which is used as the default treebank format in Lingua::Align (Penn Treebank format is supported as well):

 <s id="s1">
 <graph root="s1_502">
 <terminals>
  <t id="s1_1" word="THE" pos="DT" morph="--"/>
  <t id="s1_2" word="GARDEN" pos="NNP" morph="--"/>
  <t id="s1_3" word="OF" pos="IN" morph="--"/>
  <t id="s1_4" word="EDEN" pos="NNP" morph="--"/>
 </terminals>
 <nonterminals>
  <nt id="s1_500" cat="NP">
   <edge label="--" idref="s1_4"/>
  </nt>
  <nt id="s1_501" cat="PP">
   <edge label="--" idref="s1_3"/>
   <edge label="--" idref="s1_500"/>
  </nt>
  <nt id="s1_502" cat="NP">
   <edge label="--" idref="s1_1"/>
   <edge label="--" idref="s1_2"/>
   <edge label="LOC" idref="s1_501"/>
  </nt>
 </nonterminals>
 </graph>
 </s>

The alignment is guided by a discriminative binary classifier that provides link likelihoods between arbitrary node pairs based on features connected with these nodes. This classifier requires training data in form of correctly aligned trees to train its parameters. Features can be any kind of tree attributes at each node and its context. Tree alignments are stored as links between nodes. The default format in Lingua::Align is a format that we will call STA (Stockholm Tree Aligner format). Here is an example:

 <?xml version="1.0" encoding="UTF-8"?>
 ...
 <treebanks>
   <treebank id="en" language="en_US" filename="smultron_en_sophie.xml"/>
   <treebank id="sv" language="sv_SE" filename="smultron_sv_sophie.xml"/>
 </treebanks>
 ...
 <alignments>
  <align type="good">
    <node treebank_id="en" node_id="s1_3"/>
    <node treebank_id="sv" node_id="s1_1"/>
  </align>
  <align type="good">
    <node treebank_id="en" node_id="s1_4"/>
    <node treebank_id="sv" node_id="s1_1"/>
  </align>
  <align type="good">
    <node treebank_id="en" node_id="s1_502"/>
    <node treebank_id="sv" node_id="s1_500"/>
  </align>
  ...

The classifier learns from these aligned examples how likely it is to link certain nodes in arbitrary trees. For this we use a feature representation of nodes and a log-linear combination of so-called feature functions (features mapping to real values). Feature functions can be binary, for example 

 f_catlabel(a=1,NP,NP) = 1
 f_catlabel(a=1,NP,PP) = 0

which means that two aligned nodes (a=1) have the category labels source-node=NP and target-node=NP (but not the category labels source-node=NP and target-node=PP). Other feature functions may map to real values such as

 f_lcsr(a=1,EDEN,EDENS) = 4/5

which refers to the longest common subsequence ratio (LCSR) between the two linked terminal nodes "EDEN" and "EDENS". Feature types have to be specified before training the classifier. The same features will then be used whan aligning unseen data. For more information on feature types suported by Lingua::Align please look at L<Lingua::Align::Features>.

After classification (each possible node pair) the aligner may use various inference strategies (link search) to perform the actual alignment. Certain restrictions and constraints can be added to guide the aligner. For example, one may use a greedy search strategy to restrict the alignment result to one-to-one links. Furthermore, structural dependencies in the output space (tree alignment) can be added by using history features in classification (previous alignment decisions).


=head2 What do I need to run the aligner?

First of all you need a sentence aligned parallel corpus. Both sides have to be parsed and parse trees have to be stored in one of the supported formats (TigerXML, Penn Treebank format, AlpinoXML).

Secondly, you need training data for training the local classifier. Usually a small number of aligned parse trees is sufficient (around 200) to obtain reasonable results. Training data is not available for many language pairs. If you need to (manually) create training corpora you may want to look at the Stockholm Tree Aligner (L<http://kitt.cl.uzh.ch/kitt/treealigner>). The format produced by this tool can directly been used by Lingua::Align (see above for an example).

Thirdly, you may need to run automatic word alignment that is needed for some of the tree alignment features. There is a number of word alignment features (gizae2f, gizaf2e, moses) and lexical features based on word alignment (inside, outside) which are usually very important for tree alignment. You can use standard tools such as Giza++ and Moses for producing these word alignments (http://statmt.org/moses/). Note that you probably want to run on larger corpora than your small tree-aligned training data to get reliable word alignments (and lexical translation probabilities).

Finally you need to specify the features to be used in tree alignment. There is a lot of possibilities and you can combine features in various ways also using contextual nodes. For more information on feature types look at L<Lingua::Align::Features>.

Look at the examples in C<Lingua/Align/smultron> and C<Lingua/Align/europarl> to see some settings that can be used.


=head2 How can I improve the alignment performance?

There are two basic things that can be done to improve alignment performance:

1. Increase the amount of training data. More data is always better for data-driven approaches like this one. Manually aligning is no fun but every additional example gives the classifier more evidence to rely on.

2. Optimize the set of features. Feature engineering is very important in descriminative classification. Try to experiment with various feature sets and feature combinations. Lot's of contextual features can be useful also to implicitely capture the structural nature of the tree alignment task. Remember, that negative features can also be very useful. They will get negative weights and may help the classifier to make the right decisions.


=head2 What can I do with the aligned treebanks?

Good question. Do whatever you like to do with it. You can use these treebanks to extract translation data for (syntax-driven) machine translation. You can use them to explore cross-lingual language diversities. You may extract bilingual phrase dictionaries. Let me know if you have found another good example for using parallel aligned treebanks.


=head1 SEE ALSO

L<treealign> (tree aligner front-end),
L<treealigneval> (tree alignment evaluation script),
L<sta2phrases> (conversion from tree alignments to phrase pairs),
L<Lingua::Align::Trees> (tree aligner module),
L<Lingua::Align::Features> (feature extraction module),
L<Lingua::Align::Corpus> (top-level module for corpus data I/O)

=head1 AUTHOR

Joerg Tiedemann

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joerg Tiedemann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
