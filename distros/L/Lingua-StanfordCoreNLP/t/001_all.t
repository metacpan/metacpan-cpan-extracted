#!/usr/bin/perl

use Test::More;

my @list_methods = qw(joinList joinListCompact toArray toHashMap toCompactString toString);
my @item_methods = qw(setIDFromString initializeCounters randomizeCounters generateID getID getIDString identicalTo);
my $default_annotators = 'tokenize, ssplit, pos, lemma, ner, parse, dcoref';
my $test_sentences = 'Jane looked at the IBM computer. She turned it off.';
my $java_namespace = 'Lingua::StanfordCoreNLP::be::fivebyfive::lingua::stanfordcorenlp';

##
## Module load
##
BEGIN {
	use_ok('Lingua::StanfordCoreNLP');
}


##
## Lingua::StanfordCoreNLP::Pipeline
##
my $pipeline = new_ok('Lingua::StanfordCoreNLP::Pipeline');
can_ok($pipeline, qw(getProperties setProperties getPipeline initPipeline process));

my $props = $pipeline->getProperties;
ok(
	defined($props) && $props->get('annotators') eq $default_annotators,
	'Lingua::StanfordCoreNLP::Pipeline->getProperties()'
);

$props->put('annotators', $default_annotators);
$pipeline->setProperties($props);
$props = $pipeline->getProperties;
ok(
	defined($props) && $props->get('annotators') eq $default_annotators,
	'Lingua::StanfordCoreNLP::Pipeline->setProperties()'
);


##
## Lingua::StanfordCoreNLP::PipelineSentenceList
##
my $result   = $pipeline->process($test_sentences);

isa_ok($result, $java_namespace . '::PipelineSentenceList');
can_ok($result, @list_methods);

my @sentences = @{$result->toArray};

ok(
	@sentences == 2,
	'"ssplit" annotator'
);


##
## Lingua::StanfordCoreNLP::PipelineSentence
##
for my $sent (@sentences) {
	isa_ok($sent, $java_namespace . '::PipelineSentence');
	can_ok($sent, qw(getSentence getTokens getDependencies getCoreferences toCompactString toString), @item_methods);
}

my $sentence = $sentences[0]->getSentence;

ok(
	defined $sentence,
	'Lingua::StanfordCoreNLP::PipelineSentence->getSentence'
);

my $tokens_ref = $sentences[0]->getTokens;


##
## Lingua::StanfordCoreNLP::PipelineTokenList
##
isa_ok($tokens_ref, $java_namespace . '::PipelineTokenList');
can_ok($tokens_ref, @list_methods);

my @tokens   = @{$tokens_ref->toArray};

ok(
	@tokens == 7,
	'Lingua::StanfordCoreNLP::PipelineTokenList->toArray'
);


##
## Lingua::StanfordCoreNLP::PipelineToken
##
my $token_look = $tokens[1];
my $token_IBM  = $tokens[4];

isa_ok($token_look, $java_namespace . '::PipelineToken');
can_ok($token_look, qw(getWord getPOSTag getNERTag getLemma toCompactString toString), @item_methods);

ok(
	$token_look->getWord   eq 'looked',
	'"tokenize" annotator'
);

ok(
	$token_look->getLemma  eq 'look',
	'"lemma" annotator'
);

ok(
	$token_look->getPOSTag  eq 'VBD',
	'"pos" annotator'
);

ok(
	$token_IBM->getNERTag  eq 'ORGANIZATION',
	'"ner" annotator'
);


##
## Lingua::StanfordCoreNLP::PipelineCoreferenceList
##
my $corefs_ref   = $sentences[0]->getCoreferences;

isa_ok($corefs_ref, $java_namespace . '::PipelineCoreferenceList');
can_ok($corefs_ref, @list_methods);

my @corefs = @{$corefs_ref->toArray};

ok(
	@corefs == 2,
	'Lingua::StanfordCoreNLP::PipelineCoreferenceList->toArray'
);


##
## Lingua::StanfordCoreNLP::PipelineCoreference
##
my $coref_jane = $corefs[0];

isa_ok($coref_jane, $java_namespace . '::PipelineCoreference');
can_ok($coref_jane, qw(
	getSourceSentence getTargetSentence getSourceHead getTargetHead
	getSourceToken getTargetToken equals toCompactString toString
), @item_methods);

ok(
	($coref_jane->getSourceToken->getWord eq 'Jane') &&
	($coref_jane->getTargetToken->getWord eq 'She'),
	'"dcoref" annotator'
);


##
## Lingua::StanfordCoreNLP::PipelineDependencyList
##
my $deps_ref = $sentences[0]->getDependencies;

isa_ok($deps_ref, $java_namespace . '::PipelineDependencyList');
can_ok($deps_ref, @list_methods);

my @deps =  @{$deps_ref->toArray};

ok(
	@deps == 4,
	'Lingua::StanfordCoreNLP::PipelineDependencyList->toArray'
);


##
## Lingua::StanfordCoreNLP::PipelineDependency
##
my $dep_nsubj = $deps[0];

isa_ok($dep_nsubj, $java_namespace . '::PipelineDependency');
can_ok($dep_nsubj, qw(
	getGovernor getGovernorIndex getDependent getDependentIndex
	getRelation getLongRelation toCompactString toString
), @item_methods);

ok(
	($dep_nsubj->getRelation eq 'nsubj') &&
	($dep_nsubj->getGovernorIndex  == 1)  &&
	($dep_nsubj->getDependentIndex == 0),
	'"parser" annotator'
);



done_testing;
