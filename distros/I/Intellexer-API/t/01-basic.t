#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON;

use_ok q{Intellexer::API};

done_testing;

__END__

my $json = JSON->new->pretty(1);
my $sample_text ='AD 2140
The human race is still limited largely to the planet Earth. Sparsely-manned scientific colonies exist on Mars and Luna. After sporadic conflicts and bloodshed in the previous hundred years, Earth now exists mostly in a state of peace. Considerable scientific achievements have been made, especially in the areas of cybernetic implantation and genetic manipulation. Children are born free of birth defects, accident victims often have body parts replaced with newly "grown" parts, derived from their own DNA. People with nerve and brain damage commonly undergo cybernetic augmentation to restore their senses, cure paralysis, and solve many common debilitating brain disorders. A jubilant scientific community celebrates the many contributions their technology has made, allowing humanity to live happier, healthier, longer lives.

At about the same time, various military organizations are secretly researching the possibilities that these technologies may offer them. Among other things, great strides are made in human dermal reinforcement, muscle enhancement, reaction speed and perception enhancement. Test subjects are able to endure harsh environments for long periods of time and perform superhuman feats of strength and speed. Some governments begin testing and producing cloned "drone soldiers", human bodies with no brain, controlled by a small computer implanted in the skull. These soldiers have limited effectiveness when run autonomously, instead being wirelessly linked and controlled via a central computer. Other, more ghastly creations are engineered, strange creatures intended for a multitude of uses, both on and off the battlefield.';

my $sample_text2 ='AD 2140
The human race is still limited largely to the planet Earth. Sparsely-manned scientific colonies exist on Mars and Luna. After sporadic conflicts and bloodshed in the previous hundred years, Earth now exists mostly in a state of peace. Considerable scientific achievements have been made, especially in the areas of cybernetic implantation and genetic manipulation. Children are born free of birth defects, accident victims often have body parts replaced with newly "grown" parts, derived from their own DNA. People with nerve and brain damage commonly undergo cybernetic augmentation to restore their senses, cure paralysis, and solve many common debilitating brain disorders. A jubilant scientific communasdity celebrates the many contributions their technology has made, allowing humanity to live happier, healthier, longer lives.

At about the same time, various military organizations are secretly researching the possibilities that these technologies may offer them. Among other things, great strides are made in human dermal reinforcement, muscle enhancement, reaction speed and perception enhancement. Test subjects are able to endure harsh environments for long periods of time and perform superhuman feats of strength and speed. Some governments begin testinddg and producing cloned "drone soldiers", human bodies with no brain, controlled by a small computer implanted in the skull. These soldiers have limited effectiveness when run autonomously, instead being wirelessly linked and controlled via a central computer. Other, more ghastly creaddtions are engineered, strange creatures intended for a multitude of uses, both on and off the battlefield.';

my $filename = '/home/haxmeister/Documents/perl/intellexer-API/sample.txt';
my @url_list = (
    'https://www.vendetta-online.com/h/storyline_section3.html',
    'http://www.infoplease.com/biography/var/barackobama.html'
);
my $api_key = shift @ARGV;

my $api = Intellexer::API->new($api_key);
#my $response = $api->getTopicsFromUrl('https://perldoc.perl.org/perlsub');

# my $response = $api->analyzeText(
#     $sample_text,
#     'loadSentences' => 'True',
#     'loadTokens' => 'True',
#     'loadRelations' => 'True'
# );

# my $response = $api->sentimentAnalyzerOntologies();

# my @reviews = (
#     {
#         "id" => "snt1",
#         "text" => "YourText"
#     },
#     {
#         "id" => "snt2",
#         "text" => "YourText"
#     }
# );
# my $ontology = "Gadgets";
# my $response = $api->analyzeSentiments(
#     \@reviews,
#     'ontology'      => 'Hotels',
#     'loadSentences' => 'True', # defaults to false
# );
#
# my $response = $api->recognizeNe(
#     'url' => 'https://en.wikipedia.org/wiki/Boogie',
#     'loadNamedEntities' => 'True',    # load named entities (FALSE by default)
#     'loadRelationsTree' => 'True',    # load tree of relations (FALSE by default)
#     'loadSentences'     => 'True',    # load source sentences (FALSE by default)
# );


# my $response = $api->recognizeNeFileContent(
#     'fileName' => $filename,       # name of the file to process
#     #'fileSize' => $size,          # size of the file to process in bytes (optional)
#     'loadNamedEntities' => 'True', # load named entities (FALSE by default)
#     'loadRelationsTree' => 'True', # load tree of relations (FALSE by default)
#     'loadSentences'     => 'True', # load source sentences (FALSE by default)
# );

# my $response = $api->recognizeNeText(
#     $sample_text,
#     'loadNamedEntities' => 'True',    # load named entities (FALSE by default)
#     'loadRelationsTree' => 'True',    # load tree of relations (FALSE by default)
#     'loadSentences'     => 'True',    # load source sentences (FALSE by default)
# );

# my $response = $api->summarize(
#   'https://www.vendetta-online.com/h/storyline_section3.html',
#   'summaryRestriction' => '7',
#   'returnedTopicsCount' => '2',
#   'loadConceptsTree' => 'true',
#   'loadNamedEntityTree' => 'true',
#   'usePercentRestriction' => 'true',
#   'conceptsRestriction' => '7',
#   'structure' => 'general',
#   'fullTextTrees' => 'true',
#   'textStreamLength' => '1000',
#   'useCache' => 'false',
#   'wrapConcepts' => 'true'
# );

# my $response = $api->summarizeText(
#     $sample_text,
#   'summaryRestriction' => '7',
#   'returnedTopicsCount' => '2',
#   'loadConceptsTree' => 'true',
#   'loadNamedEntityTree' => 'true',
#   'usePercentRestriction' => 'true',
#   'conceptsRestriction' => '7',
#   'structure' => 'general',
#   'fullTextTrees' => 'true',
#   'textStreamLength' => '1000',
#   'useCache' => 'false',
#   'wrapConcepts' => 'true'
#
# );

# my $response = $api->summarizeFileContent(
#   $filename,
#   'summaryRestriction' => '7',
#   'returnedTopicsCount' => '2',
#   'loadConceptsTree' => 'true',
#   'loadNamedEntityTree' => 'true',
#   'usePercentRestriction' => 'true',
#   'conceptsRestriction' => '7',
#   'structure' => 'general',
#   'fullTextTrees' => 'true',
#   'textStreamLength' => '1000',
#   'useCache' => 'false',
#   'wrapConcepts' => 'true'
# );

# my $response = $api->multiUrlSummary(
#   \@url_list,
#   'filename' => 'sample.txt',  #required
#   'summaryRestriction' => '7',
#   'returnedTopicsCount' => '2',
#   'loadConceptsTree' => 'true',
#   'loadNamedEntityTree' => 'true',
#   'usePercentRestriction' => 'true',
#   'conceptsRestriction' => '7',
#   'structure' => 'general',
#   'fullTextTrees' => 'true',
#   'textStreamLength' => '1000',
#   'useCache' => 'false',
#   'wrapConcepts' => 'true'
# );

#my $response = $api->compareText($sample_text, $sample_text2);

#my $response = $api->compareUrls($url_list[0], $url_list[1]);

#my $response = $api->compareUrlwithFile($url_list[0], $filename);

#my $response = $api->compareFiles('sample.txt','sample2.txt');

# my $response = $api->clusterize(
#     $url_list[0],
#     'conceptsRestriction' => '10',
#     'fullTextTrees' => 'true',
#     'loadSentences' => 'true',
#     'wrapConcepts' => 'true'
# );

# my $response = $api->clusterizeText(
#     $sample_text,
#     'conceptsRestriction' => '10',
#     'fullTextTrees' => 'true',
#     'loadSentences' => 'true',
#     'wrapConcepts' => 'true'
# );

#my $sampleSize = -s 'sample.txt';
# my $response = $api->clusterizeFileContent(
#     'sample.txt',
#     'conceptsRestriction' => '10',
#     'fullTextTrees' => 'true',
#     'loadSentences' => 'true',
#     'wrapConcepts' => 'true',
# );

#my $response = $api->convertQueryToBool('I just enter some text here and see what happens');

#my $response = $api->supportedDocumentStructures();

#my $response = $api->supportedDocumentTopics();



#my $response = $api->parseFileContent('sample.txt');

#my $response = $api->recognizeLanguage($sample_text);
my $response = $api->checkTextSpelling(
    $sample_text,
    'language' => 'ENGLISH',
    'errorTune' => '2',
    'errorBound' => '3',
    'minProbabilityTune' => '2',
    'minProbabilityWeight' => '30',
    'separateLines' => 'true'
);

say $json->encode($response);
