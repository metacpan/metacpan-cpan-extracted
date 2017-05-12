# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 21;
use Lingua::EN::Tagger;

ok('Lingua::EN::Tagger', 'module compiled'); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.



######################################
# Start by creating the parser object
######################################

ok( $parser = Lingua::EN::Tagger->new( stem => 1), 'creating parser object' );


########################################
# Check various cases of punctuation
# with the private _split_punct() method
########################################
like( join( " ", $parser->_split_punct( '"word!")') ), qr/`` word \! '' \)/, 'punctuation 1'); 
like( join( " ", $parser->_split_punct( '"word.")') ), qr/`` word\. '' \)/, 'punctuation 2' ); 
like( join( " ", $parser->_split_punct( 'word--word') ), qr/word - word/, 'punctuation 3' ); 
like( join( " ", $parser->_split_punct( "didn't." ) ), qr/did n't\./, 'punctuation 4' ); 
like( join( " ", $parser->_split_punct( "(she'll)" ) ), qr/\( she 'll \)/, 'punctuation 5' ); 
like( join( " ", $parser->_split_punct( "'that's'" ) ), qr/` that 's '/, 'punctuation 6' ); 
like( join( " ", $parser->_split_punct( '"we\'ve"' ) ), qr/`` we 've ''/, 'punctuation 7' ); 
like( join( " ", $parser->_split_punct( '"o\'er"' ) ), qr/`` o'er ''/, 'punctuation 8' ); 
like( join( " ", $parser->_split_punct( 'naïve' )), qr/naïve/, 'punctuation 9' );
like( join( " ", $parser->_split_punct( "China's" ) ), qr/China 's/, 'punctuation 10' );
like( join( " ", $parser->_clean_text( 'We, naïve souls, drank tea in a café.' ) ), qr/We , naïve souls , drank tea in a café ./, 'punctuation 11' );
# Make sure that it doesn't die when parsing a non-text sample
ok( $parser->add_tags( "#!/usr/bin/perl -w\nuse strict;\nmy \$var = 'hello world';
print \$var | 'no value'; "), "non-text sample");

########################
# Check the stemmer
########################
is( $parser->stem( 'realize' ), 'realiz', 'stemming word' );


###############################################
# If all the above tests pass, we can now
# test the _clean_text() method on a real text
###############################################
$text = penn();
$cleaned = penn_cleaned();

ok( @words = $parser->_clean_text( $text ), 'cleaning text' );
$my_cleaned = join( " ", @words );
like( $my_cleaned, $cleaned, 'checking cleaned text' );
is( $parser->add_tags( '' ), undef, 'checking empty string' );
is( $parser->add_tags(), undef, 'checking NULL string' );

########################################
# Add and remove POS tags with the
# add_tags() and _strip_tags() methods
# the result should be like $cleaned
########################################
ok( $tagged = $parser->add_tags( $text ), 'adding POS tags' );
like( $parser->_strip_tags( $tagged ), $cleaned, 'removing POS tags' );



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





