# NAME

Intellexer::API - API client for Intellexer

Perl API client for  [Intellexer](https://www.intellexer.com/), a webservice that, "enables developers to embed Intellexer semantics products using XML or JSON."

# SYNOPSIS
```perl
    my $api_key = q{...get this from intellexer.com};
    my $api = Intellexer::API->new($api_key);
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
```
# DESCRIPTION

An interface to the [Intellexer](https://www.intellexer.com/) API. This module provides perl methods to all the methods available in the Intellexer API using the same names. This will make it easy for those who want to look for more documentation on the [Intellexer API help website ](https://esapi.intellexer.com/Home/Help)

## Methods

### Topic Modeling

Automatically extract topics from text.

#### `getTopicsFromUrl($url)`

Accepts a single argument that is a valid URL to a document or webpage.
```perl
    my $response = $api->getTopicsFromUrl( 'https://perldoc.perl.org/perlsub' );
```
#### `getTopicsFromFile($file_path)`

Accepts a single argument that is a valid path to a local text file.
```perl
    my $response = $api->getTopicsFromFile($file_path);
```
#### `getTopicsFromText($text)`

Accepts a single argument that is text to be analyzed.
```perl
    my $response = $api->getTopicsFromText($text);
```
### Linguistic Processor

Parse an input text stream and extract various linguistic information: detected sentences with their offsets in a source text; text tokens (words of sentences) with their part of speech tags, offsets and lemmas (normal forms); subject-verb-object semantic relations.

**Parameters**

- loadSentences - load source sentences (TRUE by default)
- loadTokens - load information about words of sentences (TRUE by default)
- loadRelations - load information about extracted semantic relations in sentences (TRUE by default)

#### `analyzeText($text, %params)`

Accepts the text to be analyzed and optionally one or more of the shown parameters.
```perl
    my $response = $api->analyzeText(
        $sample_text,
        'loadSentences' => 'True',
        'loadTokens'    => 'True',
        'loadRelations' => 'True'
    );
```
**Response Structure**

    'sentences' - array of processed sentences
        'text' - text of the sentence with offset information
            'content' - the sentence plain text
            'beginOffset' - the start sentence offset in the source text
            'endOffset' - the end sentence offset in the source text
        'tokens' - list of tokens extracted from sentences
            'text' - text of the token with offset information
                'content' - the token plain text
                'beginOffset' - the start token offset in the source sentence
                'endOffset' - the end token offset in the source sentence
            'partOfSpeechTag' - token part of speech tag (the tagset is a generalized version of the Lancaster-Oslo/Bergen (LOB) tagset and consist of 37 tags)
                'lemma' - initial token form
        'relations' - array of extracted subject-verb-object relations
        'tokens' - list of tokens extracted from sentences
            'text' - text of the token with offset information
                'content' - the token plain text
                'beginOffset' - the start token offset in the source sentence
                'endOffset' - the end token offset in the source sentence
            'partOfSpeechTag' - token part of speech tag (the tagset is a generalized version of the Lancaster-Oslo/Bergen (LOB) tagset and consist of 37 tags)
                'lemma' - initial token form
        'relations' - array of extracted subject-verb-object relations
            'subject' - subject field
            'verb' - verb field
            'object' - object field
            'adverbialPhrase' - adverbial phrase field

### Sentiment Analyzer

Automatically extracts sentiments (positivity/negativity), opinion objects (e.g., product features with associated sentiment phrases) and emotions (liking, anger, disgust, etc.) in unstructured text data.

You will need the list of currently available ontologies which you can retrieve using the `sentimentAnalyzerOntologies` method

**Parameters**

- ontology - specify which of the existing ontologies will be used to group the results
- loadSentences - load source sentences (FALSE by default)

#### `sentimentAnalyzerOntologies()`

Accepts no arguments but returns the ontologies available from the API
```perl
    my $response = $api->sentimentAnalyzerOntologies();
```
#### `analyzeSentiments(\@reviews, %params)`

Accepts a reference to a list of reviews and the shown parameters
```perl
    my @reviews = (
        {
            "id" => "snt1",
            "text" => "YourText"
        },
        {
            "id" => "snt2",
            "text" => "YourText"
        }
    );

    my $ontology = "Gadgets";
    my $response = $api->analyzeSentiments(
        \@reviews,
        'ontology'      => 'Hotels', # required
        'loadSentences' => 'True',   # defaults to false
    );
```
**Response Structure**

    'sentimentsCount' - number of processed reviews
    'ontology' - ontology used to group the results
    'sentences' - array of processed sentences
        'sid' - review identifier
        'text' - text of the sentence with the sentiment tags (pos - positive words, neg - negative words and obj - sentiment objects)
        'w' - sentiment weight of the sentence (0 - neutral information, <0 - negative information, >0 - positive information)
    'opinions' - tree of categorized opinions (opinion objects with sentiment phrases)
        't' - text of the opinion object, opinion phrase or the title of an ontology category
        'w' - sentiment weight of the opinion (negative or positive values are used for opinion phrases, zero values - for objects or ontology categories)
    'sentiments' - additional information about the processed reviews
        'author' - author of the review
        'dt' - date and time when the review was written
        'id' - review identifier
        'title' - review title
        'w' - sentiment weight of the review. This parameter is used to classify the whole text of a review as expressing a positive, neutral or negative opinion

### Named Entity Recognizer

Identifies elements in text and classifies them into predefined categories such as personal names, names of organizations, position/occupation, nationality, geographical location, date, age, duration and names of events. Additionally allows identifying the relations between named entities.

**Parameters**

- url - The url to parse (when using url based method)
- fileName - name of the file to process (when using file processing only
- fileSize - size of the file to process in bytes
- loadNamedEntities - load named entities (FALSE by default)
- loadRelationsTree - load tree of relations (FALSE by default)
- loadSentences - load source sentences (FALSE by default)

#### `recognizeNe(%params)`

Load Named Entities from a document from a given URL. Accepts the shown parameters.
```perl
    my $response = $api->recognizeNe(
        'url'               => 'https://en.wikipedia.org/wiki/Boogie', # required
        'loadNamedEntities' => 'True',    # load named entities (FALSE by default)
        'loadRelationsTree' => 'True',    # load tree of relations (FALSE by default)
        'loadSentences'     => 'True',    # load source sentences (FALSE by default)
    );
```
**Response Structure**

    'document' - information about the text
        'id' - document identifier
        'size' - document size in bytes
        'title' - document title
        'url' - source of the request
        'error' - information about processing errors
        'sizeFormat' - formatted document size
    'entities' - array of detected entities
        'sentenceIds' - array of sentence identifiers containing extracted entities
        'type' -entity type. Possible values: 0 - Unknown, 1 - Person, 2 - Organization, 3 - Location, 4 - Title, 5 - Position, 6 - Age, 7 - Date, 8 - Duration, 9 - Nationality, 10 - Event, 11 - Url, 12 - MiscellaneousLocation
        'wc' - number of words in the entity
        'text' - entity text
    'sentences' - array of processed sentences
    'relationsTree' - tree of relations among the detected entities
        'entityText' - entity text
        'sentenceIds' - array of sentence identifiers
        'text' - entity text along with the entity type identifier
        'type' - entity type

#### `recognizeNeFileContent($file_path, %params)`

Load Named Entities from a file. Accepts a file path and the shown parameters as arguments.
```perl
    my $response = $api->recognizeNeFileContent(
        $filepath,
        'fileSize'          => $size,
        'loadNamedEntities' => 'True',
        'loadRelationsTree' => 'True',
        'loadSentences'     => 'True',
    );
```
**Response Structure**

    'document' - information about the text
    'entities' - array of the detected entities
        'sentenceIds' - array of sentence identifiers
        'type' - entity type. Possible values: 0 - Unknown, 1 - Person, 2 - Organization, 3 - Location, 4 - Title, 5 - Position, 6 - Age, 7 - Date, 8 - Duration, 9 - Nationality, 10 - Event, 11 - Url, 12 - MiscellaneousLocation
        'wc' - number of words in the entity
        'text' - entity text
    'sentences' - array of processed sentences
    'relationsTree' - tree of relations among the detected entities
        'entityText' -entity text
        'sentenceIds' - array of sentence identifiers containing detected entities
        'text' - entity text along with the entity type identifier
        'type' - entity type

#### `recognizeNeText($text, %params)`

Load Named Entities from a text. Accepts a sample text and the shown parameters.
```perl
    my $response = $api->recognizeNeText(
       $sample_text,
       'loadNamedEntities' => 'True',
       'loadRelationsTree' => 'True',
       'loadSentences'     => 'True',
    );
```
**Response Structure**

    'document' - information about the text
    'entities' - array of detected named entities
        'sentenceIds' - array of sentence identifiers
        'type' - entity type. Possible values: 0 - Unknown, 1 - Person, 2 - Organization, 3 - Location, 4 - Title, 5 - Position, 6 - Age, 7 - Date, 8 - Duration, 9 - Nationality, 10 - Event, 11 - Url, 12 - MiscellaneousLocation
        'wc' - number of words in the entity
        'text' - entity text
    'sentences' - array of processed sentences
    'relationsTree' - tree of relations among the detected entities
        'entityText' - entity text
        'sentenceIds' - array of sentence identifiers containing detected entities
        'text' - entity text along with entity type identifier
        'type' - entity type

### Summarizer

Automatically generates a summary (short description) of a document with its main ideas. Intellexer Summarizer's unique feature is the possibility to create different kinds of summaries: theme-oriented (e.g., politics, economics, sports, etc.), structure-oriented (e.g., scientific article, patent, news article) and concept-oriented.

**Parameters**

- loadConceptsTree - load a tree of concepts (FALSE by default)
- loadNamedEntityTree - load a tree of Named Entities (FALSE by default)
- summaryRestriction - determine size of a summary measured in sentences
- usePercentRestriction - use percentage of the number of sentences in the original text instead of the exact number of sentences
- conceptsRestriction - determine the length of a concept tree
- structure - specify structure of the document (News Article, Research Paper, Patent or General)
- returnedTopicsCount - determine max count of document topics to return
- fullTextTrees - load full text trees
- useCache - if TRUE, document content will be loaded from cache if there is any
- wrapConcepts - mark concepts found in the summary with HTML bold tags (FALSE by default)

#### `summarize($url, %params)`

Returns summary data for a document from a given URL. Accepts a valid URL as the first argument then any parameters.
```perl
    my $response = $api->summarize(
        $url,
       'summaryRestriction'    => '7',
       'returnedTopicsCount'   => '2',
       'loadConceptsTree'      => 'true',
       'loadNamedEntityTree'   => 'true',
       'usePercentRestriction' => 'true',
       'conceptsRestriction'   => '7',
       'structure'             => 'general',
       'fullTextTrees'         => 'true',
       'textStreamLength'      => '1000',
       'useCache'              => 'false',
       'wrapConcepts'          => 'true'
    );
```
**Response Structure**

    'summarizerDoc' - information about the text
        'id' - document identifier
        'size' - document size in bytes
        'title' - document title
        'url' - source of the request
        'error' - information about processing errors
        'sizeFormat' - formatted document size
    'structure' - document structure
    'topics' - array of detected document topics
    'items' - summary items (important document sentences)
        'text' - text of the summary item
        'rank' - item rank. Larger rank means greater importance of the sentence
        'weight' - item weight
    'totalItemsCount' - total number of processed sentences
    'conceptTree' - tree of important document concepts
        'sentenceIds' - array of sentence identifiers containing detected concepts
        'text' - concept text
        'w' - concept weight
        'mp' - "main phrase" - meaningful/important concepts used in NE relations tree
        'st' - "status" - concept value change from 0 to 1, if the concept was selected for Rearrange operation
        'children' array - concept tree that consists of root nodes (for ex. retrieval) and children nodes (for ex. information retrieval)
    'namedEntityTree' - tree of relations among the detected entities
        'entityText' - entity text
        'sentenceIds' - array of sentence identifiers containing detected entities
        'text' - entity text
        'w' - entity weight

#### `summarizeText($text, %params)`

Return summary data for a text. Accepts text as first argument then any parameters.
```perl
    my $response = $api->summarizeText( $sample_text, %params );
```
    Response Summary:

        'summarizerDoc' - information about the text
           'id' - document identifier
           'size' - document size in bytes
           'title' - document title
           'url' - source of the request
           'error' - information about processing errors
           'sizeFormat' - formatted document size
       'structure' - document structure
       'topics' - array of detected document topics
       'items' - summary items (important document sentences)
           'text' - text of the summary item
           'rank' - item rank. Larger rank means greater importance of the sentence
           'weight' - item weight
       'totalItemsCount' - total number of processed sentences
       'conceptTree' - tree of important document concepts
           'sentenceIds' - array of sentence identifiers containing  detected concepts
           'text' - concept text
           'w' - concept weight
           'mp' - "main phrase" - meaningful/important concepts used in NE relations tree
           'st' - "status" - concept value change from 0 to 1, if the concept was selected for Rearrange operation
           'children' array - concept tree that consists of root nodes (for ex. retrieval) and children nodes (for ex. information retrieval)
       'namedEntityTree' - tree of relations among the detected entities
           'entityText' - entity text
           'sentenceIds' - array of sentence identifiers containing detected entities
           'text' - entity text
           'w' - entity weight

#### `summarizeFileContent($file_path, %params)`

Return summary data for a text file. Accepts a file path as first argument then any parameters.
```perl
    my $response = $api->summarizeFileContent( $file_path, %params );
```
**Response Structure**

    'summarizerDoc' - information about the text
        'id' - document identifier
        'size' - document size in bytes
        'title' - document title
        'url' - source of the request
        'error' - information about processing errors
        'sizeFormat' - formatted document size
    'structure' - document structure
    'topics' - array of detected document topics
    'items' - summary items (important document sentences)
        'text' - text of the summary item
        'rank' - item rank. Larger rank means greater importance of the sentence
        'weight' -item weight
    'totalItemsCount' - total number of processed sentences
    'conceptTree' - tree of important document concepts
        'sentenceIds' - array of sentence identifiers containing detected concepts
        'text' - concept text
        'w' - concept weight
        'mp' - "main phrase" - meaningful/important concepts used in NE relations tree
        'st' - "status" - concept value change from 0 to 1, if the concept was selected for Rearrange operation
        'children' array - concept tree that consists of root nodes (for ex. retrieval) and children nodes (for ex. information retrieval)
    'namedEntityTree' - tree of relations among the detected entities
        'entityText' - entity text
        'sentenceIds' - array of sentence identifiers containing detected entities
        'text' - entity text
        'w' - entity weight

### Multi-Document Summarizer

With Related Facts automatically generates a summary (short description) from multiple documents with their main ideas. Also it detects the most important facts between the concepts of the selected documents (this feature is called Related Facts).

**Parameters**

- loadConceptsTree - load a tree of concepts (FALSE by default)
- loadNamedEntityTree - load a tree of Named Entities (FALSE by default)
- summaryRestriction - determine size of a summary measured in sentences
- usePercentRestriction - use percentage of the number of sentences in the original text instead of the exact number of sentences
- conceptsRestriction - determine the length of a concept tree
- structure - specify structure of the document (News Article, Research Paper, Patent or General)
- returnedTopicsCount - set max number of document topics to return
- relatedFactsRequest - add a query to extract facts and concepts related to it
- maxRelatedFactsConcepts - set max number of related facts/concepts to return
- maxRelatedFactsSentences - set max number of sample sentences for each related fact/concept
- fullTextTrees - load full text trees

#### `multiUrlSummary(\@url_list, %params)`

Accepts a reference to a list of valid URLs and then any parameters.
```perl
    my $response = $api->multiUrlSummary(
        \@url_list,
        'filename'              => 'sample.txt',  #required
        'summaryRestriction'    => '7',
        'returnedTopicsCount'   => '2',
        'loadConceptsTree'      => 'true',
        'loadNamedEntityTree'   => 'true',
        'usePercentRestriction' => 'true',
        'conceptsRestriction'   => '7',
        'structure'             => 'general',
        'fullTextTrees'         => 'true',
        'textStreamLength'      => '1000',
        'useCache'              => 'false',
        'wrapConcepts'          => 'true'
    );
```
**Response Structure**

    'documents' - information about the documents
        'id' - document identifier
        'size' - document size in bytes
        'title' - document title
        'url' - source of the request
        'error' - information about processing errors
        'sizeFormat' - formatted document size
    'topics' - array of detected document topics
    'structure' - document structure
    'items' - multi-document summary items (important document sentences)
        'text' - item text
        'rank' - item rank. Larger rank means greater importance of the sentence
        'weight' - item weight
    'conceptTree' - tree of important document concepts
        'mp' - "main phrase" - meaningful/important concepts used in NE relations tree
        'st' - "status" - concept value change from 0 to 1, if the concept was selected for Rearrange operation
        'children' array - concept tree that consists of root nodes (for ex. retrieval) and children nodes (for ex. information retrieval)
    'namedEntityTree' - tree of relations among the detected entities
    'relatedFactsQuery' - query for related facts extraction (most important concepts and document sentences related to the query)
    'relatedFactsTree' - related facts tree along with the facts about the extracted concepts
        'sentenceIds' - array of sentence containing detected facts
        'text' - fact text
        'w' - fact weight

### Comparator

Accurately compares documents of any format and determines the degree of similarity between them.

**Parameters**

- useCache - if TRUE, document content will be loaded from cache if there is any

**Response Structure**

    'proximity' - proximity between documents. The proximity is calculated within the range of 0-1, where 0 means "completely different texts" and 1 means "completely identical texts"
    'document1' - information about the first document
        'id' - document identifier
        'size' - document size in bytes
        'title' - document title
        'url' - source of the request
        'error' - information about processing errors
        'sizeFormat' - formatted document size
    'document2' - information about the second document
        'id' - document identifier
        'size' - document size in bytes
        'title' - document title
        'url' - source of the request
        'error' - information about processing errors
        'sizeFormat' - formatted document size

#### `compareText( $text1, $text2 )`

Compares the specified sources. Accepts two arguments that are text.
```perl
    my $response = $api->compareText( $sample_text, $sample_text2 );
```
#### `compareUrls( $url1, $url2, %params )`

Compares the specified sources. Accepts two arguments that are valid URLs followed by any params.
```perl
    my $response = $api->compareUrls( $url1, $url2 );
```
#### `compareUrlwithFile( $url, $file, %params )`

Compares URL source to a local file. Accepts a valid URL followed by a valid file path followed by any params
```perl
    my $response = $api->compareUrlwithFile( $url, $filename )
```
#### `compareFiles( $file1, $file2 )`

Compares the given sources. Accepts two arguments that are both valid file paths.
```perl
    my $response = $api->compareFiles('sample.txt','sample2.txt');
```
### Clusterizer

Hierarchically sorts an array of documents or terms from given texts.

**Parameters**

- conceptsRestriction - determine the length of a concept tree
- fullTextTrees - load full text trees
- useCache - if TRUE, document content will be loaded from cache if there is any ( when using URLs )
- loadSentences - load all sentences
- wrapConcepts - mark concepts found in the summary with HTML bold tags (FALSE by default)

**Response Structure**

    'conceptTree' - tree of important document concepts
        'sentenceIds' - array of sentence identifiers containing detected concepts
        'text' - concept text
        'w' - concept weight
        'mp' - "main phrase" - meaningful/important concepts used in NE relations tree
        'st' - "status" - concept value change from 0 to 1, if the concept was selected for Rearrange operation
        'children' array - concept tree that consists of root nodes (for ex. retrieval) and children nodes (for ex. information retrieval)
    'sentences' - array of processed sentences

#### `clusterize($url, %params)`

Return tree of concepts for a document from a given URL. Accepts a valid URL followed by any parameters.
```perl
    my $response = $api->clusterize(
        $url_list[0],
        'conceptsRestriction' => '10',
        'fullTextTrees'       => 'true',
        'loadSentences'       => 'true',
        'wrapConcepts'        => 'true'
    );
```
#### `clusterizeText($text, %params)`

Return tree of concepts for a text. Accepts text followed by any parameters.
```perl
    my $response = $api->clusterizeText( $sample_text, %params );
```
#### clusterizeFileContent($file, %params)

Return tree of concepts for a text. Accepts a valid file path followed by any parameters.
```perl
    my $response = $api->clusterizeFileContent($file, %params)
```
### Natural Language Interface

Transforms Natural Language Queries into Boolean queries.

#### `convertQueryToBool( $text )`

Convert a user query in English to a set of terms and concepts joined by logical operators. Accepts a single argument which is the text to be processed
```perl
    my $response = $api->convertQueryToBool('I just enter some text here and see what happens');
```
### Preformator

Extracts plain text and information about the text layout from documents of different formats (doc, pdf, rtf, html, etc.).

**Parameters**

- useCache - if TRUE, document content will be loaded from cache if there is any
- getTopics - if TRUE, response will contain Topic ID of the document

#### `supportedDocumentStructures()`

Return available Preformator Document structures.
```perl
    my $response = $api->supportedDocumentStructures();
```
#### `supportedDocumentTopics()`

Return available Preformator Document topics.
```perl
    my $response = $api->supportedDocumentTopics();
```
#### `parse( $url, %params )`

**Response Structure**

    'structure' - document structure
    'topics' - array of detected document topics
    'lang' - document language
    'langId' - language identifier
    'inputSize' - size of the document before processing
    'size' - size of extracted plain text
    'text' - plain text from the input document

Parse internet/intranet file content using Preformator. Accepts a valid URL followed by any parameters.
```perl
    my $response = $api->parse( $url, 'getTopics' => 'true');
```
#### `parseFileContent( $file )`

Parse file content using Preformator. Accepts a single argument that is a valid path to a file.
```perl
    my $response = $api->parse( $file_path );
```
**Response Structure**

    'structure' - document structure
    'topics' - array of detected document topics
    'lang' - document language
    'langId' - language identifier
    'inputSize' - size of the document before processing
    'size' - size of extracted plain text
    'text' - plain text from the input document

### Language Recognizer

Identifies the language and character encoding of incoming documents.

#### `recognizeLanguage( $text )`

Recognize language and encoding of an input text stream. Accepts one argument that is the text to be analyzed.
```perl
    my $response = $api->recognizeLanguage( $text );
```
**Response Structure**

    'languages' - array of detected languages
    'language' - document language
    'encoding' - document encoding
    'weight' - language weight. Lar

### Spellchecker

Automatically corrects spelling errors due to well-chosen statistic and linguistic rules, including: rules for context-dependent misspellings; rules for evaluating the probability of possible corrections; rules for evaluating spelling mistakes caused by different means of representing speech sounds by the letters of alphabet; dictionaries with correct spelling and etc.

**Parameters**

- separateLines - process each line independently
- language - set input language
- errorTune - adjust 'errorBound' to the length of words according to the expert bound values. There are 3 possible modes:
    1. Reduce - choose the smaller value between the expert value and the bound set by the user;
    2. Equal - choose the bound set by the user;
    3. Raise - choose the bigger value between the expert value and the bound set by the user.
- errorBound - manually set maximum number of corrections for a single word regardless of its length
- minProbabilityTune - adjust 'minProbabilityWeight' to the length of words according to the expert probability values. Modes are similar to 'errorTune'
- minProbabilityWeight - set minimum probability for the words to be included to the list of candidates

#### `checkTextSpelling($text, %params)`

Perform text spell check. Accepts the text as the first argument, followed by any parameters.
```perl
    my $result = $api->checkTextSpelling(
        $text,
        'language'             => 'ENGLISH',
        'errorTune'            => 2,
        'errorBound'           => 3,
        'minProbabilityTune'   => 2,
        'minProbabilityWeight' => 30,
        'separateLines'        => 'true'
    );
```
**Response Structure**

    'inputSize' - size of the document
    'sentencesCount' - number of processed sentences
    'processedSentences' - array of corrected sentences
    'sourceSentences' - array of source sentences
    'corrections' - array of candidate corrections
        'l' - length of the candidate correction
        'ndx' - index of the sentence with a spelling error
        's' - the offset of the error
        'v' - array of candidate corrections
            't' - correction text
            'w' - correction weight. Larger weight means greater relevance of the candidate correctionmeans greater  relevance of the detected language

# ENVIRONMENT

An API key is required to access the Intellexer API. You can get one free for 30 days.

[https://www.intellexer.com/](https://www.intellexer.com/)

Intellexer.com provides API documentation that this module attempts to follow.

[https://esapi.intellexer.com/Home/Help](https://esapi.intellexer.com/Home/Help)

# BUGS

Please report bugs to the Github repository for this project.

[https://github.com/haxmeister/Perl-Intellexer-API](https://github.com/haxmeister/Perl-Intellexer-API)

# AUTHOR

HAX (Joshua S. Day)
<haxmeister@hotmail.com>

# LICENSE & COPYRIGHT

This software is copyright (c) 2024 by Joshua S. Day.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
