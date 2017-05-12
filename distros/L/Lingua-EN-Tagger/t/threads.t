# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 12;
use Lingua::EN::Tagger;

ok('Lingua::EN::Tagger', 'module compiled'); # If we made it this far, we're ok.

######################################
# Start by creating the parser object
# (without the stemmer)
######################################
ok($tagger = Lingua::EN::Tagger->new( stem => 0, weight_noun_phrases => 0, longest_noun_phrase => 15 ), 'creating parser object' );

SKIP: {
    eval { 
        require threads;
        require threads::shared;
    };

    skip "threading support not available, skip threading tests", 10 if $@;

    eval {
        ok($shared = threads::shared::shared_clone($tagger), 'creating shared object');
    };
    skip "threading support not available, skip threading tests", 10 if $@;

    sub tag {
        $text = shift;
        return $shared->get_readable($text);
    }

    ok($penn = threads->new(\&tag, penn()), 'started thread with text');
    ok($hyphen = threads->new(\&tag, hyphen()), 'started thread with hyphens');
    ok($jibberish = threads->new(\&tag, jibberish()), 'started thread with unknown words');

    ok($accuracy = compute_accuracy($penn->join, penn_benchmark()), 'computing accuracy');
    cmp_ok($accuracy, '>=', 95, "overall accuracy ($accuracy%)");

    ok($accuracy = compute_accuracy($hyphen->join, hyphen_benchmark()), 'computing accuracy');
    cmp_ok($accuracy, '>=', 100, "overall accuracy ($accuracy%)");

    ok($accuracy = compute_accuracy($jibberish->join, jibberish_benchmark()), 'computing accuracy');
    cmp_ok($accuracy, '>=', 80, "overall accuracy ($accuracy%)");
}




###############################################
# Words that mostly don't occur in the lexicon
###############################################
sub jibberish {
        return "Nils occludes the 5 corybantic sciolists from fressing upon the
        northeast-oriented perambulations of the yabbering doyenne";
}
sub jibberish_benchmark {
        return "Nils/NNP occludes/VBZ the/DET 5/CD corybantic/JJ sciolists/NNS from/IN
        fressing/VBG upon/IN the/DET northeast-oriented/JJ perambulations/NNS of/IN
        the/DET yabbering/VBG doyenne/NN";
}

##########################################################
# Hyphenated words that mostly don't occur in the lexicon
##########################################################
sub hyphen {
        # brother-in-law not in lexicon, sister-in-law is
        return "The brother-in-law. The sister-in-law. A strategy of tit-for-tat among
        middle-eastern states.";
}
sub hyphen_benchmark {
        return "The/DET brother-in-law/NN ./PP The/DET sister-in-law/NN ./PP A/DET
        strategy/NN of/IN tit-for-tat/NN among/IN middle-eastern/JJ states/NNS ./PP";
}


####################################################
# Test the tagger against an actual tagged corpus
####################################################
sub penn { 
        return <<PENN 
        Lisa Raines, a lawyer and director of government relations for the Industrial Biotechnical Association, contends that a judge well-versed in patent law and the concerns of research-based industries would have ruled otherwise. And Judge Newman, a former patent lawyer, wrote in her dissent when the court denied a motion for a rehearing of the case by the full court, "The panel's judicial legislation has affected an important high-technological industry, without regard to the consequences for research and innovation or the public interest." Says Ms. Raines, "[The judgement] confirms our concern that the absence of patent lawyers on the court could prove troublesome." 
PENN
}
        
sub penn_cleaned {
        qr|Lisa Raines , a lawyer and director of government relations for the Industrial Biotechnical Association , contends that a judge well-versed in patent law and the concerns of research-based industries would have ruled otherwise \. And Judge Newman , a former patent lawyer , wrote in her dissent when the court denied a motion for a rehearing of the case by the full court , `` The panel 's judicial legislation has affected an important high-technological industry , without regard to the consequences for research and innovation or the public interest \. '' Says Ms\. Raines , `` \[ The judgement \] confirms our concern that the absence of patent lawyers on the court could prove troublesome \. ''|i 
}


sub penn_benchmark {
        return <<BENCHMARK
Lisa/NNP Raines/NNP ,/PPC a/DET lawyer/NN and/CC director/NN of/IN government/NN relations/NNS for/IN the/DET Industrial/NNP Biotechnical/NNP Association/NNP ,/PPC contends/VBZ that/IN a/DET judge/NN well-versed/JJ in/IN patent/NN law/NN and/CC the/DET concerns/NNS of/IN research-based/JJ industries/NNS would/MD have/VB ruled/VBN otherwise/RB ./PP And/CC Judge/NNP Newman/NNP ,/PPC a/DET former/JJ patent/NN lawyer/NN ,/PPC wrote/VBD in/IN her/PRPS dissent/NN when/WRB the/DET court/NN denied/VBD a/DET motion/NN for/IN a/DET rehearing/NN of/IN the/DET case/NN by/IN the/DET full/JJ court/NN ,/PPC ``/PPL The/DET panel/NN 's/POS judicial/JJ legislation/NN has/VBZ affected/VBN an/DET important/JJ high-technological/JJ industry/NN ,/PPC without/IN regard/NN to/TO the/DET consequences/NNS for/IN research/NN and/CC innovation/NN or/CC the/DET public/JJ interest/NN ./PP ''/PPR Says/VBZ Ms./NNP Raines/NNP ,/PPC ``/PPL [/LRB The/DET judgement/NN ]/RRB confirms/VBZ our/PRPS concern/NN that/IN the/DET absence/NN of/IN patent/NN lawyers/NNS on/IN the/DET court/NN could/MD prove/VB troublesome/JJ ./PP ''/PPR 
BENCHMARK
}



sub compute_accuracy {
        my ( $test, $benchmark ) = @_;
        my @tokenized = split /\s+/, $test;
        my @model = split /\s+/, $benchmark;
        my $accurate = 0;
        my $num_items = scalar @tokenized;
        for( my $i=0; $i <= $#tokenized; $i++ ){
                
                my ( $my_word, $my_tag, $word, $tag );
                ( $my_word, $my_tag ) = $tokenized[$i] =~ /^(.*)\/([A-Z]+)$/
                        if $tokenized[$i];
                ( $word, $tag ) = $model[$i] =~ /^(.*)\/([A-Z]+)$/ 
                        if $model[$i];
                if( $my_word ne $word ){
                        shift @model;
                        next;
                }
                $accurate++ if $my_tag eq $tag;
        }
        return sprintf( "%.1f", 100 * $accurate / $num_items);
                        
}

