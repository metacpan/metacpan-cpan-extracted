#!/usr/bin/perl -w
package Lingua::IW::Logical;

use strict;
use integer;

require Exporter;

@Lingua::IW::Logical::ISA = qw(Exporter);
@Lingua::IW::Logical::EXPORT = qw(log2vis_string log2vis_text);
@Lingua::IW::Logical::EXPORT_OK = qw(set_debug);
$Lingua::IW::Logical::VERSION="0.5";

################################################################################
#   Logical-Visual Hebrew subroutines
#   Author: Stanislav Malyshev <frodo@sharat.co.il>
#   Date: 02/08/1998
#   Based on the algorithm from the book 'The Unicode Standard, Version 2.0'
#   Redistribution and modification of the code is allowed freely under LGPL terms
################################################################################

my($ALEPH,$TAV,$debug,$STRONG_RTL,$STRONG_LTR,$WEAK_EN,$WEAK_CS,$WEAK_ET,$WEAK_ES,$NEUTRAL_WS,$NEUTRAL_ON,%mirror);

$ALEPH='à';
$TAV='ú';
$debug=0;   # put 1 here for full report of what algorithm is doing

# this is entity-type constants
# see Unicode 2.0, page 4-11
$STRONG_RTL=0;
$STRONG_LTR=1;
$WEAK_EN=2;
$WEAK_CS=3;
$WEAK_ET=6;
$WEAK_ES=7;
$NEUTRAL_WS=4;
$NEUTRAL_ON=5;

# This is the list of "mirrored" characters
# see Unicode 2.0, page 4-22
%mirror = (
	   '(' => ')',
	   ')' => '(',
	   '[' => ']',
	   ']' => '[',
	   '{' => '}',
	   '}' => '{',
	   );

# subroutine to get type of a character
# needs to be converted to a hash for efficiency
sub get_type {
    my($l)=@_;
    return $STRONG_RTL if($l ge $ALEPH && $l le $TAV);
    return $STRONG_LTR if($l =~ /[a-zA-Z]/);
    return $WEAK_EN if($l =~ /[0-9]/);
    return $WEAK_ET if($l =~ m|[-\$%+\^#]|);
    return $WEAK_ES if($l =~ m%[./\(\)]%);
    return $WEAK_CS if($l =~ /[:,;]/);
    return $NEUTRAL_WS if($l =~ /\s/);

    return $NEUTRAL_ON;
}

sub set_debug {
    my($db)=@_;
    $debug=$db;
}

# main reverse subroutine
# expects text in "logical" encoding, converts to "visual"

sub log2vis_string ($) {
    my($str)=@_;
    my($i)=();
    return $str unless $str =~ /[$ALEPH-$TAV]/o; # shortcut - no hebrew
    
    my($len)=length($str);
    # making levels
    my(@str_types)=map { &get_type($_) } split(//,$str); # get character types

    print "{",join(":",@str_types),"}\n" if $debug;

    # resolving weak types
    # see page 3-15 to 3-23
    for($i=0;$i<$len;$i++) {
	
	# EN,ES,EN -> EN,EN,EN
	if($str_types[$i] == $WEAK_ES && $str_types[$i-1] == $WEAK_EN && $str_types[$i+1] == $WEAK_EN) {
		$str_types[$i]=$WEAK_EN;
		next;
	}
	
	# EN,CS,EN -> EN,EN,EN
	if($str_types[$i] == $WEAK_CS && $str_types[$i-1] == $WEAK_EN && $str_types[$i+1] == $WEAK_EN) {
		$str_types[$i]=$WEAK_EN;
		next;
	}

	# EN, ET -> EN,EN
	if($i>0 && $str_types[$i-1] == $WEAK_EN && $str_types[$i] == $WEAK_ET && $str_types[$i+1] != $STRONG_RTL) {
		$str_types[$i]=$WEAK_EN;
		next;
	}

	# ET, EN -> EN,EN
	if($str_types[$i+1] == $WEAK_EN && $str_types[$i] == $WEAK_ET) {
		$str_types[$i]=$WEAK_EN;
		next;
	}

	# otherwise: L, ES, EN -> L, N, EN
	# etc.
	## if($i>0 && $str_types[$i-1] == $STRONG_LTR && $str_types[$i+1] == $WEAK_EN) {
	if($str_types[$i] == $WEAK_CS || $str_types[$i] == $WEAK_ES || $str_types[$i] == $WEAK_ET) {
	    $str_types[$i]=$NEUTRAL_ON;
	    next;
	}

    } ## for
    
    print "<",join(":",@str_types),">\n" if $debug;

    # making directions
    # r - RTL, l - LTR, n - neutral (takes current direction), e - embedding level direction
    
    my($levels)='-' x $len;     # initially characters have no directionality
    my($base)='';               # base directionality of the string
    my($last_strong,@next_strong)=();
    for($i=0;$i<$len;$i++) {
	# first strong character is LTR - all before are LTR
	if($str_types[$i] == $STRONG_LTR) {
	    substr($levels,$i,1) = 'l';
#	    substr($levels,0,$i) = 'l' x $i unless $base;
	    $base='l' unless $base;
	    for(my($j)=$last_strong;$j<$i;$j++) { $next_strong[$j]=$STRONG_LTR; }
	    $last_strong=$i;
	    next;
	}

	# first strong character is RTL - all before are RTL
	if($str_types[$i] == $STRONG_RTL) {
	    substr($levels,$i,1) = 'r';
#	    substr($levels,0,$i) = 'r' x $i unless $base;
	    $base='r' unless $base;
	    for(my($j)=$last_strong;$j<$i;$j++) { $next_strong[$j]=$STRONG_RTL; }
	    $last_strong=$i;
	    next;
	}
	
	# directioning neutrals
	if($str_types[$i] == $NEUTRAL_ON || $str_types[$i] == $NEUTRAL_WS) {
	
	    # RNR -> RRR
	    if($str_types[$i-1] == $STRONG_RTL && $str_types[$i+1] == $STRONG_RTL) {
		substr($levels,$i,1)='r';
		next;
	    }
	    
	    # LNL -> LLL
	    if($str_types[$i-1] == $STRONG_LTR && $str_types[$i+1] == $STRONG_LTR) {
		substr($levels,$i,1)='l';
		next;
	    }
	    
	    # RNL -> ReL
	    if($str_types[$i-1] == $STRONG_RTL && $str_types[$i+1] == $STRONG_LTR) {
		substr($levels,$i,1)='e';
		next;
	    }
	    
	    # LNR -> LeR
	    if($str_types[$i-1] == $STRONG_LTR && $str_types[$i+1] == $STRONG_RTL) {
		substr($levels,$i,1)='e';
		next;
	    }
	    
	    # RNW -> RR?
	    if($str_types[$i-1] == $STRONG_RTL && $str_types[$i+1] == $WEAK_EN) {
		substr($levels,$i,1)='r';
		next;
	    }

	    # LNW -> LL?
	    if($str_types[$i-1] == $STRONG_LTR && $str_types[$i+1] == $WEAK_EN) {
		substr($levels,$i,1)='l';
		next;
	    }
	    
	    # if basic directionality is RTL : WNL -> ?LL
	    if($base == 'r' && $str_types[$i-1] == $WEAK_EN && $str_types[$i+1] == $STRONG_LTR) {
		substr($levels,$i,1)='l';
		next;
	    }

	    # if basic directionality is RTL : WNR -> ?RR
	    if($base == 'r' && $str_types[$i-1] == $WEAK_EN && $str_types[$i+1] == $STRONG_RTL) {
		substr($levels,$i,1)='r';
		next;
	    }

	    substr($levels,$i,1)='e';  # default for neutrals is 'e'
	    next;
	}

	# weak entity
	if($str_types[$i] == $WEAK_EN) { 
	    substr($levels,$i,1) = 'n';
	    next;
	}

	substr($levels,$i,1) = 'e';  # if not matched - take 'e'
    }

    print $levels,"\n" if $debug;

    # compose string
    my($dir)=$base; ##substr($str,0,1);   # current direction
    my($cursor)=0;
    my($outstr)='';
    my($nowdir)=$dir;
    for($i=0;$i<$len;$i++) {
	my($c)=substr($str,$i,1);
	if(substr($levels,$i,1) eq 'l') {
	    $dir = 'l';
	}
	if(substr($levels,$i,1) eq 'r') {
	    $dir = 'r';
	}

	if(substr($levels,$i,1) eq 'e') {
	    if($dir eq 'r' && $next_strong[$i] == $STRONG_LTR) {
		# $dir = 'l';
	    } 
	    elsif($dir eq 'l' && $next_strong[$i] == $STRONG_RTL) {
		$dir = 'r'
		}
	    elsif($next_strong[$i] == '') {
		$dir = $base;
	    }
	}

	$nowdir=$dir;
	
	# space between LTR and RTL is moved towards RTL, like
	# abc ABC -> CBA abc
	if(substr($levels,$i,1) eq 'e' && $dir eq 'l' && $next_strong[$i] == $STRONG_RTL) {
	    $nowdir = 'r';
	}

	if(substr($levels,$i,1) eq 'n') {
	    $nowdir='l';
	}
	
	$cursor=0 if $nowdir eq 'r';

	$c=$mirror{$c} if($nowdir eq 'r' && $mirror{$c} ne '');
	
	substr($outstr,$cursor,0)=$c;
	
	$cursor++ if $nowdir eq 'l';
	print "$dir:$nowdir:$cursor: [$outstr]\n" if $debug;
    }
    
    return $outstr;

}


# this one works with texts, i.e. handles linebreaks, etc. and splits text on the given width
sub log2vis_text {
    my($text,$string_len,$before,$after) = @_;

    $string_len = 80 unless $string_len;
    $after = "\n" unless defined($after);

    my($logstr,$outtext,$visstr);
    while($text =~ /(.*(\n|$))/g) { # for each line
	next unless $1;
	$logstr = $1;
	chomp($logstr);
	$visstr = log2vis_string($logstr);
	
	while(length($visstr) > $string_len) { # we need to divide
	    substr($visstr,-$string_len) =~ /.*?\s(.*)/; # find first space after length
	    $outtext .= ( defined($before) ? $before : ' ' x ($string_len - length($1) - 1) ). $1 . $after;  # 
	    substr($visstr,-length($1))='';
	} 
	
	$outtext .= (defined($before) ? $before : ' ' x ($string_len - length($visstr) - 1) ) . $visstr . $after; 
    }
    return $outtext;
}

