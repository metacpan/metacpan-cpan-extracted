package TypeLessTranslator; 

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		TypeLessTranslator.pm
# Description: 	Translate typeless text to full code - sms 4 codng
#
# Date	 		Change
# -----------------------------------------------------------------------------
# 09/05/2005	Auto generated file
# 09/05/2005	Needed for faster GOO editing - trying to eclipse eclispe
#
###############################################################################

use strict; 

use Goo::FileUtilities; 
use Goo::Thing::pm::Perl5; 


###############################################################################
#
# translate_file - translate a file
#
###############################################################################

sub translate_file { 

	my ($file) = @_; 
	
	my $newfile; 
	
	# added a new line - testing	
	foreach my $line (Goo::FileUtilities::get_file_as_lines($file)) { 

		# skip if the line is a comment
		if ($line =~ m/^\s*\#/) { 
			$newfile .= $line; 
			next; 
		} 

		# skip if the line is blank
		if ($line =~ m/^\s*$/) { 
			# print "skipping!!!! \n";
			$newfile .= $line; 
			next; 
		} 
		
		# skip if the line contains a regex
		if ($line =~ m/\=\~/) { 
			# print "skipping!!!! \n";
			$newfile .= $line; 
			next; 
		} 
		
		# skip if the line contains a doublequote
		if ($line =~ m/\"/) { 
			# print "skipping!!!! \n";
			$newfile .= $line; 
			next; 
		} 
		
		$newfile .= translate_line($line); 
		
	} 
	
	
	Goo::FileUtilities::write_file($file, $newfile); 
	
} 


###############################################################################
#
# translate_line - translate a line
#
###############################################################################

sub translate_line { 

	my ($line, $language) = @_; 

	# turn this off!!!
	return $line;

	# don't translate comments
	return $line if ($line =~ /^\s+#/); 

	# don't translate HEREDOC's tokens or variables at the start of a line
	return $line if ($line =~ /^[A-Z\$]+/); 

	# preserve whitespace
	my ($whitespace, $code) = $line =~ m/^(\s*)(.*)$/; 
	
	# sometimes the code contains comments 
	# don't expand comments 
	$code =~ m/(.*?)\ (.*)$/; 

	$code = $1 || $code; 
	my $comments = $2; # is abs glob 

	# expand packages references

	# expand reserved words in line
	return $whitespace . expand_reserved_words($code). $comments . "\n"; 

} 


###############################################################################
#
# expand_reserved_words - turn any abbreviated reserved words into full words
#
###############################################################################

sub expand_reserved_words { 

	my ($line, $language) = @_; 

	# at the moment everything is Perl5 but I will add Perl6 ASAP
	# go through all bareword letters and expand them
	my @tokens = split(/\s+/, $line); 
	
	my $newline; 
	
	foreach my $token (@tokens) { 

		# ignore capitalised tokens - package names and barewords
		if ($token =~ /[A-Z]/) { $newline .= $token." "; next; } 
		
		# ignore sigil tokens
		if ($token =~ /[\$\@\%]/) { $newline .= $token." "; next; } 

		# find lowercase barewords!
		# for version 1 only allow "pure" tokens i.e., m => my 
		# this [(m] token is not valid: (m $row =
		# had problems with regexes too: $row =~ m/
		if ($token =~ /^[a-z]*$/) { 
			# extract any contiguous lowercase letters from the token
			# $token =~ s/([a-z]*)/Perl5::match_reserved_word($1)/x;
			$token =~ s/([a-z]+)/matchReservedWord($1)/e; 
				
		} 

		$newline .= $token." "; 
				
	} 
	
	return $newline; 
	
} 


###############################################################################
#
# match_reserved_word - match abbreviated letters to full reserved words
#			if nothing is found return the letters
#
###############################################################################

sub match_reserved_word { 

	my ($letters) = @_; 
	
	# go no further is this the full word
 	return $letters if Goo::Thing::pm::Perl5::is_reserved_word($letters); 
	
        # f   => for
        # w   => while
        # fk  => fork
        # fe  => foreach        
        
        # take a string of letters and create a pattern
        # f   => f.*	    	matches for
        # fe  => f.*?e.*        matches foreach
        # fre => f.*?r.*?e.*  	matches foreach
        # fk  => f.*?k.*	matches fork
        my $pattern = join(".*?", split(//, $letters)); 
        $pattern .= ".*"; 

	# print "pattern = ".$pattern."\n";
        
        # translate a letter sequence into a regex - could be more efficient
 	foreach my $word (sort { length($a) <=> length($b) } Goo::Thing::pm::Perl5::get_common_words()) { 
 	
 		# find a matching reserved word
 		if ($word =~ /^$pattern/) { 
 			# in the short term tell me when it happens!
 			# print "expanding $letters to $word\n"; 
 			return $word; 
 		} 
 	
 	} 

	return $letters; 

} 


1; 


__END__

=head1 NAME

TypeLessTranslator - Experimental module. It translates "typeless" text to full code. It's like 
writing abbreviate sms txt for Perl code.

=head1 SYNOPSIS

use TypeLessTranslator;

=head1 DESCRIPTION



=head1 METHODS

=over

=item translate_file

translate a file by expanding typeless code to full code

=item translate_line

translate a line

=item expand_reserved_words

turn any abbreviated reserved words into full reserved words

=item match_reserved_word

match abbreviated letters to full reserved words

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

