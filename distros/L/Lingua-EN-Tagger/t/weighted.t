# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 10;
use Lingua::EN::Tagger;

ok('Lingua::EN::Tagger', 'module compiled'); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.



######################################
# Start by creating the parser object
# (without the stemmer)
######################################
ok( $parser = Lingua::EN::Tagger->new( stem => 0, weight_noun_phrases => 1, longest_noun_phrase => 15 ), 'creating parser object' );
$tagged = $parser->add_tags( penn() );

ok( %words = $parser->get_words( penn() ), 'get_words() method' );
$accuracy = compute_accuracy( \%words, np_benchmark() );
is( $accuracy, '100', "accuracy of np extraction ($accuracy%)" );

##############################################
# Test the extraction of maximal noun phrases
##############################################
ok( %max_noun_phrases = $parser->get_max_noun_phrases( $tagged ), 'extract MNPs' );
$accuracy = compute_accuracy( \%max_noun_phrases, mnp_benchmark() );
is( $accuracy, '100', "accuracy of mnp extraction ($accuracy%)" );


##############################################
# Test the extraction of all noun phrases
##############################################
ok( %noun_phrases = $parser->get_noun_phrases( $tagged ), 'extract noun phrases' );
$accuracy = compute_accuracy( \%noun_phrases, np_benchmark() );
is( $accuracy, '100', "accuracy of np extraction ($accuracy%)" );

##############################################
# Test the extraction of all nouns
##############################################
ok( %nouns = $parser->get_nouns( $tagged ), 'extract nouns' );
$accuracy = compute_accuracy( \%nouns, noun_benchmark() );
is( $accuracy, '100', "accuracy of np extraction ($accuracy%)" );


sub compute_accuracy {
        ( $hash_ref, $benchmark ) = @_;
        ( $errors, $i ) = ( 0 )x2;
        foreach( keys %{ $hash_ref } ){
                $i++;
                unless( defined $benchmark->{$_} ){
                        # warn "$_ not in benchmark\n";
                        $errors++, 
                        next;
                }
                $i++;
                unless ( $hash_ref->{$_} == $benchmark->{$_} ){
                        # warn $_.": ".$hash_ref->{$_}." != ".$benchmark->{$_}." (benchmark)\n";
                        $errors++;
                }
        }
        foreach( keys %{ $benchmark } ){
                $i++;
                unless( defined $hash_ref->{$_} ){
                        # warn "$_ not defined in extraction\n";
                        $errors++;
                }
        }
        return sprintf( "%d", 100 * ( 1 - $errors / $i ) );
}

sub mnp_benchmark {
        $hash_ref = { 'lisa raines' => 1,
                        'lawyer' => 1,
                        'director of government relations for the industrial biotechnical association' => 1,
                        'judge' => 1,
                        'patent law' => 1,
                        'concerns of research-based industries' => 1,
                        'judge newman' => 1,
                        'former patent lawyer' => 1,
                        'dissent' => 1,
                        'court' => 1,
                        'motion for a rehearing of the case by the full court' => 1, 
                        'panel' => 1,
                        'judicial legislation' => 1,
                        'important high-technological industry' => 1,
                        'regard' => 1,
                        'consequences for research' => 1,
                        'innovation' => 1,
                        'public interest' => 1,
                        'ms. raines' => 1,
                        'judgement' => 1,
                        'concern that the absence of patent lawyers on the court' => 1
                };
        return $hash_ref;
}

sub noun_benchmark {
        $hash_ref = { 'lisa' => 1,
                        'raines' => 2,
                        'lawyer' => 2,
                        'director' => 1,
                        'relations' => 1,
                        'government' => 1,
                        'association' => 1,
                        'judge' => 2,
                        'patent' => 3,
                        'law' => 1,
                        'concerns' => 1,
                        'industries' => 1,
                        'newman' => 1,
                        'dissent' => 1,
                        'court' => 3,
                        'motion' => 1,
                        'rehearing' => 1,
                        'case' => 1,
                        'panel' => 1,
                        'legislation' => 1,
                        'industry' => 1,
                        'regard' => 1,
                        'consequences' => 1,
                        'research' => 1,
                        'innovation' => 1,
                        'interest' => 1,
                        'ms.' => 1,
                        'judgement' => 1,
                        'concern' => 1,
                        'industrial' => 1,
                        'biotechnical' => 1,
                        'absence' => 1,
                        'lawyers' => 1
                };
        return $hash_ref;
}

sub np_benchmark {
        $hash_ref = { 'lisa' => 1,
                        'raines' => 2,
                        'lawyer' => 2,
                        'director' => 1,
                        'relations' => 1,
                        'government' => 1,
                        'association' => 1,
                        'judge' => 2,
                        'patent' => 3,
                        'law' => 1,
                        'concerns' => 1,
                        'industries' => 1,
                        'newman' => 1,
                        'dissent' => 1,
                        'court' => 3,
                        'motion' => 1,
                        'rehearing' => 1,
                        'case' => 1,
                        'panel' => 1,
                        'legislation' => 1,
                        'industry' => 1,
                        'regard' => 1,
                        'consequences' => 1,
                        'research' => 1,
                        'innovation' => 1,
                        'interest' => 1,
                        'ms.' => 1,
                        'judgement' => 1,
                        'concern' => 1,
                        'industrial' => 1,
                        'biotechnical' => 1,
                        'absence' => 1,
                        'lawyers' => 1,
                        'lisa raines' => 2,
                        'director of government relations for the industrial biotechnical association' => 9,
                        'patent law' => 2,
                        'concerns of research-based industries' => 4,
                        'judge newman' => 2,
                        'former patent lawyer' => 3,
                        'motion for a rehearing of the case by the full court' => 11,
                        'judicial legislation' => 2,
                        'important high-technological industry' => 3,
                        'consequences for research' => 3,
                        'public interest' => 2,
                        'ms. raines' => 2,
                        'concern that the absence of patent lawyers on the court' => 10,
                        'government relations' => 2,
                        'industrial biotechnical association' => 3,
                        'biotechnical association' => 2,
                        'research-based industries' => 2,
                        'patent lawyer' => 2,
                        'full court' => 2,
                        'high-technological industry' => 2,
                        'patent lawyers' => 2
                };      
        return $hash_ref;

}

#       Lisa Raines, a lawyer and director of government relations for the Industrial Biotechnical Association, contends that a judge well-versed in patent law and the concerns of research-based industries would have ruled otherwise. And Judge Newman, a former patent lawyer, wrote in her dissent when the court denied a motion for a rehearing of the case by the full court, "The panel's judicial legislation has affected an important high-technological industry, without regard to the consequences for research and innovation or the public interest." Says Ms. Raines, "[The judgement] confirms our concern that the absence of patent lawyers on the court could prove troublesome." 
                        



###############################################
# Words that mostly don't occur in the lexicon
###############################################
sub jibberish {
        return "Nils occludes the 5 corybantic sciolists from fressing upon the
        northeast-oriented perambulations of the yabbering doyenne";
}


##########################################################
# Hyphenated words that mostly don't occur in the lexicon
##########################################################
sub hyphen {
        # brother-in-law not in lexicon, sister-in-law is
        return "The brother-in-law. The sister-in-law. A strategy of tit-for-tat among
        middle-eastern states.";
}



####################################################
# Test the tagger against an actual tagged corpus
####################################################
sub penn { 
        return <<PENN 
        Lisa Raines, a lawyer and director of government relations for the Industrial Biotechnical Association, contends that a judge well-versed in patent law and the concerns of research-based industries would have ruled otherwise. And Judge Newman, a former patent lawyer, wrote in her dissent when the court denied a motion for a rehearing of the case by the full court, "The panel's judicial legislation has affected an important high-technological industry, without regard to the consequences for research and innovation or the public interest." Says Ms. Raines, "[The judgement] confirms our concern that the absence of patent lawyers on the court could prove troublesome." 
PENN
}
        

