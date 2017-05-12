#!/usr/bin/perl -w
####
#### Retread of GO's luigi, except find all OBO files and jam them into
#### a lucene index. Will be using slightly different commands.
####
#### Requires obo CVS's FileParser.pm to be in the perl path.
####
#### Usage:
####
####    perl -I/home/sjcarbon/local/src/cvs/obo/website/cgi-bin -I/home/sjcarbon/local/src/svn/geneontology/go-moose local/src/svn/geneontology/go-moose/bin/make-lucene-index-for-foundry.pl -v -e -o /data/public_ftp/pub/obo/obo-all -t /home/sjcarbon/local/src/cvs/obo/website/cgi-bin/ontologies.txt -d /tmp/lucene
####

## Bring in GOBO and OBO site data parser.
#use lib '/home/sjcarbon/local/src/svn/geneontology/go-moose';
#use lib '/home/sjcarbon/local/src/cvs/obo/website/cgi-bin';

use utf8;
use strict;
use Cwd;
use File::Find;
#use Data::Dumper;
use Getopt::Std;
use vars qw(
	     $opt_v
	     $opt_e
	     $opt_o
	     $opt_t
	     $opt_d
	  );

## Go go power GOBO!
## http://en.wikipedia.org/wiki/File:Arctium_lappa02.jpg
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
use GOBO::Util::LuceneIndexer;
use FileHandle;

use FileParse; # for ontologies.txt

## Setup.
getopts('ved:o:t:');


##
sub kvetch {
  my $str = shift || '';
  print STDERR $str . "\n" if $opt_v;
}

###
###
###


## Make sure that we have a writable directory for our target.
my $target_dir = './';
if ( $opt_d ) {
  $target_dir = $opt_d;
}
if( ! -d $target_dir ||
    ! -w $target_dir ){
  die "The targetted directory must be writable: $!";
}
kvetch('Will write to: ' . $target_dir);

## Make sure that we have the OBO file path right.
my $obo_dir = undef;
if ( $opt_o ) {
  $obo_dir = $opt_o;
}
if( ! defined($obo_dir) ||
    ! -d $obo_dir ){
  die "The OBO file directory must be corrected: $!";
}
kvetch('Will read from: ' . $obo_dir);

## Make sure that we have the ontologies.txt file path right.
my $ont_file = undef;
if ( $opt_t ) {
  $ont_file = $opt_t;
}
if( ! defined($ont_file) ||
    ! -f $ont_file ){
  die "The ontology file must be corrected: $!";
}
kvetch('Will read ontology file: ' . $ont_file);


###
### Fill in a hash with the information in 'ontologies.txt'.
###

## Parse ontologies.txt and check to see if there is anything by that
## name that we can work with.
my %ont_info = ();
open(INFILE, "<" . $ont_file)
  or die "Couldn\'t read ontologies.txt: $!";

## Slorp it all in.
my @mini_buff = ();
while (<INFILE>) { push @mini_buff, $_; }
close(INFILE);
my $ontologies_txt = join('', @mini_buff);

## Break it into double newline chunks.
my @chunks = split /\n\n/s, $ontologies_txt;

foreach my $chunk (@chunks){

  ## If it looks like it has a key.
  #if( $chunk =~ /id\s+(.*)/g ){
  if( $chunk =~ /download\s+http\:\/\/obo\.cvs\.sourceforge\.net\/\*checkout\*\/obo\/(.*)/g ){

    my $current_file = $1;
    if ( ! $ont_info{$current_file} ){
      $ont_info{$current_file} = {};
    }

    if( $chunk =~ /id\s+(.*)/ ){
      $ont_info{$current_file}{'id'} = $1; }
    if( $chunk =~ /domain\s+(.*)/ ){
      $ont_info{$current_file}{'domain'} = $1; }
    if( $chunk =~ /relevant_organism\s+NCBITaxon\:(.*)\|.+/ ){
	$ont_info{$current_file}{'organism'} = $1; }
    if( $chunk =~ /relevant_organism\s+all/ ){
      $ont_info{$current_file}{'organism'} = 'all'; }
    #if( $chunk =~ /download\s+http\:\/\/obo\.cvs\.sourceforge\.net\/\*checkout\*\/obo\/(.*)/ ){
    #  $ont_info{$current_id}{'file'} = $1; }
  }
}

#kvetch(Dumper(\%ont_info));

###
### Ready storage.
###

my $loo = new GOBO::Util::LuceneIndexer();
$loo->target_dir($target_dir);
$loo->open();

###
### Walk through tree, find obo files, parse them, and jam them in.
###

my @all_fatals = ();
find(\&action, $obo_dir);
sub action {

  ## Is it an OBO file?
  my $file = $File::Find::name;

  if( -f $file &&
      $file =~ /\.obo$/ ){

    ##
    kvetch('Processing file: ' . $file);
    my $parser = undef;
    eval{
      $parser = new GOBO::Parsers::OBOParser(file=>$file);
    };
    if( $@ ){
      my $estr = "Bad file parse (1): " . $file . ": " . $@;
      kvetch($estr);
      push @all_fatals, $estr;
    }else{

      ## 
      kvetch('Parsing file: ' . $file);
      eval{
	$parser->parse();
      };
      if( $@ ){
	my $estr = "Bad file parse (2): " . $file . ": " . $@;
	kvetch($estr);
	push @all_fatals, $estr;
      }else{
	kvetch("Good file: " . $file);
	$loo->index_terms($parser->graph->terms);
      }
    }
  }
}

kvetch('Done processing files. Will now optimize...');
$loo->close();

kvetch('Success.');

##
if( $opt_e ){
  foreach my $e (@all_fatals){ print $e; }
}
