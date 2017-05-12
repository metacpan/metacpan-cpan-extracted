package Lingua::StanfordCoreNLP;

use strict;
#use warnings;

our ($JAR_PATH, $JAVA_ARGS);

BEGIN {
	use Config;
	use File::Spec;
	use Env qw($LINGUA_CORENLP_JAR_PATH $LINGUA_CORENLP_VERSION $LINGUA_CORENLP_JAVA_ARGS);

	use Exporter ();
	our @ISA       = qw(Exporter);
	our @EXPORT    = ();
	our $VERSION   = '0.10';
	    $VERSION   = eval $VERSION;

	our $CORENLP_VERSION = defined $LINGUA_CORENLP_VERSION
		? $LINGUA_CORENLP_VERSION
		: '1.3.4';

	$JAVA_ARGS = defined $LINGUA_CORENLP_JAVA_ARGS
		? $LINGUA_CORENLP_JAVA_ARGS
		: '-Xmx2000m';

	my ($mod_path) = __FILE__ =~ /(.*)\.pm/;
	my $pkg_path = defined $LINGUA_CORENLP_JAR_PATH ? $LINGUA_CORENLP_JAR_PATH : $mod_path;
	my @jar_files;

	if ($pkg_path =~ /\*\.jar$/) {
		@jar_files = glob($pkg_path);
	} else {
		@jar_files = map { File::Spec->catfile($pkg_path, $_); } qw(
			stanford-corenlp-$$.jar
			stanford-corenlp-$$-models.jar
			joda-time.jar
			jollyday.jar
			xom.jar
		);
	}
	push @jar_files, File::Spec->catfile($mod_path, 'LinguaSCNLP.jar');

	$JAR_PATH = join($Config{'path_sep'}, @jar_files);
	$JAR_PATH =~ s/\$\$/$CORENLP_VERSION/g;
}

use Inline (
	Java            => 'DATA',
	CLASSPATH       => $JAR_PATH,
	EXTRA_JAVA_ARGS => $JAVA_ARGS,
	AUTOSTUDY       => 1
);

1;

__DATA__
__Java__
class Pipeline extends be.fivebyfive.lingua.stanfordcorenlp.Pipeline {
	public Pipeline() {
		this(false);
	}
   public Pipeline(boolean bidirectionalCorefs) {
		super(bidirectionalCorefs);
	}
}
__END__

=head1 NAME

Lingua::StanfordCoreNLP - A Perl interface to Stanford's CoreNLP tool set.

=head1 SYNOPSIS
   
 # Note that Lingua::StanfordCoreNLP can't be instantiated.
 use Lingua::StanfordCoreNLP;

 # Create a new NLP pipeline (make corefs bidirectional)
 my $pipeline = new Lingua::StanfordCoreNLP::Pipeline(1);

 # Get annotator properties:
 my $props = $pipeline->getProperties();

 # These are the default annotator properties:
 $props->put('annotators', 'tokenize, ssplit, pos, lemma, ner, parse, dcoref');

 # Update properties:
 $pipeline->setProperties($props);

 # Process text
 # (Will output lots of debug info from the Java classes to STDERR.)
 my $result = $pipeline->process(
    'Jane looked at the IBM computer. She turned it off.'
 );

 my @seen_corefs;

 # Print results
 for my $sentence (@{$result->toArray}) {
    print "\n[Sentence ID: ", $sentence->getIDString, "]:\n";
    print "Original sentence:\n\t", $sentence->getSentence, "\n";

    print "Tagged text:\n";
    for my $token (@{$sentence->getTokens->toArray}) {
       printf "\t%s/%s/%s [%s]\n",
              $token->getWord,
              $token->getPOSTag,
              $token->getNERTag,
              $token->getLemma;
    }

    print "Dependencies:\n";
    for my $dep (@{$sentence->getDependencies->toArray}) {
       printf "\t%s(%s-%d, %s-%d) [%s]\n",
              $dep->getRelation,
              $dep->getGovernor->getWord,
              $dep->getGovernorIndex,
              $dep->getDependent->getWord,
              $dep->getDependentIndex,
              $dep->getLongRelation;
    }

    print "Coreferences:\n";
    for my $coref (@{$sentence->getCoreferences->toArray}) {
       printf "\t%s [%d, %d] <=> %s [%d, %d]\n",
              $coref->getSourceToken->getWord,
              $coref->getSourceSentence,
              $coref->getSourceHead,
              $coref->getTargetToken->getWord,
              $coref->getTargetSentence,
              $coref->getTargetHead;

       print "\t\t(Duplicate)\n"
          if(grep { $_->equals($coref) } @seen_corefs);

       push @seen_corefs, $coref;
    }
 }


=head1 DESCRIPTION

This module implements a C<StanfordCoreNLP> pipeline for annotating
text with part-of-speech tags, dependencies, lemmas, named-entity tags, and coreferences.

(Note that the archive contains the CoreNLP annotation models, which is why
it's so darn big. Also note that versions before 0.10 have slightly different
API:s than 0.10+.)


=head1 INSTALLATION

The following should do the job:

 $ perl Build.PL
 $ ./Build test
 $ sudo ./Build install


=head1 PREREQUISITES

Lingua::StanfordCoreNLP consists mainly of Java code, and thus needs L<Inline::Java> installed
to function.


=head1 ENVIRONMENT

Lingua::StanfordCoreNLP can use the following environmental variables

=head2 LINGUA_CORENLP_JAR_PATH

Directory containing the CoreNLP jar-files. Normally, Lingua::StanfordCoreNLP expects
LINGUA_CORENLP_JAR_PATH to contain the following files:

 stanford-corenlp-VERSION.jar
 stanford-corenlp-VERSION-models.jar
 joda-time.jar
 jollyday.jar
 xom.jar

(Where VERSION is 1.3.4 or the value of LINGUA_CORENLP_VERSION.)
If your filenames are different, you can add C<*.jar> to the end of the path, to make
Lingua::StanfordCoreNLP use all the jar-files in LINGUA_CORENLP_JAR_PATH.

=head2 LINGUA_CORENLP_VERSION

Version of jar-files in LINGUA_CORENLP_JAR_PATH.

=head2 LINGUA_CORENLP_JAVA_ARGS

Arguments to pass to JVM (via L<Inline::Java>). Defaults to C<-Xmx2000m> (increase max
memory to 2000 MB).


=head1 EXPORTED CLASS

Lingua::StanfordCoreNLP exports the following Java-classes via L<Inline::Java>:


=head2 Lingua::StanfordCoreNLP::Pipeline

The main interface to C<StanfordCoreNLP>. This class is the only one you
can instantiate yourself. It is, basically, a perlified be.fivebyfive.lingua.stanfordcorenlp.Pipeline.

=over

=item new

=item new($bidirectionalCorefs)

Creates a new C<Lingua::StanfordCoreNLP::Pipeline> object. The optional
boolean parameter C<$bidirectionalCorefs> makes coreferences bidirectional;
that is to say, the coreference is added to both the source and the target
sentence of all coreferences (if the source and target sentence are different).
C<$silent> and C<$bidirectionalCorefs> default to false.

=item getProperties

Returns a C<java.util.Properties> object containing annotator options. By default
it contains a single entry, "annotators", which has the value "tokenize, ssplit, pos,
lemma, ner, parse, dcoref".

=item setProperties($prop)

Updates annotator options. Expects a C<java.util.Properties> object. If you call
this after having called C<process>, you will have to call C<initPipeline> to
update the annotator.

=item getPipeline

Returns a reference to the C<StanfordCoreNLP> pipeline used for annotation.
You probably won't want to touch this.

=item initPipeline

Reinitializes the C<StanfordCoreNLP> pipeline used for annotation.

=item process($str)

Process a string. Returns a C<Lingua::StanfordCoreNLP::PipelineSentenceList>.

=back


=head1 JAVA CLASSES

In addition, Lingua::StanfordCoreNLP indirectly exports the following Java-classes,
all belonging to the namespace C<be.fivebyfive.lingua.stanfordcorenlp>:


=head2 PipelineItem

Abstract superclass of C<Pipeline{Coreference,Dependency,Sentence,Token}>. Contains ID
and methods for getting and comparing it.

=over

=item getID

Returns a C<java.util.UUID> object which represents the item's ID.

=item getIDString

Returns the ID as a string.

=item identicalTo($b)

Returns true if C<$b> has an identical ID to this item.

=back


=head2 PipelineCoreference

An object representing a coreference between head-word W1 in sentence S1 and head-word W2 in sentence S2.
Note that both sentences and words are zero-indexed, unlike the default outputs of Stanford's tools.

=over

=item getSourceSentence

Index of sentence S1.

=item getTargetSentence

Index of sentence S2.

=item getSourceHead

Index of word W1 (in S1).

=item getTargetHead

Index of word W2 (in S2).

=item getSourceToken

The C<PipelineToken> representing W1.

=item getTargetToken

The C<PipelineToken> representing W2.

=item equals($b)

Returns true if this C<PipelineCoreference> matches C<$b> --- if
their C<getSourceToken> and C<getTargetToken> have the same ID.
Note that it returns true even if the orders of the
coreferences are reversed (if C<< $a->getSourceToken->getID == $b->getTargetToken->getID >>
and C<< $a->getTargetToken->getID == $b->getSourceToken->getID >>).

=item toCompactString

A compact String representation of the coreference ---
"Word/Sentence:Head E<lt>=E<gt> Word/Sentence:Head".

=item toString

A String representation of the coreference ---
"Word/POS-tag [sentence, head] E<lt>=E<gt> Word/POS-tag [sentence, head]".

=back


=head2 PipelineDependency

Represents a dependency in the Stanford Typed Dependency format.
For example, in the fragment "Walk hard", "Walk" is the governor and "hard"
is the dependent in the relationship "advmod" ("hard" is an adverbial modifier
of "Walk").

=over

=item getGovernor

The governor in the relation as a C<PipelineToken>.

=item getGovernorIndex

The index of the governor within the sentence.

=item getDependent

The dependent in the relation as a C<PipelineToken>.

=item getDependentIndex

The index of the dependent within the sentence.

=item getRelation

Short name of the relation.

=item getLongRelation

Long description of the relation.

=item toCompactString

=item toCompactString($includeIndices)

=item toString

=item toString($includeIndices)

Returns a String representation of the dependency --- "relation(governor-N, dependent-N) [description]".
C<toCompactString> does not include description. The optional parameter C<$includeIndices> controls
whether governor and dependent indices are included, and defaults to true.
(Note that unlike those of, e.g., the Stanford Parser, these indices start at zero, not one.)

=back


=head2 PipelineSentence

An annotated sentence, containing the sentence itself, its dependencies,
pos- and ner-tagged tokens, and coreferences.

=over

=item getSentence

Returns a string containing the original sentence

=item getTokens

A C<PipelineTokenList> containing the POS- and
NER-tagged and lemmaized tokens of the sentence.

=item getDependencies

A C<PipelineDependencyList> containing the dependencies
found in the sentence.

=item getCoreferences

A C<PipelineCoreferenceList> of the coreferences between
this and other sentences.

=item toCompactString

=item toString

A String representation of the sentence, its coreferences, dependencies, and tokens.
C<toCompactString> separates fields by "\n", whereas C<toString> separates them by
"\n\n".

=back


=head2 PipelineToken

A token, with POS- and NER-tag and lemma.

=over

=item getWord

The textual representation of the token (i.e. the word).

=item getPOSTag

The token's Part-of-Speech tag.

=item getNERTag

The token's Named-Entity tag.

=item getLemma

The lemma of the the token.

=item toCompactString

=item toCompactString($lemmaize)

A compact String representation of the token --- "word/POS-tag". If the
optional argument C<$lemmaize> is true, returns "lemma/POS-tag".

=item toString

A String representation of the token --- "word/POS-tag/NER-tag [lemma]".

=back


=head2 PipelineList

=head2 PipelineCoreferenceList

=head2 PipelineDependencyList

=head2 PipelineSentenceList

=head2 PipelineTokenList

C<PipelineList> is a generic list class which
extends C<java.Util.ArrayList>. It is in turn extended by
C<Pipeline{Coreference,Dependency,Sentence,Token}List> (which are the
list-types that C<Pipeline> returns). Note that all lists are zero-indexed.

=over

=item joinList($sep)

=item joinListCompact($sep)

Returns a string containing the output of either the C<toString> or
C<toCompactString> methods of the elements in C<PipelineList>, separated
by C<$sep>.

=item toArray

Return the elements of the list as an array-reference.

=item toHashMap

Return the list as a C<< java.util.HashMap<String,PipelineItem> >>, with
items' stringified ID:s as keys.

=item toCompactString

=item toString

Returns the elements of the C<PipelineList> as a string containing the output
of either their C<toCompactString> or C<toString> methods, separated by the
default separator (which is "\n" for all lists except C<PipelineTokenList>
which uses " ").

=back


=head1 TODO

=over

=item *

Add representative mention to PipelineCoreference.

=item *

Make build system also compile C<LinguaSCNLP.jar>.

=back


=head1 REQUESTS & BUGS

Please file any issues, bug-reports, or feature-requests at L<https://github.com/raisanen/lingua-stanfordcorenlp>.


=head1 AUTHORS

Kalle RE<auml>isE<auml>nen E<lt>kal@cpan.orgE<gt>.


=head1 COPYRIGHT

=head2 Lingua::StanfordCoreNLP (Perl bindings)

Copyright E<copy> 2011-2013 Kalle RE<auml>isE<auml>nen.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=head2 Stanford CoreNLP tool set

Copyright E<copy> 2010-2012 The Board of Trustees of The Leland Stanford
Junior University.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, see L<http://www.gnu.org/licenses/>.


=head1 SEE ALSO

L<http://nlp.stanford.edu/software/corenlp.shtml>,
L<Text::NLP::Stanford::EntityExtract>,
L<NLP::StanfordParser>,
L<Inline::Java>.

=cut
