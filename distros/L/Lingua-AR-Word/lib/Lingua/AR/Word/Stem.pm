package Lingua::AR::Word;

use strict;
use utf8;


sub stem{

  my $stem;
  my $word=shift;


  #let's strip down every prefix and suffix I'm aware of.
  #(actually suffixes relative to people like possessive adjs are NOT chopped)

	if($word=~/^(	#the prefixes
		[وفب]*ال|
		[بيلمتوسن]*ت|
		[بلوكف]*م|
		[ال]*ل|[
		ولسف]*ي|[
		وفلب]*ا|
		)
		(.*?)	# the stem
		(	# the suffixes
		ات|
		وا|
		تا|
		ون|
		وه|
		ان|
		تي|
		ته|
		تم|
		كم|
		ه[نم]*|
		ها|
		ية|
		تك|
		نا|
		ي[نه]*|
		[ةهيا]|
		)
		$/x)
	{
 		$word=$2;
       }

       #let's strip down all other unnecessary letters according to the length of the word
       if(length($word)==3){
           $stem=$word;
       }
       else{
           if(length($word)==4){
               $stem=&four($word);
           }
           else{
               if(length($word)==5){
                   $stem=&five($word);
               }
               else{
                   if(length($word)==6){
                       $stem=&six($word);
                   }
                   else{
                       $stem="NotFound";
                   }
               }
           }
       }

return $stem;
}

sub four{
	my $word=shift;
	
	if($word=~/(.)(.)(ا|ي|و)(.)/){
		$word=$1.$2.$4;
	}
	elsif ($word=~/(.)(ا|و|ط|ي)(.)(.)/){
		$word=$1.$3.$4;
	}
	else{
		$word="NotFound";
	}
}

sub five{
	my $word=shift;
	
	if($word=~/(.)(.)(ا)(ا)(.)/){
		$word=$1.$2.$5;
	}
	elsif ($word=~/(.)(ت|ي)(.)(ا)(.)/){
		$word=$1.$3.$5;
	}
	elsif ($word=~/(.)(و)(ا)(.)(.)/){
		$word=$1.$4.$5;
	}
	elsif ($word=~/(.)(ا)(.)(ي|و)(.)/){
		$word=$1.$3.$5;
	}
	elsif ($word=~/(.)(.)(.)(ا|ي|و)(.)/){
		$word=$1.$2.$3.$5;
		$word=&four($word);
	}
	elsif ($word=~/(.)(.)(ا|ي)(.)(.)/){
		$word=$1.$2.$4.$5;
		$word=&four($word);
	}
	else{
		$word="NotFound";
	}
}

sub six{
	my $word=shift;
	
	if($word=~/(.)(و)(ا)(.)(ي)(.)/){
		$word=$1.$4.$6;
	}
	elsif ($word=~/(.)(.)(ا)(.)(ي)(.)/){
		$word=$1.$2.$4.$6;
		$word=&four($word);
	}
	else{
		$word="NotFound";
	}
}

1;
__END__

=head1 NAME

Lingua::AR::Word::Stem - Perl extension to find the stem of a given Arabic word

=head1 SYNOPSIS

	use Lingua::AR::Word::Stem;

	$stem=Lingua::AR::Word::stem("ARABIC_WORD_IN_UTF8");

=head1 DESCRIPTION

This module will take care of finding the stem of an Arabic word, through chopping the prefixes and suffixes of the word and by taking away unnecessary letters in the middle of the word.


=head1 AUTHOR

Andrea Benazzo, E<lt>andy@slacky.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Andrea Benazzo. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.


=cut
