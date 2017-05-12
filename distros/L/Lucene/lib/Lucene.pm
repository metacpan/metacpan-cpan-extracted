package Lucene;
require DynaLoader;
require Exporter;

use 5.008;
use warnings;
use strict;


our $VERSION = '0.18';
our @ISA = qw( Exporter DynaLoader );
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
bootstrap Lucene $VERSION;

# This flag is necessary so that external variables get exported
# On Linux this corresponds to RTLD_GLOBAL of the function dlopen
sub dl_load_flags { 0x01 }

1; # End of Lucene

=head1 NAME

Lucene -- API to the C++ port of the Lucene search engine

=head1 SYNOPSIS

=head2 Initialize/Empty Lucene index

  my $analyzer = new Lucene::Analysis::Standard::StandardAnalyzer();
  my $store = Lucene::Store::FSDirectory->getDirectory("/home/lucene", 1);

  my $tmp_writer = new Lucene::Index::IndexWriter($store, $analyzer, 1);
  $tmp_writer->close;
  undef $tmp_writer;

=head2 Choose your Analyzer (string tokenizer)

  # lowercases text and splits it at non-letter characters 
  my $analyzer = new Lucene::Analysis::SimpleAnalyzer();
  # same as before and removes stop words
  my $analyzer = new Lucene::Analysis::StopAnalyzer();
  # same as before but you provide your own stop words
  my $analyzer = new Lucene::Analysis::StopAnalyzer([qw/that this in or and/]);
  # splits text at whitespace characters
  my $analyzer = new Lucene::Analysis::WhitespaceAnalyzer();
  # lowercases text, tokenized it based on a grammer that 
  # leaves named authorities intact (e-mails, company names,
  # web hostnames, IP addresses, etc) and removed stop words
  my $analyzer = new Lucene::Analysis::Standard::StandardAnalyzer();
  # same as before but you provide your own stop words
  my $analyzer = new Lucene::Analysis::Standard::StandardAnalyzer([qw/that this in or and/]);
  # takes string as it is
  my $analyzer = new Lucene::Analysis::KeywordAnalyzer();

=head2 Create a custom Analyzer

  package MyAnalyzer;

  use base 'Lucene::Analysis::Analyzer';

  # You MUST called SUPER::new if you implement new()
  sub new {
      my $class = shift;
      my $self = $class->SUPER::new();
      # ...
      return $self;
  }

  sub tokenStream {
      my ($self, $field, $reader) = @_;
      my $ret = new Lucene::Analysis::StandardTokenizer($reader);
      if ($field eq "MyKeywordField") {
          return $ret;
      }
      $ret = new Lucene::Analysis::LowerCaseFilter($ret);
      $ret = new Lucene::Analysis::StopFilter($ret, [qw/foo bar bax/]);
      return $ret;
  }
  package main;
  my $analyzer = new MyAnalyzer;

=head2 Choose your Store (storage engine)
  
  # in-memory storage
  my $store = new Lucene::Store::RAMDirectory();
  # disk-based storage
  my $store = Lucene::Store::FSDirectory->getDirectory("/home/lucene", 0);

=head2 Open and configure an IndexWriter

  my $writer = new Lucene::Index::IndexWriter($store, $analyzer, 0);
  # optional settings for power users
  $writer->setMergeFactor(100);
  $writer->setUseCompoundFile(0);
  $writer->setMaxFieldLength(255);
  $writer->setMinMergeDocs(10);
  $writer->setMaxMergeDocs(100);

=head2 Create Documents and add Fields

  my $doc = new Lucene::Document;
  # field gets analyzed, indexed and stored
  $doc->add(Lucene::Document::Field->Text("content", $content));
  # field gets indexed and stored
  $doc->add(Lucene::Document::Field->Keyword("isbn", $isbn));
  # field gets just stored
  $doc->add(Lucene::Document::Field->UnIndexed("sales_rank", $sales_rank));
  # field gets analyzed and indexed 
  $doc->add(Lucene::Document::Field->UnStored("categories", $categories));

=head2 Add Documents to an IndexWriter

  $writer->addDocument($doc);

=head2 Optimize your index and close the IndexWriter
  
  $writer->optimize();
  $writer->close();
  undef $writer; 

=head2 Delete Documents

  my $reader = Lucene::Index::IndexReader->open($store);
  my $term = new Lucene::Index::Term("isbn", $isbn);
  $reader->deleteDocuments($term);
  $reader->close();
  undef $reader;

=head2 Query index

  # initalize searcher and parser
  my $analyzer = new Lucene::Analysis::SimpleAnalyzer();
  my $store = Lucene::Store::FSDirectory->getDirectory("/home/lucene", 0);
  my $searcher = new Lucene::Search::IndexSearcher($store);
  my $parser = new Lucene::QueryParser("default_field", $analyzer);

  # build a query on the default field
  my $query = $parser->parse("perl");

  # build a query on another field
  my $query = $parser->parse("title:cookbook");

  # print query to a string (for debug purposes)
  my $string = $query->toString();

  # define a custom sort field
  my $sortfield = new Lucene::Search::SortField("unixtime"); 
  my $reversed_sortfield = new Lucene::Search::SortField("unixtime", 1);

  # use Lucene's build-in sort fields
  my $sortfield_by_score = Lucene::Search::SortField->FIELD_SCORE;
  my $sortfield_by_doc_num = Lucene::Search::SortField->FIELD_DOC;

  # define a sort on one field or on two fields
  my $sort = new Lucene::Search::Sort($sortfield);
  my $sort = new Lucene::Search::Sort($sortfield1, $sortfield2);

  # use Lucene's build-in sort
  my $sort = Lucene::Search::Sort->INDEXORDER;
  my $sort = Lucene::Search::Sort->RELEVANCE;

  # create a filter to contrain documents in which search is done
  my $filter = new Lucene::Search::QueryFilter($query);

  # query index and get results
  my $hits = $searcher->search($query);
  my $sorted_hits = $searcher->search($query, $sort);
  my $filtered_hits = $searcher->search($query, $filter);
  my $filtered_sorted_hits = $searcher->search($query, $filter, $sort);

  # get number of results
  my $num_hits = $hits->length();

  # get fields and ranking score for each hit
  for (my $i = 0; $i < $num_hits; $i++) {
    my $doc = $hits->doc($i);
    my $score = $hits->score($i);
    my $title = $doc->get("title");
    my $isbn = $doc->get("isbn");
  }

  # free memory and close searcher
  undef $hits;
  undef $query;
  undef $parser;
  undef $analyzer;
  $searcher->close();
  undef $fsdir;
  undef $searcher;
}

=head2 Access index by Document number

  # create index reader
  my $reader = Lucene::Index::IndexReader->open($store);

  # get number of docs in index
  my $num_docs = $reader->numDocs();

  # get the nth document
  my $document = $reader->document($n);

=head2 Get/Set field boost factor

  my $boost = $field->getBoost();
  $field->setBoost($boost);

=head2 Query multiple fields simultaneously

  my $parser = new Lucene::MultiFieldQueryParser(\@field_names, $analyzer);
  my $query = $parser->parse($query_string);

  # ... using different boosts per field
  my %rh_boosts = { "title" => 3, "subject" => 2 };
  my $parser = new Lucene::MultiFieldQueryParser(\@field_names, $analyzer, \%rh_boosts);
  my $query = $parser->parse($query_string);

=head2 Close your Store

  $store->close;
  undef $store;

=head2 Customize Lucene's scoring formula (for Lucene experts)

It is possible to customize Lucene's scoring formula by defining your own
Similarity object using perl XS and passing it on to both the IndexWriter
and the IndexSearcher

  $searcher->setSimilarity($similarity);
  $writer->setSimilarity($similarity);

=head2 Merge indexes

To merge several indexes into a single one, use the following method of
IndexWriter

  $writer->addIndexes(@stores);

This will add @stores to the writer's current store, and then optimize
the resulting index.

=head1 DESCRIPTION

Like it or not Lucene has become the de-facto standard for open-source
high-performance search. It has a large user-base, is well documented and has
plenty of committers. Unfortunately until recently Lucene was entirely written
in Java and therefore of relatively little use for perl programmers. Fortunately
in the recent years a group of C++ programmers led by Ben van Klinken decided
to port Java Lucene to C++. 

The purpose of the module is to export the C++ Lucene API to perl and at
the same time be as close as possible to the original Java API. This has the
combined advantage of providing perl programmers with a well-documented API
and giving them access to a C++ search engine library that is supposedly faster
than the original.

=head1 CHARACTER SUPPORT

This module support both types of perl strings that are available since perl 5.8.0
that is ISO 8859-1 (Latin-1) and UTF-8 encoded strings. For UTF-8 you need to make
sure that the UTF-8 flag is on. You can achieve this by applying 

  utf8::upgrade($string)

to your UTF-8 string. This will garantee the internal UTF-8 flag is on.

=head1 INDEX PORTABILITY

You can copy a Lucene index directory from one platform to another and it will
work just as well.

=head1 DEVELOPMENT AND DIAGNOSTIC TOOL

Lucene comes with a handy development and diagnostic tool which allows
to access already existing Lucene indices and to display and modify
their content. This tool is currently written in Java but doesn't
require any Java programming knowledge. 

You can download the tool (lukeall.jar) from the following webpage:

  http://www.getopt.org/luke/

and run it with the following command:

  java -jar lukeall.jar

=head1 INSTALLATION

This module requires the clucene library to be installed. The best way to
get it is to go to the following page
    
    http://sourceforge.net/projects/clucene/

and download the latest STABLE clucene-core version. Currently it is
clucene-core-0.9.20. Make sure you install it in your standard library path.

On a Linux platform this goes as follows:

    wget http://kent.dl.sourceforge.net/sourceforge/clucene/clucene-core-0.9.20.tar.gz
    tar xzf clucene-core-0.9.20.tar.gz
    cd clucene-core-0.9.20
    ./autogen.sh
    ./configure --disable-debug --prefix=/usr --exec-prefix=/usr
    make
    make check
    (as root) make install

To install the perl module itself, run the following commands:

    perl Makefile.PL
    make
    make test
    (as root) make install

=head1 SUPPORT AND FEEDBACK

For support and feedback please use the following mailing list:

    https://lists.sourceforge.net/lists/listinfo/clucene-perl

=head1 AUTHOR

Thomas Busch <tbusch at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2007 Thomas Busch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<Plucene> - a pure-Perl implementation of Lucene

L<KinoSearch> - a search engine library inspired by Lucene

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut
