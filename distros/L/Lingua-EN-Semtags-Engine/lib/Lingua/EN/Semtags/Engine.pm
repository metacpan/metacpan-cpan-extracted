package Lingua::EN::Semtags::Engine;

use strict;
use warnings;
#use Data::Dumper;
use WordNet::QueryData 1.46;
use Lingua::EN::Tagger 0.11;
use List::Util qw(min max);
use Lingua::EN::Semtags::Sentence;
use Lingua::EN::Semtags::LangUnit;
use constant SEMTAG_ISA_INDEX => 1; # TODO May be calculated
use constant PHRASE_FRAME_SIZE => 3;
use constant MIN_ISAS => 3;
use constant ISAS => 'hypes'; # Hypernyms
use constant TRUE => 1;
use constant FALSE => 0;

our $VERSION = '0.01';

#============================================================ 
sub new {
#============================================================
	my ($invocant, %args) = @_;
	my $self = bless ({}, ref $invocant || $invocant);
	$self->_init(%args);
	return $self;
}

#============================================================
sub _init {
#============================================================
	my ($self, %args) = @_;
	
	# Initialize attributes
	$self->{wn} = WordNet::QueryData->new;
	$self->{tagger} = Lingua::EN::Tagger->new;
	$self->{verbose} = FALSE;
	
	# Set the args that came from the constructor
	foreach my $arg (sort keys %args) {
		die "Unknown argument: $arg!" unless exists $self->{$arg};
		$self->{$arg} = $args{$arg};
	}
}

#============================================================
sub semtags { 
#============================================================
	my ($self, $string) = @_;
	my @semtags = ();
	
	foreach my $lunit ($self->sentence($string)->lunits) {
		my $semtag = ($lunit->isas)[SEMTAG_ISA_INDEX];
		$semtag =~ s/#\w#\d+$//;
		push @semtags, uc $semtag;		
	}
	
	return @semtags;
}

#============================================================
sub sentence {
#============================================================
	my ($self, $string) = @_;
	
	my $sentence = Lingua::EN::Semtags::Sentence->new(string => $string);
	$self->_detect_words($sentence);
	$self->_detect_phrases($sentence);
	$self->_set_lunits($sentence);

	return $sentence;
}

# Detects the POS of every token in the string.  Populates $sentence->word_tokens.  
# Only tokens of nouns, verbs, adjectives, adverbs go into $sentence->word_tokens.
#============================================================
sub _detect_words {
#============================================================
	my ($self, $sentence) = @_;
	
	$sentence->string(&_clean_for_words($sentence->string));
	
	my $tagged_string = $self->tagger->get_readable($sentence->string);
	foreach my $token_pos (split /\s/, $tagged_string) {
		my ($token, $pos) = split /\//, $token_pos;
		# Nouns, verbs, adjectives, adverbs
		$sentence->word_tokens->{$token} = $pos if ($pos =~ /^(NN|VB|JJ|RB)/);
	}
	
#	print '_detect_words: ', Dumper($sentence->word_tokens) if $self->verbose;
}

# Detects WordNet phrases.  Updates $sentence->string: glues phrase tokens 
# together with underscores.  Populates $sentence->phrase_tokens.
#============================================================
sub _detect_phrases {
#============================================================
	my ($self, $sentence) = @_;
	
	$sentence->string(&_clean_for_phrases($sentence->string));
	
	# Move a frame across the sentence and test the contents for a sense
	my @tokens = split /\s/, $sentence->string;
	for (my $i = 0; $i < @tokens; $i++) {
		my $phrase_string = $tokens[$i];
		my $frame = min($i + 1 + PHRASE_FRAME_SIZE, scalar @tokens);
		for (my $j = $i + 1; $j < $frame; $j++) {
			$phrase_string .= ' '.$tokens[$j];
			if ($self->wn->validForms($phrase_string)) {
				print "_detect_phrases: [$phrase_string]\n" 
					if $self->verbose;
				my @phrase_tokens = split /\s/, $phrase_string;
				my $phrase_string_padded = join '_', @phrase_tokens;
				(my $string = $sentence->string) =~ 
					s/$phrase_string/$phrase_string_padded/g;
				$sentence->string($string);
				$sentence->phrase_tokens->{$phrase_string_padded} = TRUE;
				$i += $#phrase_tokens; # Avoid frame overlaps
				last; # Stop growing the frame if a phrase is detected
			} 
		}		
	}
	
#	print '_detect_phrases: ', Dumper($sentence->phrase_tokens) if $self->verbose;
}

#============================================================
sub _set_lunits {
#============================================================
	my ($self, $sentence) = @_;
	my %word_tokens = %{$sentence->word_tokens};
	my %phrase_tokens = %{$sentence->phrase_tokens};
	my %seen_tokens = ();
	
	foreach my $token (split /\s/, $sentence->string) {
		if ((exists $word_tokens{$token} or exists $phrase_tokens{$token}) and 
			!exists $seen_tokens{$token}) {
				$seen_tokens{$token} = TRUE;
				
				my $pos = exists $word_tokens{$token} ? $word_tokens{$token} : undef;
				my $is_word = exists $word_tokens{$token} ? TRUE : FALSE;
				my $is_phrase = exists $phrase_tokens{$token} ? TRUE : FALSE;
				my $lunit = Lingua::EN::Semtags::LangUnit->new(
					pos => $pos,
					token => $token,
					is_word => $is_word,
					is_phrase => $is_phrase
				);
				$self->_set_isas($lunit) if $self->_set_sense($lunit);
				$sentence->add_lunit($lunit) if &_is_meaningful($lunit);
		}
	}
}

#============================================================
sub _set_sense {
#============================================================
	my ($self, $lunit) = @_;
	my $token = $lunit->token;
	my $sense = undef;
	
	if ($sense = $self->_sense($lunit)) {
		print "_set_sense: [$token] is [$sense]\n" if $self->verbose;
		$lunit->sense($sense);
		return TRUE;
	} else { 
		print "_set_sense: [$token] has no sense!\n" if $self->verbose;
		return FALSE;
	}
}

#============================================================
sub _sense {
#============================================================
	my ($self, $lunit) = @_;
	my $token = $lunit->token;
	my $poswn = $lunit->pos ? $lunit->poswn : undef;
	my $sense = undef;
	
	# Query for the token without a POS
	my @senses = $self->wn->validForms($token);
	if (@senses == 1) {
		$sense = $senses[0];
	} elsif (@senses > 1) { # Requires disambiguation
		if (defined $poswn) {
			# Query for the token with a POS
			my @senses_pos = $self->wn->validForms("$token#$poswn");
			if (@senses_pos == 1) {
				$sense = $senses_pos[0];
			} elsif (@senses_pos > 1) {
				$sense = $self->_disambiguate_senses(@senses_pos);
			} else { 
				$sense = $self->_disambiguate_senses(@senses); 
			}			
		} else { 
			$sense = $self->_disambiguate_senses(@senses); 
		}
	}
	
	return $sense;
}

#============================================================
sub _disambiguate_senses {
#============================================================
	my ($self, @senses) = @_;
	my %freqs2senses = ();
	
	foreach my $sense (@senses) {
		my $freq = $self->wn->frequency("$sense#1");
		$freqs2senses{$freq} = $sense;
	}
	
	# We are interested in the most frequently used sense
	my $max_freq = max keys %freqs2senses;
	my $sense = $freqs2senses{$max_freq};
	
	print "_disambiguate_senses: [@senses]->[$sense]\n" if $self->verbose;
	
	return $sense;
}

#============================================================
sub _set_isas {
#============================================================
	my ($self, $lunit) = @_;
	my $isa = $lunit->sense;
	
	while ($isa = ($self->wn->querySense($isa, ISAS))[0]) {
		$lunit->add_isa($isa);
	}
	
	my @isas = $lunit->isas;
	print "_set_isas: [@isas]\n" if $self->verbose;
}

#============================================================
sub wn { $_[0]->{wn}; }
sub tagger { $_[0]->{tagger}; }
sub verbose { defined $_[1] ? $_[0]->{verbose} = $_[1] : $_[0]->{verbose}; }
#============================================================

#============================================================
sub _clean_for_words {
#============================================================
	for (my $string = $_[0]) {
		s/\// /g;
		s/\s+/ /g; # Collapse multiple spaces into one
		return $string;
	}
}

#============================================================
sub _clean_for_phrases {
#============================================================
	for (my $string = $_[0]) {
		s/\W/ /g; # Remove non-word chars
		s/\b\w\b//g; # Remove single chars
		s/\s+/ /g; # Collapse multiple spaces into one
		return $string;
	}
}

#============================================================
sub _is_meaningful {
#============================================================
	return $_[0]->isas > MIN_ISAS ? TRUE : FALSE;
}

TRUE;

__END__

=head1 NAME

Lingua::EN::Semtags::Engine - extract semantic tags (semtags) from English text 

=head1 SYNOPSIS

  use Lingua::EN::Semtags::Engine;
  my $engine = Lingua::EN::Semtags::Engine->new;
  my @semtags = $engine->semtags("your blog post title");

=head1 DESCRIPTION

Lingua::EN::Semtags uses Lingua::EN::Tagger and WordNet::QueryData to extract 
semantic tags (semtags) from English text.  Semtags are words which reflect 
the semantic essence of the text (similar to topic keywords).

Lingua::EN::Semtags was designed and developed to solve a particular problem I 
was facing.

Problem: a user is processing blog post titles and needs to programmatically 
determine the posts' semantic context.

Solution: the user feeds a blog post title to Lingua::EN::Semtags and gets 
back a set of semtags which can be used for further processing (e.g., web 
searches).

Example: a blog post title like "BBtv: Graffiti Research Lab, the movie" 
(boingboing.net, Posted by Xeni Jardin, April 24, 2008 8:00 AM) would produce 
the following semtags: [DECORATION WORKPLACE SHOW].

Please note that the module makes the following assumptions when attempting to 
extract semtags:

=over 4

=item *

only nouns, verbs, adjectives and adverbs are considered as candidate words 
for semtags; 

=item *

at the time of phrase detection a frame is grown up to PHRASE_FRAME_SIZE 
(set to 3) tokens;

=item *

a language unit (a word or a phrase) is considered meaningful if its hypernym 
hierarchy in the WordNet database is at least MIN_ISAS (set to 3) levels deep;

=item *

a semtag is a meaningful language unit's hypernym at the SEMTAG_ISA_INDEX (set 
to 1, starts with 0) level of the hierarchy.

=back

=head2 METHODS

=over 4

=item B<semtags($string)> 

Calls C<sentence($string)>, gets back a populated instance of 
C<Lingua::EN::Semtags::Sentence>, iterates over its 
C<Lingua::EN::Semtags::LangUnit>s, populates and returns an array of their 
semtags.

=item B<sentence($string)>

Returns an instance of C<Lingua::EN::Semtags::Sentence> populates with 
C<Lingua::EN::Semtags::LangUnit> objects which represnet meaningful language 
units.

=item B<tagger()>

Returns the C<Lingua::EN::Tagger> instance used by the engine.

=item B<verbose([$verbose])>

Returns/sets the verbose mode.

=item B<wn()>

Returns the C<WordNet::QueryData> instance used by the engine.    

=back

=head1 SEE ALSO

L<Lingua::EN::Tagger>, L<WordNet::QueryData>

=head1 AUTHOR

Igor Myroshnichenko E<lt>igorm@cpan.orgE<gt>

Copyright (c) 2008, All Rights Reserved.

This software is free software and may be redistributed and/or
modified under the same terms as Perl itself.

=cut