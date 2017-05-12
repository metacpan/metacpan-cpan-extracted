#!/var/local/gna/bin/perl5


=pod
These are various procedures to guess topics

Use refine_topics1
=cut

my(@exclude_words) = 
    ("the", "and", "to", "of", "a", "an","for", "what", "are", "in", "our");

my($remap_table) = {
    "masters"=>"master",
    "bachelors"=>"bachelor"
    };

my($exclude_table) = {
    "master"=>["science", "arts"],
    "bachelor"=>["science", "arts"],
    "associate"=>["science", "arts"]
};

require 'edit-catalog.pl';
use strict;

my($table) = $::catalog_file;
my($table1) = $::tabledir . "/wordtable1.rdb";
my($topic_list) = $::tabledir . "/topics.rdb";

sub use_bayes {
    my($title, $restrict) = @_;
    my(%prob) = ();
    my($word, $exclude_word, $topic, $score);
    
  topicloop:
    foreach $word (split(/\s+/, $title)) {
	$word =~ tr/A-Z/a-z/;
#print "Looking for $word\n";
	foreach $exclude_word (@exclude_words) {
	    if ($word eq $exclude_word) {
#		print "  Ignoring\n";
		next topicloop;
	    }
	}
	my(%transfer_prob) = ();
	open (DATA, "echo '$word' | search -mi conting.rdb word |");
	$_ = <DATA>;
	$_ = <DATA>;
	while (<DATA>) {
	    ($topic, $word, $score) = split(/\t/, $_);
	    $transfer_prob{$topic} = $score;
	}
	close(DATA);
	
	my(%new_prob) = ();
	foreach $word (keys %transfer_prob) {
	    if ($prob{$word} ne "") {
		$new_prob{$word} = $prob{$word} * $transfer_prob{$word};
	    } else {
		$new_prob{$word} = 0.01 * $transfer_prob{$word};
	    }
	}

	foreach $word (keys %prob) {
	    if ($new_prob{$word} eq "") {
		$new_prob{$word} = 0.01 * $prob{$word};
	    }
	}

	if ($restrict ne "") {
	    foreach $word (keys %prob) {
		if ($word !~ /^$restrict/) {
		    delete $new_prob{$word};
		}
	    }
	}

# Normalize
	my($norm) =0.0;
	foreach $word (keys %new_prob) {
	    $norm += $new_prob{$word};
	}
	
	foreach $word (keys %new_prob) {
	    $new_prob{$word} /= $norm;
	}
	
	%prob = %new_prob;

#print "Probablity vector table\n---------------------\n";
#foreach $word (keys %new_prob) {
#print "$word\t$prob{$word}\n";
#}
}
    return %prob;
}

sub find_top {
    my ($probref, $number) = @_;

    my(@topic_list);
    my($I, $J);
    if ($number eq "") {
	$number = 1;
    }

    my($word);
  wordloop:
    foreach $word (keys (%{$probref})) {
        my(@list) = split(/;/, $word);
        my($words) = $#list;
	my($i);
	for ($i=0; $i < $number; $i++) {
	    my(@list_count) = split(/;/, $topic_list[$i]);
	    my($topic_count) = $#list_count;
	    my($j);

	    if ($topic_list[$i] eq "" ||
		$probref->{$word} > $probref->{$topic_list[$i]} ||
($probref->{$word} == $probref->{$topic_list[$i]}
&&
$words > $topic_count)) {
		for ($j=$number-1; $j > $i; $j--) {
		    $topic_list[$j] = $topic_list[$j-1];
		}
		$topic_list[$i] = $word;
		next wordloop;
	    }
	}
    }
    return @topic_list;
}

sub refine_topic {
    my($title, $listref) = @_;
    local($_, *FILE);
    my(%array) = ();
    my(@title_words) = split(/\s+/, $title);
    my($check_topic);

    foreach $check_topic (@{$listref}) {
        open(FILE, "echo '$check_topic' | search -mi -x $table topic | column title topic | headoff |");
        while (<FILE>) {
	    my($test, $topic) = split(/[\t\n]/);
	    $test =~ y/A-Z/a-z/;
	    my(@test_words) = split(/\s+/, $test);

            my(%bucket) = ();
            my(%title_words) = ();
	    my(%test_words) = ();
            my($match_count) = 0;
            my($total_word_count) = 0;
	    my($word);
            foreach $word (@title_words) {
                $bucket{$word} = 1;
                $title_words{$word} = 1;
            }
            foreach $word (@test_words) {
		$bucket{$word} = 1;
		$test_words{$word} = 1;
	    }
	    my(%exclude_words);
            foreach $word (keys %bucket) {
                if (! $exclude_words{$word}) {
                    if ($title_words{$word} == 1
			&& $test_words{$word} == 1) {
                        $match_count ++;
                    }
                    $total_word_count++;
                }
	    }
            my($scale_factor) = $match_count / $total_word_count;
            if ($scale_factor > $array{$topic}) {
                $array{$topic} = $scale_factor;
            }
        }
        close(FILE);
    }

    return (%array);
}

sub refine_topic1 {
    my($title, $listref) = @_;
    local($_, *FILE);
    my(%array) = ();
    my($cache_file) = "/tmp/topic.cache.$$";

    my($title_words) = &tokenize_title($title, $remap_table);
    my($exclude_words) = 
	&get_exclude_list($title_words,
			  \@exclude_words,
			  $exclude_table);

     my($check_topic, $word_score);

    foreach $check_topic (@{$listref}) {
	if ($check_topic eq "") {
	    if (!-e $cache_file) {
		`column title topic < $table > $cache_file`;
	    }
	    open(FILE, $cache_file);
	} else {
	    open(FILE, "echo '$check_topic' | search -mi -x $table topic | column title topic | headoff |");
	}
        while (<FILE>) {
	    my($test, $topic) = split(/[\t\n]/);
	    $test =~ y/A-Z/a-z/;
	    my(@test_words) = split(/\s+/, $test);
	    my($has_word) = 0;
            my(%bucket) = ();
            my(%title_words) = ();
	    my(%test_words) = ();
            my($match_count) = 0;
            my($total_word_count) = 0;
	    my($word);
            foreach $word (@test_words) {
                if (! $exclude_words->{$word}) {
		    $bucket{$word} = 1;
		    $test_words{$word} = 1;
		}
	    }

            foreach $word (@$title_words) {
                if (! $exclude_words->{$word}) {
		    if ($bucket{$word} == 1) {
			$has_word = 1;
		    }
		    $bucket{$word} = 1;
		    $title_words{$word} = 1;
		}
            }
	    if ($has_word) {
		foreach $word (keys %bucket) {
		    if (! $exclude_words->{$word}) {
			if ($title_words{$word} > 0 &&
			    $test_words{$word} > 0) {
			    $word_score = &get_word_score($topic,$word);
			    $match_count += $word_score;
#			    print "$word -> $word_score\n";
			    if ($word_score > 0) {
				$total_word_count += 
				    &get_word_score($topic,$word);
			    } else {
				$total_word_count += 1;
			    }
			} else {
			    $total_word_count += 1;
			}
		    }
		}
		my($scale_factor) = $match_count / $total_word_count;
		
		if ($scale_factor > $array{$topic}) {
#		    print "-->$topic $test $scale_factor\n";
		    $array{$topic} = $scale_factor;
		}
	    }
        }			# 
        close(FILE);
    }

    return (%array);
}

my(%cache) = ();
my(%loaded) = ();
sub get_word_score {
    my($topic, $word) = @_;
    my($foo, $foo1, $foo2, $score);
    if (!defined($loaded{$word})) {
#	print "Loading $word\n";
	open(FILE1, "echo '$word' | search -mb $table1 word | ");
	$foo = <FILE1>;
	$foo = <FILE1>;
	while ($foo = <FILE1>) {
	    ($foo1, $foo2, $score) = split(/[\t\n]+/, $foo);
	    $cache{$foo2 . "//" . $foo1} = $score;
	}
	close(FILE1);
	$loaded{$word}  = 1;
	if ($score eq "") {$score = 0;}
#	print "$topic - $word - $score\n";
	return  $cache{$word . "//" . $topic};
    } else {
	return $cache{$word . "//" . $topic};
    }
}

use strict;

sub tokenize_title {
    my ($title, $remap) = @_;
    my (@word_list) = ();
    my ($word);
    foreach $word (split(/[\s\-\:]+/, $title)) {
	$word =~ tr/A-Z/a-z/;
	$word =~ s/[:\(\)\"\'\,\?\-\;\*\&\#\.\/]//g;
	$word =~ s/<.*?>//g;
	if ($remap->{$word} ne "") {
	    $word = $remap->{$word};
#	    print "Mapping $word to $remap->{$word}\n";
	}
	push(@word_list, $word);
    }
    return \@word_list;
}

sub get_exclude_list {
    my ($title_word_list, $global_excludes, $local_exclude) = @_;
    my ($exclude_list) = {};
    my ($word, $word1);
    foreach $word (@$global_excludes) {
	$exclude_list->{$word} = 1;
    }
    foreach $word (@$title_word_list) {
	if (defined($local_exclude->{$word})) {
	    foreach $word1 (@{$local_exclude->{$word}}) {
		$exclude_list->{$word1} = 1;
	    print "Excluding $word -> $word1\n";
	    }
	}
    }
    return $exclude_list;
}

sub guess_topic {
    my($fref, $assignh) = @_;

    my($title) = $fref->{'title'} ne "" ? 
	$fref->{'title'} : $fref->{'name'};
    my($id) = $fref->{'classid'} ne "" ? 
	$fref->{'classid'} : $fref->{'progid'};
    my($topic) = $fref->{'topic'};

    my($topich) = IO::File->new($topic_list);
    my($logstring) = "";
    my(%in, %guess );
    @in{"topic", "title", "classid"} = ($topic, $title, $id);

    $in{"title"} =~ y/A-Z/a-z/;
    $in{"classid"} =~ y/A-Z/a-z/;

# Try to see if topics is already assigned
    if ($in{"classid"} ne "") {
      $topic = `echo "$in{'classid'}" | search -mi $::tabledir/catalog.rdb-c classid | column topic | headoff | head -1`;
	chop $topic;
     if ($topic ne "") {
        $in{"topic"} = $topic;
     }
}

# Ignore headers
    $topich->getline();
    $topich->getline();

    while ($_ = $topich->getline()) {
	/^\s*$/ && next;
	/^#/ && next;
	chop;
	@guess{"oldtopic", "title", "classid", "newtopic"} = 
	    split(/\|/, $_);
	my($match) = 1;
	foreach (keys %guess) {
	    if ($guess{$_} eq "" || $_ eq "newtopic") {
		next;
	    }
	    if ($_ eq "oldtopic") {
		if ($guess{"oldtopic"} eq "*") {
		    next;
		} elsif ($guess{"oldtopic"} eq "" && $in{"topic"} ne "") {
		    $match = 0; last;
		} elsif ($in{"topic"} !~ m!^$guess{"oldtopic"}!) {
		$match = 0; last;
	    }
	    } elsif ($in{$_} !~ /$guess{$_}/) {
		$match = 0; last;
	    }
	}
	
	if ($match) {

	    if ($guess{"newtopic"} =~ /^\+/) {
	        $guess{"newtopic"} =~ s/\+//;
		if ($in{"topic"} ne "" && $in{"topic"} !~ /$guess{"newtopic"}/
&& $in{'topic'} !~ /Countries/ && $in{'topic'} !~ /Regions/) {
		    $in{"topic"} .= ";" . $guess{"newtopic"};
		}
	    } else {
		($in{"topic"} = $guess{"newtopic"});
	    
	    }
	}
    }
    $topich->close();
    if ($in{"topic"} eq "") {
	$logstring .= 
	    join(":", "NOTOPIC" ,@in{"classid", "title"}) . "\n";
    } else {
	$logstring .= 
	    join(":", @in{"topic", "classid", "title"}) . "\n";
    }
    my($check_topic) = 
	&gna_catalog_edit_check_topic($::catalog_file, $in{'topic'}); 

	
    if ($check_topic ne "") {
	$logstring .= "   ****$check_topic \n";	
    }
    if ($check_topic =~ /too many/i || $in{'topic'} eq "") {
	$logstring .= "   *** Refining ";
	my(%prob_vec) = &refine_topic1($in{'title'}, [$in{'topic'}]);
	my($new_topic) = &find_top(\%prob_vec, 1);
	if ($new_topic ne "") {
	    $logstring .= "to $new_topic";
	    $in{'topic'} = $new_topic;
	}
	$logstring .= "\n";
    }
    if (defined($assignh)) {
	$assignh->print($logstring);
	$assignh->flush();
    }
    return $in{"topic"};
}



1;



