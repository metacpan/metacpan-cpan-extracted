#!/usr/bin/perl 

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use MendeleySQLite;

my $test_data = './t/test-data.db';

if ( ! -e $test_data ) {
    plan 'skip_all' => 'Test data file could not be read';
    done_testing();
}

my $M = MendeleySQLite->new( { 'dbfile' => $test_data } );

isa_ok( $M, 'MendeleySQLite' );

{

    ##
    ## get_all_keywords

    my $rh_keywords = $M->get_all_keywords();
    
    my $rh_expected = {
              'oral adverse effects' => '1',
              'randomized controlled trials topic' => '2',
              'randomized controlled trials topic standards' => '1',
              'observational' => '1',
              'factor v genetics' => '1',
              'biomedical research' => '1',
              'oral' => '1',
              'evaluation studies topic' => '1',
              'biomedical research methods' => '1',
              'how-to' => '1',
              'venous thromboembolism genetics' => '1',
              'bias' => '2',
              'follow up studies' => '1',
              'venous thromboembolism' => '1',
              'factor v' => '1',
              'female' => '1',
              'pharmaceutical preparations adverse effects' => '1',
              'Mendeley' => '1',
              'risk' => '1',
              'confounding factors (epidemiology)' => '1',
              'case control studies' => '1',
              'user manual' => '1',
              'retrospective studies' => '1',
              'interventional' => '1',
              'error' => '1',
              'pharmaceutical preparations' => '1',
              'biomedical research standards' => '1',
              'contraceptives' => '1',
              'humans' => '2',
              'research design' => '1',
              'prospective studies' => '1',
              'observation' => '1',
              'random allocation' => '1',
              'RCT' => '1',
              'bias (epidemiology)' => '1'
            };
    
    cmp_deeply(
        $rh_expected,
        $rh_keywords 
    );
        
}

{
    
    ##
    ## get_all_tags()
    
    my $rh_tags = $M->get_all_tags();
    
    my $rh_expected = {
              'observational' => '2',
              'confounding' => '2',
              'RCT' => '3',
              'interventional' => '1',
              'error' => '1',
              'bias' => '3'
            };
    
    cmp_deeply(
            $rh_expected,
            $rh_tags
        );

}

{
    
    ##
    ## get_all_tags_for_document()
    
    my $ra_tags = $M->get_all_tags_for_document('2');
    
    my $ra_expected = ['bias', 'error' ];
    
    cmp_deeply(
        $ra_expected,
        $ra_tags );
    
}

{
    
    ##
    ## get_all_keywords_for_document()

    my $ra_keywords = $M->get_all_keywords_for_document('2');

    my $ra_expected = [ 'bias', 'error' ];
    
    cmp_deeply(
        $ra_keywords,
        $ra_expected );
    
}

{
    ##
    ## get_document()
    
    my $rh_document = $M->get_document('2');

    my $rh_expected = {
              'hideFromMendeleyWebIndex' => 'false',
              'advisor' => undef,
              'department' => undef,
              'citationKey' => undef,
              'chapter' => '532',
              'issue' => '8',
              'keywords' => [
                              'bias',
                              'error'
                            ],
              'session' => undef,
              'day' => undef,
              'seriesNumber' => undef,
              'isbn' => undef,
              'doi' => undef,
              'code' => undef,
              'originalPublication' => undef,
              'reviewedArticle' => undef,
              'modified' => '1338896138',
              'arxivId' => undef,
              'lastUpdate' => undef,
              'title' => 'Why Most Published Research Findings Are False',
              'pages' => 'e124',
              'codeSection' => undef,
              'userType' => undef,
              'committee' => undef,
              'month' => undef,
              'internationalUserType' => undef,
              'added' => '1338896116',
              'series' => 'WISICT \'04',
              'seriesEditor' => undef,
              'medium' => undef,
              'edition' => undef,
              'sections' => undef,
              'dateAccessed' => undef,
              'country' => undef,
              'sourceType' => undef,
              'language' => undef,
              'articleColumn' => undef,
              'applicationNumber' => undef,
              'internationalTitle' => undef,
              'tags' => [
                          'bias',
                          'error'
                        ],
              'length' => undef,
              'deletionPending' => 'false',
              'pmid' => undef,
              'importer' => 'CatalogImporter',
              'year' => '2005',
              'institution' => 'Department of Hygiene and Epidemiology, University of Ioannina School of Medicine, Ioannina, Greece. jioannid@cc.uoi.gr',
              'shortTitle' => undef,
              'uuid' => '{b8558cdb-4d86-4ac0-9831-db22f6894c0d}',
              'favourite' => 'false',
              'confirmed' => 'true',
              'read' => 'false',
              'id' => '2',
              'privacy' => 'NormalDocument',
              'publisher' => 'Public Library of Science',
              'deduplicated' => 'false',
              'genre' => undef,
              'legalStatus' => undef,
              'abstract' => 'Summary: There is increasing concern that most current published research findings are false. The probability that a research claim is true may depend on study power and bias, the number of other studies on the same question, and, importantly, the ratio of true to no relationships among the relationships probed in each scientific field. In this framework, a research finding is less likely to be true when the studies conducted in a field are smaller; when effect sizes are smaller; when there is a greater number and lesser preselection of tested relationships; where there is greater flexibility in designs, definitions, outcomes, and analytical modes; when there is greater financial and other interest and prejudice; and when more teams are involved in a scientific field in chase of statistical significance. Simulations show that for most study designs and settings, it is more likely for a research claim to be false than true. Moreover, for many current scientific fields, claimed research findings may often be simply accurate measures of the prevailing bias. In this essay, I discuss the implications of these problems for the conduct and interpretation of research.',
              'type' => 'JournalArticle',
              'publication' => 'PLoS Medicine',
              'codeVolume' => undef,
              'revisionNumber' => undef,
              'internationalAuthor' => undef,
              'issn' => undef,
              'city' => undef,
              'publicLawNumber' => undef,
              'counsel' => undef,
              'onlyReference' => 'false',
              'owner' => undef,
              'volume' => '2',
              'note' => undef,
              'codeNumber' => undef,
              'reprintEdition' => undef,
              'internationalNumber' => undef
            };
    
    cmp_deeply(
        $rh_document,
        $rh_expected
    );
    
    is(
        $M->get_document('123'),
        undef
    );
    
    is(
        $M->get_document(),
        undef
    );
    
}

{
    ## 
    ## get_all_document_ids()
    
    my $ra_all_ids = $M->get_all_document_ids();
    
    is( scalar(@$ra_all_ids), 5 );
}

{
    ##
    ## set_keyword_for_document()
    
    my $rv = $M->set_keyword_for_document(1,'moo');
    ok ( $rv );

    $rv = $M->set_keyword_for_document(1,'moo');
    ok ( $rv );
     
    my $ra_keywords = 
        $M->get_all_keywords_for_document('1');
        
    my %keywords = map { $_ => 1 } @$ra_keywords;

    ok ( exists $keywords{'moo'} );
    
}

{
    ##
    ## set_tag_for_document()
    
    my $rv = $M->set_tag_for_document(1,'moo');
    ok ( $rv );

    $rv = $M->set_tag_for_document(1,'moo');
    ok ( $rv );
     
    my $ra_tags = 
        $M->get_all_tags_for_document('1');
    
    my %tags = map { $_ => 1 } @$ra_tags;
    
    ok ( exists $tags{'moo'} );
    
}


done_testing();