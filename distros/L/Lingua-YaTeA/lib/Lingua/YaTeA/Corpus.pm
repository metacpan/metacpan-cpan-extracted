package Lingua::YaTeA::Corpus;
use strict;
use warnings;
use Data::Dumper;
use UNIVERSAL;
use Scalar::Util qw(blessed);
use File::Path;
use POSIX qw(log10);

use Lingua::YaTeA::ForbiddenStructureMark;
use Lingua::YaTeA::TestifiedTermMark;
use Lingua::YaTeA::Sentence;
use Lingua::YaTeA::Lexicon;
use Lingua::YaTeA::DocumentSet;
use Lingua::YaTeA::SentenceSet;
use Lingua::YaTeA::WordFromCorpus;
use Lingua::YaTeA::XMLEntities;

use Encode qw(:fallbacks);;


our $VERSION=$Lingua::YaTeA::VERSION;

our $forbidden_counter = 0;
our $tt_counter = 0;
our $split_counter = 0;


sub new
{
    my ($class,$path,$option_set,$message_set) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{PATH} = $path;
    $this->{NAME} = ();
    $this->{LEXICON} = Lingua::YaTeA::Lexicon->new;
    $this->{DOCUMENTS} = Lingua::YaTeA::DocumentSet->new;
    $this->{SENTENCES} = Lingua::YaTeA::SentenceSet->new;
    $this->{WORDS} = [];
    $this->{OUTPUTS} = ();
    $this->setName;


    $this->setOutputFiles($option_set,$message_set);
    return $this;
}

sub preLoadLexicon
{
    my ($this,$sentence_boundary,$document_boundary,$match_type) = @_;
    my $fh = $this->getFileHandle;
    my $word;
    my %lexicon;
    while (! $fh->eof)
    {
	$word = $fh->getline;
	if(
	    ($word=~ /^([^\t]+)\t([^\t]+)\t([^\t]+)$/)
	    &&
	    ($2 ne $sentence_boundary)
	    &&
	    ($2 ne $document_boundary)
	    )
	{
	    if($match_type ne "strict")
	    {
		$lexicon{lc($1)}++; # record IF
		if($match_type eq "loose")
		{
		    $lexicon{lc($3)}++; # record LF
		}
	    }
	    else
	    {
		$lexicon{lc($1)."~".$2}++; # record IF + POS
	    }
	}
    }
    return \%lexicon;
} 


sub _normalizeInputCorpusLine {
    my ($this, $block, $language) = @_;

    my $line;
    my @elems;
    my @elems_out;
    my $new_block = "";
    
    my @septags;

    if ((defined $language) && ($language eq "FR-Flemm")) {
	foreach $line (split /\n/, $block) {
	    $line =~ s/</INF/go;
	    $line =~ s/>/SUP/go;
	    $line =~ s/\t:\t/\tCOLUMN\t/go;
	    
	    @elems = split /\t/, $line;

# 	    warn "-> $line" . scalar(@elems) . "\n";


	    if (scalar(@elems) > 3) {
		# ambiguity in the pos tagging
		my @tmp = split /\s\|\|\s/, $elems[2];
		$elems[2] = shift @tmp;
		$#elems = 2;
	    }
	    if (scalar(@elems)  == 3) {
		@septags = split /:/, $elems[1];
		my $tag;
		if (scalar(@septags) == 2) {
		    $tag = $septags[1];
		} elsif (scalar(@septags) == 3) {
		    $tag = $septags[2];
		} else {
		    $tag = $septags[0];
		}
                # if the tag is PUN(cit)
		if ($tag eq "PUN(CIT)") {
		    $tag = "PUN";
		}
                # if the tag is Sp+Da, it is transformed as SpDa
		$tag =~ s/\+D/D/;
		# if the word is 'une', the postag is corrected
		if ($elems[0] eq "une") {
		    $tag = "Da3fs---";
		}
		# if it's a  present participle, the postag is then Vmpp-----
		if ($tag =~ /Vmpp/) {
		    $tag = "Vmpp-----";
		}
		# if the word is 'l', the postag is corrected
		if (lc($elems[0]) eq "l") {
		    $tag = "Da3-s---";
		}
		$elems[1] = $tag;
	    }
	    if (scalar(@elems)  == 3) {
		$new_block .= join("\t", @elems) . "\n";
	    }
	}
	return($new_block);
    } else {
# 	warn "Language is $language, so nothing to do\n";

	# foreach $line (split /\n/, $block) {
	#     $line =~ s/</INF/go;
	#     $line =~ s/>/SUP/go;
	#     $line =~ s/\t:\t/\tCOLUMN\t/go;
	#     $line =~ s/\t\t+/\t/go;
	#     if($line !~ /^[^\t]*\t[^\t]+\t[^\t]*$/o){	    
	# 	# warn "***********************************\n";
	# 	# warn "Start correction of the line: $line\n";
	# 	@elems = split /\t/, $line;
	# 	if (scalar(@elems) > 3) {
	# 	    # ambiguity in the pos tagging
	# 	    # my @tmp = split /\s\|\|\s/, $elems[2];
	# 	    # $elems[2] = shift @tmp;
	# 	    $#elems = 2;
	# 	} else {
	# 	    if (defined $elems[0]) {
	# 		$elems[2] = $elems[0];
	# 		if (!defined $elems[1]) {
	# 		#     $elems[1] = 'SYM';
	# 		    $elems[1] = $elems[0];
	# 		}
	# 	    } else {
	# 		@elems =();
	# 	    }

	# 	}
	# 	if (scalar(@elems)  == 3) {
	# 	    $new_block .= join("\t", @elems) . "\n";
	# 	}
	#     } else {
	# 	$new_block .= $line . "\n"; 
	#     }
	# }
	# $new_block .= join("\t", @elems) . "\n";
	# return($new_block);
 	return($block);
    }
}


sub read
{
    my ($this,$sentence_boundary,$document_boundary,$FS_set,$testified_set,$match_type,$message_set,$display_language, $language,$debug_fh) = @_;
    my $num_line = 0;
    my $fh = $this->getFileHandle;
    my $block;
  
#    local $/ = "\.\t". $sentence_boundary ."\t\.\n";
    $this->getSentenceSet->addSentence($this->getDocumentSet);
    while (! $fh->eof)
    {
	$block = $this->_normalizeInputCorpusLine(Encode::decode("UTF-8", $this->readSentence($fh,$sentence_boundary)), $language);
	$this->WrapBlock(\$block);
	$this->MarkForbiddenStructures(\$block,$FS_set);
	$this->MarkTestifiedTerms(\$block,$testified_set,$match_type,$debug_fh);
	$this->UnwrapBlock(\$block);
	
	$this->recordWords($block,$sentence_boundary,$document_boundary,\$num_line,$message_set,$display_language);
    }
}

sub readSentence {
    my ($this, $fh, $sentence_boundary) = @_;

#     warn "in readsentence\n";
    my $line;
    my $sentence;
    if (! $fh->eof) {
	do {
	    $line = $fh->getline;
	    # warn "line: $line;\n";
	    $sentence .= $this->correctInputLine($line);
	    # $sentence .= $line;
	} while ((!$fh->eof) && (index($line, "\t$sentence_boundary\t") == -1));
# 	warn "sentence: $sentence\n";
    }
    return($sentence);
}

sub correctInputLine {
    my ($line, $this) = reverse(@_);
    
    my @elems;
    my $tail = "";
    if ($line =~ /(\n+)$/) {
	$tail = $1;
    }
    chomp $line;

    $line =~ s/</INF/go;
    $line =~ s/>/SUP/go;
    $line =~ s/\t:\t/\tCOLUMN\t/go;
    $line =~ s/\t\t+/\t/go;
    if($line !~ /^[^\t]*\t[^\t]+\t[^\t]*$/o){	    
	# warn "***********************************\n";
	# my $line2 = $line;
	# $line2 =~ s/\t/\\t/go;
	# warn "Start correction of the line: " . $line2 . "\n";
	@elems = split /\t/, $line;
	if (scalar(@elems) > 3) {
	    # ambiguity in the pos tagging
	    # my @tmp = split /\s\|\|\s/, $elems[2];
	    # $elems[2] = shift @tmp;
	    $#elems = 2;
	} else {
	    if ((defined $elems[0]) && (length($elems[0])>0)) {
		$elems[2] = $elems[0];
		if (!defined $elems[1]) {
		    #     $elems[1] = 'SYM';
		    $elems[1] = $elems[0];
		}
	    } else {
		@elems =();
	    }
	    
	}
	if (scalar(@elems)  == 3) {
	    # warn "Corrected line: " . join('\t', @elems). "\n";
	    # warn "***********************************\n";
	    return(join("\t", @elems) . $tail);
	} else {
	    # warn "Removing line\n";
	    # warn "***********************************\n";
	    return("");
	}
    } else {
	return($line . $tail); 
    }
     
    return($line . $tail); 
}

sub recordWords
{
    my ($this,$block,$sentence_boundary,$document_boundary,$num_line,$message_set,$display_language) = @_;
    my $word;
    my @words = split /\n/,$block;
    
    foreach $word (@words)
    { # record each word of the sentence
	$$num_line++;
	if ($word !~ /^\s*$/)
	{
	    $this->addWordFromCorpus($word,$sentence_boundary,$document_boundary,$num_line,$message_set,$display_language);
	}
    }
}

sub addWordFromCorpus
{
    my ($this,$form,$sentence_boundary,$document_boundary,$num_line,$message_set,$display_language) = @_;
    my $word;
    chomp $form;
   
    if($form =~ /^[^\t]*\t[^\t]+\t[^\t]*$/o){
	$word = Lingua::YaTeA::WordFromCorpus->new($form,$this->getLexicon,$this->getSentenceSet);
    }
    else{
	if($form =~ /\<\/?FORBIDDEN/)
	{
	    $word = Lingua::YaTeA::ForbiddenStructureMark->new($form);
	}
	else
	{
	    if($form =~ /\<\/?FRONTIER/)
	    {
		$word = Lingua::YaTeA::TestifiedTermMark->new($form);
	    }
	    else
	    {
		warn $message_set->getMessage('INVALID_TOKEN')->getContent($display_language) . $$num_line . $message_set->getMessage('IN_FILE')->getContent($display_language) . $this->getPath . " ($form)";
		die "\n";
	    }
	}
    }
    push @{$this->{WORDS}}, $word;
    $this->incrementCounters($word,$sentence_boundary,$document_boundary);
    return $word;
}

sub incrementCounters
{
    my ($this,$word,$sentence_boundary,$document_boundary) = @_;
   
    if ((blessed($word)) && ($word->isa('Lingua::YaTeA::WordFromCorpus')))
    {
	$Lingua::YaTeA::WordFromCorpus::counter++;
	if ($word->isSentenceBoundary($sentence_boundary))
	{
	    $Lingua::YaTeA::Sentence::counter++;
	    $Lingua::YaTeA::Sentence::in_doc_counter++;
	    Lingua::YaTeA::Sentence::resetStartChar;
	    $this->getSentenceSet->addSentence($this->getDocumentSet);
	}
	else{
	    if ($word->isDocumentBoundary($document_boundary))
	    {
		$this->getDocumentSet->addDocument($word);
		Lingua::YaTeA::Sentence->resetStartChar;
		$this->getSentenceSet->addSentence($this->getDocumentSet);
		Lingua::YaTeA::Sentence->resetInDocCounter;
		$word->updateSentence($this->getSentenceSet);
		$word->updateStartChar;
		
		$Lingua::YaTeA::Sentence::counter++;
		$Lingua::YaTeA::Sentence::in_doc_counter++;
		$this->getSentenceSet->addSentence($this->getDocumentSet);
		
	    }
	    else{
		Lingua::YaTeA::Sentence->updateStartChar($word);
	    }
	}
    }
    
}

sub print
{
    my ($this,$sentence_boundary,$document_boundary) = @_;
    my $word;
    foreach $word (@{$this->{WORDS}} )
    {
	if ((blessed($word)) && ($word->isa("Lingua::YaTeA::WordFromCorpus")))
	{
	    if ($word->isSentenceBoundary($sentence_boundary))
	    {
		print $word->getLexItem->getIF . "\n";	
	    }
	    else
	    {
		if($word->isDocumentBoundary($document_boundary))
		{
		    print "\n" . $word->getLexItem->getIF . "\n";	
		}
		else
		{
		    print $word->getLexItem->getIF . " ";
		}
	    }
	}
	else{
	    print $word->getForm . "\n";
	}
    }
}


sub selectTestifiedTerms {
    my ($this,$block_r,$testified_set,$match_type) = @_;
    my @block_lines = split ("\n", $$block_r);
    my %block_lexicon;
    my $word;
    my $testified;
    my %block_testified_set;

    if((defined $testified_set)	&& ($testified_set->size > 0)) {
	foreach $word (@block_lines) {
	    if ($word=~ /^([^\t]+)\t([^\t]+)\t([^\t]+)$/) {
		if($match_type ne "strict") {
		    $block_lexicon{lc($1)}++; # record IF
		    if($match_type eq "loose") {
			$block_lexicon{lc($3)}++; # record LF
		    }
		}
		else {
		    $block_lexicon{lc($1)."~".$2}++; # record IF + POS
		}
	    }	
	}
	foreach $testified (values %{$testified_set->getTestifiedTerms}) {
	    if($testified->isInLexicon(\%block_lexicon,$match_type) == 1) {
		$block_testified_set{$testified->getID} =  $testified;
	    }
	}
    }
    return \%block_testified_set;
}




sub MarkTestifiedTerms
{
    my ($this,$block_r,$testified_set,$match_type,$debug_fh) = @_;
    my $testified;
    my $reg_exp;
    my $id = 0;
  #   print $debug_fh $$block_r . "\n";
    my $selected_TTs_h = $this->selectTestifiedTerms($block_r,$testified_set,$match_type);

    if (defined $selected_TTs_h)
    {
	foreach $testified (values %$selected_TTs_h)
	{
#	    print $debug_fh $testified->getIF . "\n";
	    $reg_exp = $testified->getRegExp;
	    $$block_r =~ s/($reg_exp)/$this->createAnnotation($1,\$id,$testified)/gei;
	    $$block_r =~ s/\n\n/\n/g;
	}
    }
}

sub createAnnotation
{
    my ($this,$match,$id_r,$testified) = @_;
    my $type;
    
    my $annotation = "\n\<FRONTIER ID=" . $$id_r . " TT=" . $testified->getID . "\>\n" . $match . "\n<\/FRONTIER ID=" . $$id_r . " TT=" . $testified->getID ."\>\n";
    $$id_r++;
    
    return $annotation;
}


sub MarkForbiddenStructures
{
    my ($this,$block_r,$FS_set) = @_;
    my $FS_any_a = $FS_set->getSubset("ANY");
    my $FS;
    my $ID = 0;
    my $reg_exp;
    my $action;
    my $split_after;

    foreach $FS (@$FS_any_a) 
    {
	$action = $FS->getAction;
	$reg_exp = $FS->getRegExp;
	if ($action eq "delete"){
	    $$block_r =~ s/($reg_exp)/\n\<FORBIDDEN ID=$ID ACTION=$action\>$1\<\/FORBIDDEN ID=$ID ACTION=$action\>\n/ig;
	}
	else{
	    if ($action eq "split"){
		$split_after = $FS->getSplitAfter;
		$$block_r =~ s/($reg_exp)/\n\<FORBIDDEN ID=$ID ACTION=$action SPLIT\_AFTER=$split_after\>$1\<\/FORBIDDEN ID=$ID ACTION=$action SPLIT\_AFTER=$split_after\>\n/ig;
	    }
	}
	$ID++;
    }
}

sub WrapBlock
{
    my ($this,$block_r) = @_;
    $$block_r =~ s/\r//g;
    $$block_r =~ s/^/\n/;
    $$block_r =~ s/$/\n/;
}

sub UnwrapBlock
{
    my ($this,$block_r) = @_;
    $$block_r =~ s/^\n//;
    $$block_r =~ s/\n$//;
}





sub chunk
{
    my ($this,$phrase_set,$sentence_boundary,$document_boundary,$chunking_data,$FS_set,$tag_set,$parsing_pattern_set,$testified_term_set,$option_set,$fh) = @_;
    my $word;
    my $i;
    my @words;
    my $action;
    my $split_after = -1;
    my $valid;
    my $num_content_words;
    my @clean_corpus;
    my $term_frontiers_h;
    my $compulsory = $option_set->getCompulsory;
    my $max_length = $option_set->getMaxLength;

    print STDERR "MAX_LENGTH: " .  $max_length . "\n";
    for ($i = 0; $i <= $this->size; $i++){
	$word = $this->getWord($i);
	if ((defined $fh) && (defined $word))
	{
	    $word->print($fh);
	}
	# if (defined $word) {
	#     print STDERR "> ($word)";
	#     $word->print(\*STDERR);
	# }
	if(
	    ($i == $this->size) # last word of the corpus
	    ||
	    ($word->isChunkEnd(\$action,\$split_after,$sentence_boundary,$document_boundary,$chunking_data) == 1)
	    )
	{
	    ($valid,$num_content_words,$term_frontiers_h) = $this->cleanChunk(\@words,$chunking_data,$FS_set,$option_set->getCompulsory,$tag_set,$fh);
	    # print STDERR "====$valid\n";
	    # foreach my $w (@words) {
	    # 	$w->print(\*STDERR);
	    # }
	    # print STDERR "====\n";
	    
	   if ($valid == 1)
	   {
	       $phrase_set->recordOccurrence(\@words,$num_content_words,$tag_set,$parsing_pattern_set,$option_set,$term_frontiers_h,$testified_term_set,$this->getLexicon,$this->getSentenceSet,$fh);
		$Lingua::YaTeA::Corpus::tt_counter = 0;
	   }
	   
	   @words = ();
	    
	}
	else{
	    push @words, $word;
	}


#	warn "ref= " . ref($word) . "\n";
	if((defined $word) && ((blessed($word)) && ($word->isa('Lingua::YaTeA::WordFromCorpus'))))
	{
	    push @clean_corpus,$word;
	}
    }

    $this->{WORDS} = \@clean_corpus;

}


sub cleanChunk
{
    my ($this,$words_a,$chunking_data,$FS_set,$compulsory,$tag_set,$fh) = @_;
    my $num_content_words;
    my $term_frontiers_h;
    
    if ($this->pruneFromStart($words_a,$chunking_data,$FS_set,$fh) == 1)
    {
	
	if($this->pruneFromEnd($words_a,$chunking_data,$FS_set,$fh) == 1)
	{
	    if($this->checkCompulsory($words_a,$compulsory,$fh) == 1)
	    {
		($num_content_words,$term_frontiers_h) = $this->deleteAnnotationMarks($words_a,$tag_set,$fh);
		return (1,$num_content_words,$term_frontiers_h);
	    }
	    return (0,0);
	}
	return  (0,0); # no words left
    }
    return (0,0); # no words left
}


sub deleteAnnotationMarks
{
    my ($class,$words_a,$tag_set,$fh) = @_;
    my $word;
    my @tmp;
    my $content_words = 0;
    my $index = 0;
    my %term_frontiers;
    my $frontier;

    foreach $word (@$words_a){
	if ((blessed($word)) && ($word->isa("Lingua::YaTeA::WordFromCorpus")))
	{
	    if ($tag_set->existTag('CANDIDATES',$word->getPOS))
	    {
		$content_words++;
	    }
	    push @tmp, $word;
	    $index++;
	}
	else
	{
	    if ((blessed($word)) && ($word->isa("Lingua::YaTeA::TestifiedTermMark")))
	    {
		if($word->isOpener)
		{
		    $term_frontiers{$word->getID} = $word;
		    $word->{START} = $index; # should use setStart
		}
		else
		{
		    if($word->isCloser)
		    {
			$frontier = $term_frontiers{$word->getID};
			$frontier->{END} = $index;   # should use setEnd
		    }
		}
	    }
	}
    }
    @$words_a = @tmp;
    
    return ($content_words,\%term_frontiers);
}




sub pruneFromStart
{
    my ($this,$words_a,$chunking_data,$FS_set,$fh) = @_;
    my $i =0;
    my $word;
    my $potential_FS_a;
    my $inside_testified = 0;
    my %testified_frontiers;
  

    while ($i < scalar @$words_a)
    {
	$word = $words_a->[$i];

	if ((blessed($word)) && ($word->isa('Lingua::YaTeA::TestifiedTermMark')))
	{
	    return 1;
	}
	else
	{
	    if ((blessed($word)) && ($word->isa('Lingua::YaTeA::WordFromCorpus')))
	    {
		
		if ($word->isCleaningFrontier($chunking_data))
		{
		    if(
			#  ($inside_testified == 0)
# 		    &&
# 		    ($word->isa('Lingua::YaTeA::WordFromCorpus'))
# 		    && 
			($potential_FS_a = $word->isStartTrigger($FS_set->getTriggerSet("START")))
			)
		    {
			if(!$this->expandStartTriggers($potential_FS_a,$words_a,$fh))
			{
			    last;
			}
		    }
		    else
		    {
			last;
		    }
		}
		
		
	    }
	    shift @$words_a; # delete element
	}
    }
    if(scalar @$words_a > 0)
    {
	return 1;
    }
    return 0;
}

sub pruneFromEnd
{
    my ($this,$words_a,$chunking_data,$FS_set,$fh) = @_;
    my $i = $#$words_a;
    my $word;
    my $potential_FS_a;
    my $inside_testified = 0;
    my %testified_frontiers;
    my $deleted = 0;
  
    while ($i >= 0)
    {
	$word = $words_a->[$i];

	if ((blessed($word)) && ($word->isa('Lingua::YaTeA::TestifiedTermMark')))
	{
	    return 1;
	}
	else
	{
	    if ((blessed($word)) && ($word->isa('Lingua::YaTeA::WordFromCorpus')))
	    {
		if ($word->isCleaningFrontier($chunking_data))
		    
		{
		    if(
			($inside_testified == 0)
			&&
			((blessed($word)) && ($word->isa('Lingua::YaTeA::WordFromCorpus')))
			&& 
			($potential_FS_a = $word->isEndTrigger($FS_set->getTriggerSet("END")))
			)
		    {
			if(!$this->expandEndTriggers($potential_FS_a,$words_a,$fh))
			{
			    last;
			}
			else
			{
			    $deleted = 1;
			    if(scalar @$words_a == 0)
			    {
				return 0;
			    }
			    else
			    {
				$i = $#$words_a;
			    }
			}
		    }
		    else
		    {
			last;
		    }
		}
	    }
	    if ((blessed($word)) && ($word->isa('Lingua::YaTeA::ForbiddenStructureMark')))
	    {
		my $del = pop @$words_a; # delete element
		$i--;  
	    }
	    else
	    {
		if($deleted == 0)
		{
		    my $del = pop @$words_a; # delete element
		    $i--;
		}
	    }
	    $deleted = 0;
	    
	    
	}
    }
    if(scalar @$words_a > 0)
    {
	return 1;
    }
    return 0;
}




sub checkCompulsory
{
    my ($this,$words_a,$compulsory,$fh) = @_;
    my $word;
    foreach $word (@$words_a)
    {
	if (!((blessed($word)) && ($word->isa('Lingua::YaTeA::ForbiddenStructureMark'))))
	{
	    
	    if (
		((blessed($word)) && ($word->isa('Lingua::YaTeA::TestifiedTermMark')))
		||
		($word->isCompulsory($compulsory))
		)
	    {
		return 1;
	    }	
	}
    }
    return 0;
}



sub getWord
{
    my ($this,$i) = @_;
    return $this->{WORDS}->[$i];
}

sub size
{
    my ($this) = @_;
    return scalar @{$this->{WORDS}};
}


sub expandStartTriggers
{
    my ($this,$potential_FS_a,$words_a,$fh) = @_;
    my $FS;
    my $i;
    my $j;
    my $to_find;
    my $to_delete;

    foreach $FS (@$potential_FS_a)
    {
	
	if($FS->getLength <= scalar @$words_a)
	{
	    $to_delete = $FS->apply($words_a);
	    if(defined $to_delete)
	    {
		last;
	    }
	    
	}	
    }
    if(defined $to_delete)
    {
	while($to_delete != 1)
	{
	    if ((blessed($words_a->[0])) && ($words_a->[0]->isa('Lingua::YaTeA::TestifiedTermMark')))
	    {
		return 1;
	    }
	    else
	    {
		my $del = shift @$words_a;
		$to_delete--;
	    }
	}
	return 1;
    }
    return 0;
}


sub expandEndTriggers
{
    my ($this,$potential_FS_a,$words_a,$fh) = @_;
    my $FS;
    my $i;
    my $j;
    my $to_find;
    my $to_delete;

    foreach $FS (@$potential_FS_a)
    {
	
	if($FS->getLength <= scalar @$words_a)
	{
	    $to_delete = $FS->apply($words_a);
	    if(defined $to_delete)
	    {
		last;
	    }
	}	
    }
    if(defined $to_delete)
    {
	while($to_delete != 0)
	{
	    if ((blessed($words_a->[$#$words_a])) && ($words_a->[$#$words_a]->isa('Lingua::YaTeA::TestifiedTermMark')))
	    {
		return 1;
	    }
	    else
	    {
		my $w = pop @$words_a;
		$to_delete--;
	    }
	}
	return 1;
    }
    return 0;
}

sub getSentenceSet
{
    my ($this) = @_;
    return $this->{SENTENCES};
}

sub getDocumentSet
{
    my ($this) = @_;
    return $this->{DOCUMENTS};
}

sub getFileHandle
{
    my ($this) = @_;
    my $path = $this->getPath;
#    print STDERR "corpus :" . $path . "\n";
    my $fh = FileHandle->new("<$path");
#    binmode($fh, ":utf8");
    return $fh;
}

sub getPath
{
    my ($this) = @_;
    return $this->{PATH};
}

sub getName
{
    my ($this) = @_;
    return $this->{NAME};
}

sub getOutputFileSet
{
    my ($this) = @_;
    return $this->{OUTPUT};
}

sub getLexicon
{
    my ($this) = @_;
    return $this->{LEXICON};
}

# the name of the file is what appears after the last "/" and before the last "." if any
sub setName
{
    my ($this) = @_;
    
    if($this->getPath =~ /\/?([^\/]+)\.[^\.]+$/)
    {
	$this->{NAME} = $1;
    }
    else
    {
	$this->getPath =~ /\/?([^\/]+)$/;
	$this->{NAME} = $1;
    }
}

sub setOutputFiles
{
    my ($this,$option_set,$message_set) = @_;
    my $sub_dir;
    my $option;
    my $file;
    my @files;
    my $file_info;
    my $output_path;
    my $no_output_defined = 1;
    my %match_to_option= (
	'xmlout'=>'xml:candidates.xml',
	'TT-for-BioLG'=>'xml:TTforBioLG.xml',
	'TC-for-BioLG'=>'xml:TCforBioLG.xml',
	'termList'=>'raw:termList.txt',
	'termAndHeadList'=>'raw:termAndHeadList.txt',
	'printChunking'=>'html:candidatesAndUnparsedInCorpus.html',
	'debug'=>'raw:debug,unparsable,unparsed',
	'TTG-style-term-candidates' => 'raw:termCandidates.ttg',
	'XML-corpus-for-BioLG' => 'xml:corpusForBioLG.xml',
	'bootstrap' => 'raw:parsedTerms.txt',
        'XML-corpus-raw' => 'xml:corpusRaw.xml',
	);
    
    $output_path = $option_set->getOutputPath ."/". $this->getName . "/" . $option_set->getSuffix;

    if(-d $output_path)
    {
	print STDERR $message_set->getMessage('OVER_WRITE_REP')->getContent($option_set->getDisplayLanguage) . $output_path . "/\n";
	rmtree $output_path;
    }
#     else
#     {
	mkpath $output_path;
	print STDERR $message_set->getMessage('CREATE_REP')->getContent($option_set->getDisplayLanguage) . $output_path . "/\n";
#     }
    $this->{OUTPUT} = Lingua::YaTeA::FileSet->new($this->getName);
  
    while (($option,$file_info) = each (%match_to_option))
    {
	if($option_set->optionExists($option))
	{
	    $this->setFilesForOption($file_info,$output_path);
	    $no_output_defined = 0;
	}
    }
    if($no_output_defined == 1)
    {
	$this->setFilesForOption($match_to_option{'xmlout'},$output_path);
    }
    $option_set->addOption('default_output',$no_output_defined);
}

sub setFilesForOption
{
    my ($this,$file_info,$sub_dir) = @_;
    my @files;
    my $file;
    my $sub_sub_dir;
    $file_info =~ /^([^:]+):(.+)$/;
    @files = split (/,/,$2);
    $sub_sub_dir = $sub_dir . "/" . $1;
    if(! -d $sub_sub_dir)
    {
	mkdir $sub_sub_dir;
    }
    foreach $file (@files)
    {
	$this->{OUTPUT}->addFile($sub_sub_dir,$file);
    }   
}

sub printCorpusForLGPwithTCs
{
    my ($this,$term_candidates_h,$output_file,$sentence_boundary,$document_boundary,$lgp_mapping_file,$chained_links,$tag_set) = @_;
  
    my ($occurrences_h,$mapping_to_TCs_h) = $this->orderOccurrencesForXML($term_candidates_h);
    my $LGPmapping_h = $this->loadLGPmappingFile($lgp_mapping_file->getPath);
    $this->printXMLcorpus($occurrences_h,$output_file->getPath,$sentence_boundary,$document_boundary,$mapping_to_TCs_h,$LGPmapping_h,$chained_links,$tag_set);
}


sub printCorpusForLGPwithTTs
{
    my ($this,$testified_terms_h,$output_file,$sentence_boundary,$document_boundary,$lgp_mapping_file,$parsing_direction,$chained_links,$tag_set) = @_;

    my ($occurrences_h,$mapping_to_TTs_h) = $this->orderOccurrencesForXML($testified_terms_h);
    $this->getBestOccurrences($occurrences_h,$parsing_direction);
    my $LGPmapping_h = $this->loadLGPmappingFile($lgp_mapping_file->getPath);
    $this->printXMLcorpus($occurrences_h,$output_file->getPath,$sentence_boundary,$document_boundary,$mapping_to_TTs_h,$LGPmapping_h,$chained_links,$tag_set);
}


sub getBestOccurrences
{
    my ($this,$occurrences_h,$parsing_direction) = @_;
    my $doc;
    my $sentence;
    my @occurrences;
    my $occurrence;
    my $occurrence_set;
    my $same_start;
    foreach $doc (values %$occurrences_h)
    {
	foreach $sentence (values %$doc)
	{
	    @occurrences = ();
	    foreach $same_start (values %$sentence)
	    {
		foreach $occurrence (@$same_start){
		    push @occurrences, $occurrence;
		}
		
	    }
	    foreach $occurrence (@occurrences)
	    {
		if($occurrence->isNotBest(\@occurrences,$parsing_direction))
		{
		    $this->removeOccurrence($occurrences_h,$occurrence->getDocument->getID,$occurrence->getSentence->getID,$occurrence->getStartChar,$occurrence->getID);
		 
		}
	    }
	    
	}
    }
   
}


sub removeOccurrence
{
    my ($this,$occurrences_h,$doc,$sentence,$start_char,$occ_id) = @_;
    my @tmp;
    my $occurrence;
    my $occurrences_set = $occurrences_h->{$doc}{$sentence}{$start_char};
    if(scalar @$occurrences_set == 1)
    {
	delete $occurrences_h->{$doc}{$sentence}{$start_char};
    }
    else
    {
	foreach $occurrence (@$occurrences_set)
	{
	    if($occurrence->getID != $occ_id)
	    {
		push @tmp, $occurrence;
	    }
	}
	@{$occurrences_h->{$doc}{$sentence}{$start_char}} = @tmp;
    }
}

sub printCorpusForBioLG{
    my ($this,$output_file,$sentence_boundary,$document_boundary,$chained_links) = @_;
  
    my %occurrences;
    my %BioLGmapping;
    my %mapping_to_TTs;
 
    $this->printXMLcorpus(\%occurrences,$output_file->getPath,$sentence_boundary,$document_boundary,\%mapping_to_TTs,\%BioLGmapping,$chained_links);
}



sub printXMLcorpus
{
    my ($this,$occurrences_h,$output_file_path,$sentence_boundary,$document_boundary,$mapping_to_TCs_h,$LGPmapping_h,$chained_links,$tag_set) = @_;
    my $word;
    my $sentence;
    my $sentence_id;
    my $document_id;
    my $occurrence;
    my $tc;
    my $head_word;
    my $head_index;
    my $local_occurrences_a;
    my $links_a;
    my $counter = 0;
    my $pos;
    my $if;
    my $i;
    my $tc_length;
    my $occurrence_set;
    
    my $fh = FileHandle->new(">" . $output_file_path);
    binmode($fh, ":utf8");
    $this->printXMLheader($fh);
 
    for ($i=0; $i < scalar @{$this->getWords}; $i++)
    {
	$word = $this->getWords->[$i];
	if(! $word->isDocumentBoundary($document_boundary))
	{

	    if(exists $occurrences_h->{$word->getDocumentID}{$word->getSentenceID}{$word->getStartChar})
	    {
		$occurrence_set = $occurrences_h->{$word->getDocumentID}{$word->getSentenceID}{$word->getStartChar};
		$occurrence = $occurrence_set->[0];

		    $tc = $mapping_to_TCs_h->{$occurrence->getID};
		    $tc_length = $tc->getLength;
		    
		# previous and next words are not coordinations: to be removed when coordination will be handled ?
		    if(
			(
			 ($i == 0)
			 ||
			 (!($tag_set->existTag('COORDINATIONS',$this->getWords->[$i-1]->getPOS)))
			)
			&&
			(
			 ($i == (scalar @{$this->getWords} -1))
			 ||
			 (!($tag_set->existTag('COORDINATIONS',$this->getWords->[$i + $tc_length]->getPOS)))
			)
			)
		    {
			
			($head_word,$head_index,$links_a) = $tc->getHeadAndLinks($LGPmapping_h,$chained_links);
			$counter++;
			$pos = $head_word->getPOS;
			$if = $head_word->getIF;
			Lingua::YaTeA::XMLEntities::encode($pos);
			Lingua::YaTeA::XMLEntities::encode($if);
			$sentence .= "<term c=\"" . $pos . "\" parse_as=\"" . $if . "\"";
			if(scalar $links_a > 0)
			{
			    $sentence .= " internal=\"" . join ("",@$links_a) . "\"";
			}
			$sentence .= " head=\"" . $head_index . "\">";
			
		    }
		    else
		    {
			undef $occurrence;
		    }
	    }
	    $pos = $word->getPOS;
	    $if = $word->getIF;
	    Lingua::YaTeA::XMLEntities::encode($pos);
	    Lingua::YaTeA::XMLEntities::encode($if);
	    $sentence .= "<w c=\"" . $pos . "\">" . $if . "</w> ";
	    
	    if (
		(defined $occurrence)
		&&
		($occurrence->getEndChar == $word->getStartChar + $word->getLexItem->getLength)
		)
	    {
		undef $occurrence;
		$sentence .= "</term>";
	    }
	    if($word->isSentenceBoundary($sentence_boundary))
	    {
		$sentence =~ s/\s*$//;
		$sentence .= "</sentence>";
		$sentence_id = $word->getSentence->getID;
		$document_id = $word->getDocument->getID;
		$local_occurrences_a = $occurrences_h->{$document_id}{$sentence_id};
	
		print $fh $sentence . "\n";
		$sentence = "<sentence>";
	    }
	}
	
    }
    # corpus ended without a final dot
    if($sentence ne "<sentence>")
    {
	$sentence .= "</sentence>";
	print $fh $sentence;
    }
    print STDERR $counter . " terms marked\n";
    $this->printXMLtrailer($fh);
}

sub printXMLheader
{
    my ($this,$fh) = @_;
    print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<sentences><sentence>";	
}

sub printXMLtrailer
{
    my ($this,$fh) = @_;
    print $fh "\n</sentences>\n";	
}

sub loadLGPmappingFile
{
    my ($this,$file_path) = @_;
    
    my $fh = FileHandle->new("<$file_path");
    my %mapping;
    my $line;
    while ($line= $fh->getline)
    {
	if(($line !~ /^\s*$/)&&($line !~ /^\s*#/)) # line is not empty nor commented
	{
	    $line =~ /^([^\t]+)\t([^\t]+)\s*\n$/;
	    $mapping{$1} = $2;
	}
    }
    return \%mapping;
}


sub printCandidatesAndUnparsedInCorpus
{
    my ($this,$term_candidates_h,$unparsable_a,$file,$sentence_boundary,$document_boundary,$color_blind_option, $parsed_color, $unparsed_color) = @_;
    my %ids_for_parsed;
    
#    my $fh = FileHandle->new(">".$file->getPath);

    my $fh;
    if ($file eq "stdout") {
	$fh = \*STDOUT;
    } else {
	if ($file eq "stderr") {
	    $fh = \*STDERR;
	} else {
	    $fh = FileHandle->new(">".$file->getPath);
	}
    }
    binmode($fh, ":utf8");


    $this->printHTMLheader($fh);
    my $occurrences_h = $this->orderOccurrences($term_candidates_h,$unparsable_a,\%ids_for_parsed);
 
    $this->printHTMLCorpus($occurrences_h,\%ids_for_parsed,$fh,$sentence_boundary,$document_boundary,$color_blind_option, $parsed_color, $unparsed_color);
    $this->printHTMLtrailer($fh);
}


sub printHTMLheader
{
    my ($this,$fh) = @_;
    print $fh
    "<html>\n<head>\n<title>Term Candidates and unparsed phrases in Corpus</title>\n</head><body>";	
}

sub printHTMLtrailer
{
    my ($this,$fh) = @_;
    print $fh
    "</body></html>";	
}

sub printXMLRawCorpus
{
    my ($this,$file,$sentence_boundary,$document_boundary) = @_;
    my $sentence_id;
    my $document_id;
    my $document_name;
    my $word;
    my $first_sentence = 1;
    my $in_doc = 0;
    my $string;
    my $last_word;
    my $fh = FileHandle->new(">".$file->getPath);
    binmode($fh,":utf8");
    $this->printXMLheader($fh);
    print $fh " <documentCollection>\n";
    foreach $word (@{$this->getWords})
    {
	if($word->isDocumentBoundary($document_boundary)) # new document is started
	{
	    if($in_doc == 1)
	    {
		if(!$last_word->isSentenceBoundary($sentence_boundary)) # last word of document is not a sentence boundary
		{
		    $string =~ s/ $//;
		    Lingua::YaTeA::XMLEntities::encode($string);
		    print $fh "   <sentence id=\"" . $word->getSentence->getID . "\" inDocID=\"" . $word->getSentence->getInDocID . "\">" .  $string . "</sentence>\n";
		    $string = "";
		}
		print $fh "  </document>\n";
	    }
	    print $fh "  <document id=\"" . $word->getDocument->getID . "\"";
	    if($word->getDocument->getName ne 'no_name')
	    {
		print $fh " name=\"". $word->getDocument->getName . "\"";
	    }
	    print $fh ">\n";
	    $in_doc = 1 ;
	}
	else
	{
	    # rebuild the sentence from occurrences of words from the corpus
	    $string .= $word->getIF . " ";
	    $last_word = $word;
	    if($in_doc == 0) # if no explicit marker of document boundary in the input document
	    {
		print $fh "  <document id=\"" . $word->getDocument->getID . "\"";
		if($word->getDocument->getName ne 'no_name')
		{
		    print $fh " name=\"". $word->getDocument->getName . "\"";
		}
		print $fh ">\n";
		$in_doc = 1;
	    }
	    if (
		($word->isSentenceBoundary($sentence_boundary)) # new sentence is started
		||
		($word == $this->getWords->[$#{$this->getWords}]) # last word of the corpus (no final dot)
		)
	    {
		$string =~ s/ $//;
		Lingua::YaTeA::XMLEntities::encode($string);
		print $fh "   <sentence id=\"" . $word->getSentence->getID . "\" inDocID=\"" . $word->getSentence->getInDocID . "\">" .  $string . "</sentence>\n";
		$string = "";
		if($word == $this->getWords->[$#{$this->getWords}])
		{
		    print $fh "  </document>\n";
		}
	    }
	}

    }
    print $fh " </documentCollection>\n";
}


sub printHTMLCorpus
{
    my ($this,$parsed_occurrences_h,$ids_for_parsed_h,$fh,$sentence_boundary,$document_boundary,$color_blind_option, $parsed_color, $unparsed_color) = @_;
    my $sentence_id;
    my $document_id;
    my $document_name;
    my $word;
    my $occurrence;
    my $local_occurrences_a;
    my $string;
    my $offset = 0;
    my $string_copy;
    my $color;
  
    
    foreach $word (@{$this->getWords})
    {
	if($word->isDocumentBoundary($document_boundary)) # new sentence is started
	{
	    print $fh "<BR><B>Document " . $word->getDocument->getID;
	    if($word->getDocument->getName ne 'no_name')
	    {
		print $fh " - ". $word->getDocument->getName;
	    }
	    print $fh "</B><BR>";
	}
	else
	{
	    # rebuild the sentence from occurrences of words from the corpus
	    $string .= $word->getIF . " ";
	    if (
		($word->isSentenceBoundary($sentence_boundary)) # new sentence is started
		||
		($word == $this->getWords->[$#{$this->getWords}]) # last word of the corpus (no final dot)
		)
	    {
		$string =~ s/ $//;
		# get the term candidates occurrences for the next sentence
		$sentence_id = $word->getSentence->getID;
		$document_id = $word->getDocument->getID;
		$document_name = $word->getDocument->getName;
		
		$local_occurrences_a = $parsed_occurrences_h->{$document_id}{$sentence_id};
		# mark term candidates on the rebuilt sentence
		foreach $occurrence (@$local_occurrences_a)
		{
		    $color = $this->setColor($occurrence->getID,$ids_for_parsed_h,$color_blind_option, $parsed_color, $unparsed_color);
		    if(!defined $offset)
		    {
			die;
		    }
		    $string_copy .= substr($string,$offset,$occurrence->getStartChar - $offset). "<B><FONT COLOR =\"" . $color . "\">";
		    $string_copy .= substr($string,$occurrence->getStartChar,$occurrence->getEndChar - $occurrence->getStartChar) . "</FONT></B>";
		    $offset = $occurrence->getEndChar;
		    
		    if(! substr($string,$offset-1))
		    {
			print STDERR "problem d'offset pour la phrase DOC:" . $document_id . " - SENT: " . $sentence_id . "\n";
			print STDERR $string . "\n";
		    }
		}

		$string_copy .= substr($string,$offset);
		print $fh $word->getSentence->getInDocID . ":" . $string_copy . "<BR>\n";
		$string = "";
		$string_copy  = "";
		$offset = 0;
	    }
	}
    }
}


sub setColor
{
    my ($this,$occurrence_id,$ids_for_parsed_h,$color_blind_option, $parsed_color, $unparsed_color) = @_;
    my $color;
    
    if(exists $ids_for_parsed_h->{$occurrence_id})
    {
	if($color_blind_option->getValue eq 'yes')
	{
	    if (defined $parsed_color) {
		$color = $parsed_color->getValue;
	    } else {
		$color = "FF0099";
	    }
	}
	else
	{
	    if (defined $parsed_color) {
		$color = $parsed_color->getValue;
	    } else {
		$color = "CC0066";
	    }
	}
    }
    else
    {
	if($color_blind_option->getValue eq 'yes')
	{
	    if (defined $unparsed_color) {
		$color = $unparsed_color->getValue;
	    } else {
		$color = "0000CC";
	    }
	} 
	else
	{
	    if (defined $unparsed_color) {
		$color = $unparsed_color->getValue;
	    } else {
		$color = "3366CC";
	    }
	}
    }
    return $color;
}

sub orderOccurrencesForXML
{
    my ($this,$term_h) = @_;
    my %occurrences;
    my %mapping_to_TCs;
    my $document;
    my $sentence;
    my $occurrence;
    my $term;
    my $unparsable;
    my $sent_hash;
    my $occurrences_a;

    foreach $term (values (%$term_h))
    {

       	foreach $occurrence (@{$term->getOccurrences})
	{
	    # only the occurrences covering an entire phrase are selected
	    if(
		((blessed($term)) && ($term->isa('Lingua::YaTeA::TestifiedTerm')))
		||
		($occurrence->isMaximal)
		)
	    {
		push @{$occurrences{$occurrence->getDocument->getID}{$occurrence->getSentence->getID}{$occurrence->getStartChar}},  $occurrence;
		$mapping_to_TCs{$occurrence->getID} = $term;	
	    }
	   
	}
    }
    return (\%occurrences,\%mapping_to_TCs);
}



sub orderOccurrences
{
    my ($this,$term_candidates_h,$unparsable_a,$ids_for_parsed_h) = @_;
    my %occurrences;
    my $document;
    my $sentence;
    my $occurrence;
    my $term_candidate;
    my $unparsable;
    my $sent_hash;
    my $occurrences_a;


    foreach $term_candidate (values (%$term_candidates_h))
    {
       	foreach $occurrence (@{$term_candidate->getOccurrences})
	{
	    if($occurrence->isMaximal)
	    {
		push @{$occurrences{$occurrence->getDocument->getID}{$occurrence->getSentence->getID}}, $occurrence;
		$ids_for_parsed_h->{$occurrence->getID}++;	
	    }
	}
    }
    foreach $unparsable (@$unparsable_a)
    {
       	foreach $occurrence (@{$unparsable->getOccurrences})
	{
	    if($occurrence->isMaximal)
	    {
		push @{$occurrences{$occurrence->getDocument->getID}{$occurrence->getSentence->getID}}, $occurrence;
	    }
	}
    }
    while (($document,$sent_hash) = each (%occurrences))
    {
	while (($sentence,$occurrences_a) = each (%$sent_hash))
	{
	    @$occurrences_a = sort ({$a->getStartChar <=> $b->getStartChar} @$occurrences_a);
	}
 
    }	
    return \%occurrences;
}

sub getWords
{
    my ($this) = @_;
    return $this->{WORDS};
}

sub selectOnTermListStyle {
    my ($this, $term_candidates_h,$term_list_style,$debug_fh) = @_;

    my $tc;
    # warn "selectOnTermListStyle ($term_list_style)\n";
    foreach $tc (values (%$term_candidates_h))
    {
	# warn $tc->getIF . "\n";
	# warn ($tc->isa('Lingua::YaTeA::MultiWordTermCandidate') * 1) . "\n";
	if (($term_list_style ne "") && ($term_list_style ne "all") &&
	    (($term_list_style ne "multi") || ((blessed($tc)) && ($tc->isa('Lingua::YaTeA::MultiWordTermCandidate') != 1)))) {
		$tc->setTermStatus(0);
	}
	# warn "" . (1 * $tc->getTermStatus) . "\n";
	# warn "  " . ($tc->isTerm * 1) . "\n";
    }    
}

sub makeDDW
{
    my ($this,$term_candidates_h,$fh) = @_;
    my $tc_weight;
    my $mean_occ;
    my $total_occ = 0;
    my $total_doc = $this->getDocumentSet->getDocumentNumber;
    my %doc_by_tc;
    my %docs_for_this_tc;
    my $tc;
    my $occ;


    foreach $tc (values (%$term_candidates_h))
    {
	%docs_for_this_tc  = ();
	foreach $occ (@{$tc->getOccurrences})
	{	    
	    $docs_for_this_tc{$occ->getDocument->getID}++;
	    $total_occ++;
	}
	$doc_by_tc{$tc->getKey} = scalar keys(%docs_for_this_tc);
    }
    if (scalar(keys(%$term_candidates_h)) > 0) {
	$mean_occ = $total_occ / scalar keys %$term_candidates_h;
    } else {
	$mean_occ = 0;
    }
    foreach $tc (values (%$term_candidates_h))
    {
	##### measure 'descriptor discriminating weight' described in 'Building back-of-the-book indexes', Nazarenko, Ait El Mekki (2005)
	##### PROBLEM: each time there is only one document in the corpus, the value is 0 (log10(1/1) = 0)
	$tc_weight =  ($tc->getFrequency/$mean_occ) * log10 ($total_doc/$doc_by_tc{$tc->getKey});
	$tc->setWeight($tc_weight);
    }
}

sub processTotalDocOccurrences
{
    my ($this,$occurrences_h) = @_;
    my $total;
    my $occ;
#    print STDERR $occurrences_h. "\n";
    foreach $occ (values (%$occurrences_h))
    {
	$total +=  $occ;
    }
    return $total;
}


1;

__END__

=head1 NAME

Lingua::YaTeA::Corpus - Perl extension for ???

=head1 SYNOPSIS

  use Lingua::YaTeA::Corpus;
  Lingua::YaTeA::Corpus->();

=head1 DESCRIPTION


=head1 METHODS


=head2 new()


=head2 preLoadLexicon()


=head2 read()


=head2 recordWords()


=head2 addWordFromCorpus()


=head2 incrementCounters()


=head2 print()


=head2 selectTestifiedTerms()


=head2 MarkTestifiedTerms()


=head2 createAnnotation()


=head2 MarkForbiddenStructures()


=head2 WrapBlock()


=head2 UnwrapBlock()


=head2 chunk()


=head2 cleanChunk()


=head2 deleteAnnotationMarks()


=head2 pruneFromStart()


=head2 pruneFromEnd()


=head2 checkCompulsory()


=head2 getWord()


=head2 size()


=head2 expandStartTriggers()


=head2 expandEndTriggers()


=head2 getSentenceSet()


=head2 getDocumentSet()


=head2 getFileHandle()


=head2 getPath()


=head2 getName()


=head2 getOutputFileSet()


=head2 getLexicon()


=head2 setName()


=head2 setOutputFiles()


=head2 setFilesForOption()


=head2 printCorpusForLGPwithTCs()


=head2 printCorpusForLGPwithTTs()


=head2 getBestOccurrences()


=head2 removeOccurrence()


=head2 printCorpusForBioLG{()


=head2 printXMLcorpus()


=head2 printXMLheader()


=head2 printXMLtrailer()


=head2 loadLGPmappingFile()


=head2 printCandidatesAndUnparsedInCorpus()


=head2 printHTMLheader()


=head2 printHTMLtrailer()


=head2 printHTMLCorpus()


=head2 setColor()


=head2 orderOccurrencesForXML()


=head2 orderOccurrences()


=head2 getWords()


=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
