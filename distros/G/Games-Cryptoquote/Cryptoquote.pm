# Cryptoquote.pm -- Solves Cryptoquote puzzles.
# 
# Copyright (C) 1999-2002  Bob O'Neill
# All rights reserved.
#
# Thanks to Adam Foxson for the prodding and know-how that made
# it possible for this module to make it to CPAN.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

package Games::Cryptoquote;

use strict;
use vars qw($VERSION);
use Carp;

$VERSION = '1.30';
local $^W = 1;

sub new
{
	my $type  = shift;
	my $class = ref($type) || $type;
	return bless {}, $class;
}

sub quote
{
	my $self = shift;
	$self->{'quote'} = shift if @_;
	return $self->{'quote'}
}

sub source
{
	my $self = shift;
	$self->{'source'} = shift if @_;
	return $self->{'source'}
}

sub timeout
{
	my $self = shift;
	$self->{'timeout'} = shift if @_;
	return $self->{'timeout'}
}

sub build_dictionary
{
	my $self = shift;

	croak "Invalid arguments (expecting even number)" if @_ % 2;
	my %options  = @_;
	my @bad_opts = grep { !/^(?:type|file)$/ } keys %options;
	croak "Invalid argument(s): (@bad_opts)" if @bad_opts;

	my $file = $options{'file'};
	my $type = $options{'type'};

	if ($type eq 'dict')
	{
		if (open DICT, "$file")
		{
			my ( $words, $file );
			while ( <DICT> )
			{
				chomp;
				$self->{'dict_patterns'}{&build_pattern($_)}{$_} = 1;
			}
			close DICT;
			return 1;
		}
		else
		{
			my ($caller, $line) = (caller(0))[1..2];
			carp "Couldn't read $file: $! (called by $caller line $line)";
			return 0;
		}
	}
	elsif ($type eq 'patterns')
	{
		if (open DICT, "$file")
		{
			my ( $words, $pattern );
			while ( <DICT> )
			{
				chomp;
				($pattern, $words) = split /:/; 
				for ( split /\|/, $words )
				{
					$self->{'dict_patterns'}{$pattern}{$_} = 1;
				}
			}
			close DICT;
			return 1;
		}
		else
		{
			my ($caller, $line) = (caller(0))[1..2];
			carp "Couldn't read $file: $! (called by $caller line $line)";
			return 0;
		}
	}
	else
	{	
		croak "Invalid dictionary type ($type)";
	}
}

sub write_patterns
{
	my $self = shift;

	croak "Invalid arguments (expecting even number)" if @_ % 2;
	my %options  = @_;
	my @bad_opts = grep { !/^(?:dict_file|pattern_file)$/ } keys %options;
	croak "Invalid argument(s): (@bad_opts)" if @bad_opts;

	my $dict_file    = $options{'dict_file'};
	my $pattern_file = $options{'pattern_file'};

	$self->build_dictionary(file => $dict_file, type => 'dict');

	my %patterns_hash = %{ $self->{'dict_patterns'} };

	if (-e $pattern_file)
	{
		carp "$pattern_file exists.  I won't overwrite it.\n";
		carp "You probably want to remove the call to write_patterns.\n";
	}

	open PATTERNS, ">$pattern_file" or croak "Couldn't write $pattern_file: $!";
	for my $pattern (sort keys %patterns_hash)
	{
		print PATTERNS "$pattern:";

		for my $word (sort keys %{ $patterns_hash{$pattern} })
		{
			print PATTERNS "$word|";
		}

		print PATTERNS "\n";
	}
	close PATTERNS;
}

sub solve
{
	my $self = shift;

	my $quote   = $self->quote()   || '';
	my $source  = $self->source()  || '';
	my $timeout = $self->timeout() || 0;
	croak "Invalid timeout value $timeout" unless $timeout =~ /^\d+$/;

	$self->{'let_let'} = ();
	$self->{'bad_let_let'} = ();

	# We will have to do away with the uc() for the quote that's saved
	# (currently, globalquote or globalquote2).
	$self->{'globalquote'} = $quote;
	$self->{'globalquote'} = uc $quote;

	for ( split /\s/, $self->{'globalquote'} )
	{
		s/[^a-z]//gi;
		next if exists $self->{'word_word'}{$_};
		$self->{'word_word'}{$_} = $self->{'dict_patterns'}{&build_pattern($_)};
	}

	my $last_num_poss = -1;
	my $time_in  = time;
	my $solution = {};
	while ( 1 )
	{
		my ($current_num_poss,$quote_soln,$hash_ref) = $self->narrow_possibilities();
		if ( $current_num_poss == $last_num_poss or $current_num_poss == 0 )
		{
			my $source_soln;
			if ($quote_soln !~ /\|/)
			{
				$quote_soln  = &apply_mapping($self->quote(), $hash_ref);
				$source_soln = &apply_mapping($self->source(), $hash_ref);
			}
			$self->{'solution'}{'quote'}  = $quote_soln;
			$self->{'solution'}{'source'} = $source_soln;
			return 1;
		}
		$last_num_poss = $current_num_poss;

		if ($timeout and time - $time_in > $timeout)
		{
			$self->{'solution'}{'quote'}  = '';
			$self->{'solution'}{'source'} = '';
			return 0;
		}
	}
}

sub narrow_possibilities
{
	my $self = shift;
	$self->{'let_word_let'} = {};
	$self->{'word_let_let_word'} = {};
	$self->{'best_word_word'} = {};

	$self->algorithm_one();
	$self->algorithm_two();
	$self->algorithm_three();

	$self->{'word_word'} = {};
	$self->{'word_word'} = $self->{'best_word_word'};

	my $num_poss = 0;
	my $soln = '';
	my %good_let_let;
	for my $word1 ( split /\s/, $self->{'globalquote'} )
	{
		$word1 =~ s/[^a-z]//gi;

		my @temp = keys %{$self->{'best_word_word'}{$word1}};
		$soln .= join( '|', (@temp)) . ' ';
		$soln .= " #$word1#" if $#temp == -1;
		$num_poss += $#temp;

		my @chars = split('',$word1);
		for my $poss (@temp) # <-- possibilities for $word1
		{
			my @poss_chars = split('',$poss);
			for my $i (0..$#chars)
			{
				$good_let_let{$chars[$i]}{$poss_chars[$i]} = 1;
			}
		}
	}

	return ($num_poss, $soln, \%good_let_let);
}

sub algorithm_one
{
	my $self = shift;
	for my $word1 ( sort {scalar(keys %{$self->{'word_word'}{$a}}) <=> scalar(keys %{$self->{'word_word'}{$b}})} keys %{$self->{'word_word'}} )
	{
		WORD2:for my $word2 ( keys %{$self->{'word_word'}{$word1}} )
		{
			for my $i ( 0..length($word2) - 1) 
			{
				next WORD2 if exists $self->{'bad_let_let'}{substr($word1,$i,1)}{substr($word2,$i,1)};
			}

			for my $i ( 0..length($word2) - 1) 
			{
				my $char1 = substr($word1,$i,1); 
				my $char2 = substr($word2,$i,1); 

				$self->{'let_word_let'}{$char1}{$word1}{$char2} = 1;
				$self->{'let_let'}{$char1}{$char2} = 1;
				$self->{'word_let_let_word'}{$word1}{$char1}{$char2}{$word2} = 1;
			}
		}

		for my $char1 ( keys %{$self->{'let_let'}} )
		{
			CHAR2:for my $char2 ( keys %{$self->{'let_let'}{$char1}} )
			{
				for my $word1 ( keys %{$self->{'let_word_let'}{$char1}} )
				{
					unless ( exists $self->{'let_word_let'}{$char1}{$word1}{$char2} )
					{
						$self->{'bad_let_let'}{$char1}{$char2} = 1;
						delete $self->{'let_let'}{$char1}{$char2};
						next CHAR2; 
					}
				}
			}
		}
	}
}

sub algorithm_two
{
	my $self = shift;
	my $took_out = 0;

	for my $word1 ( keys %{$self->{'word_let_let_word'}} )
	{
		for my $char1 ( keys %{$self->{'word_let_let_word'}{$word1}} )
		{
			my @chars2 = keys %{$self->{'word_let_let_word'}{$word1}{$char1}};

			if ( $#chars2 == 0 )
			{
				for my $word3 ( keys %{$self->{'word_let_let_word'}} )
				{
					for my $char3 ( keys %{$self->{'word_let_let_word'}{$word3}} )
					{
						next unless exists $self->{'word_let_let_word'}{$word3}{$char3}{$chars2[0]};
						if ( $char1 eq $char3 )
						{
							if ( scalar(keys %{$self->{'word_let_let_word'}{$word3}{$char3}}) > 1 )
							{
								my $temp = $self->{'word_let_let_word'}{$word3}{$char3}{$chars2[0]};
								delete $self->{'word_let_let_word'}{$word3}{$char3};
								$self->{'word_let_let_word'}{$word3}{$char3}{$chars2[0]} = $temp;
								$took_out++;
							}
						}
						else
						{
							delete $self->{'word_let_let_word'}{$word3}{$char3}{$chars2[0]};
							$took_out++;
						}
					}
				}
			}
		}	
	}
}

sub algorithm_three
{
	my $self = shift;

	for my $word1 ( keys %{$self->{'word_let_let_word'}} )
	{
		my $const1 = ( keys %{$self->{'word_let_let_word'}{$word1}} )[0];
		
		for my $const2 ( keys %{$self->{'word_let_let_word'}{$word1}{$const1}} )
		{
			WORD2:for my $word2 ( keys %{$self->{'word_let_let_word'}{$word1}{$const1}{$const2}} )
			{
				CHAR1:for my $char1 ( keys %{$self->{'word_let_let_word'}{$word1}} )
				{
					for my $char2 ( keys %{$self->{'word_let_let_word'}{$word1}{$char1}} )
					{
						next CHAR1 if exists $self->{'word_let_let_word'}{$word1}{$char1}{$char2}{$word2};
					}
					next WORD2;
				}
				$self->{'best_word_word'}{$word1}{$word2} = 1;
			}
		}
	}
}

sub build_pattern
{
	my @chars   = split '', shift;
	my $pattern = '';
	my $string  = '';

	for my $i ( 0..$#chars )
	{
		if ($string =~ /$chars[$i]/)
		{
			$pattern .= (index( $string, $chars[$i] ) + 1) . '|';
		}
		else
		{
			$pattern .= ( $i + 1 ) . '|';
			$string  .= $chars[$i];
		}
	}

	chop $pattern; # <-- chop trailing '|'
	return $pattern;
}

sub apply_mapping
{
	my $ciphertext  = shift;
	my $mapping_ref = shift;

	return "No solution.\n" unless ref $mapping_ref eq 'HASH';

	# Clean up the mapping, reducing us to
	# one solution, but that's ok for now.
	my %mapping;
	for my $from (keys %$mapping_ref)
	{
		for my $to (keys %{$mapping_ref->{$from}})
		{
			$mapping{$from} = $to;
			last;
		}
	}

	my @my_chars;
	for my $i (0..length($ciphertext))
	{
		my $crypt_char = substr($ciphertext,$i,1);

		if ($crypt_char =~ /^[a-z]$/)
		{
			$my_chars[$i] = '%';
		}
		elsif ($crypt_char =~ /^[A-Z]$/)
		{
			$my_chars[$i] = '#';
		}
		else
		{
			$my_chars[$i] = $crypt_char;
		}
	}
	my $plaintext = join('',@my_chars);

	for my $letter (keys %mapping)
	{
		next unless $mapping{$letter};

		my @my_locations;
		for my $j (0..length($ciphertext))
		{
			if (substr($ciphertext,$j,1) =~ /^$letter$/i)
			{
				push @my_locations, $j;
			}
		}
		my @new_chars = split('',$plaintext);
		for my $i (0..$#my_locations)
		{
			my $index = $my_locations[$i];

			if ($new_chars[$index] eq '#')
			{
				# It's uppercase.
				$new_chars[$index] = $mapping{$letter};
			}
			else
			{
				# It's lowercase, so keep it that way.
				$new_chars[$index] = lc $mapping{$letter};
			}
		}
		$plaintext = join('',@new_chars);
	}

	return $plaintext;
}

sub get_solution
{
	my $self = shift;
	my $type = shift;
	croak "Invalid solution type: $type" unless $type =~ /^(quote|source)$/;

	return $self->{'solution'}{$type};
}

1; # because Perl is number one.

__END__

=head1 NAME

Games::Cryptoquote - Solves Cryptoquotes

=head1 SYNOPSIS

  use Games::Cryptoquote;

  my $quote     = 
  'Omyreeohrmy jsvlrtd stpimf yjr hepnr ztpvesox yjsy yjod ztphtsx od brtu vppe!';
  my $author    = q(Npn P'Mroee);

  my $c = Games::Cryptoquote->new();

  unless (-e 'patterns.txt')
  {
      $c->write_patterns(
          dict_file => '/usr/share/dict/words',
          pattern_file => 'patterns.txt'
      ) or die;
  }
  $c->build_dictionary(file => 'patterns.txt', type => 'patterns') or die;
  
  $c->quote($quote);
  $c->source($author);
  $c->timeout(10);
 
  my $time1     = time;
  $c->solve();
  my $time2     = time;
  
  print  "Solution : ".$c->get_solution('quote')." -- ".
                       $c->get_solution('source')."\n";
  printf "Took     : %f seconds\n", $time2 - $time1;

=head1 DESCRIPTION

 This module solves cryptoquote puzzles, where each letter stands for
 a different letter.  These puzzles are typically found in newspapers
 with comics and crossword puzzles.  You can also find several
 examples on the internet, which are nice, because you can cut and paste
 into your script for expeditious solving.

 Note that you'll get some pretty interesting results if
 your cryptoquote puzzle does not yield a unique result,
 or if it uses words that are not in your dictionary.


Public Methods:

B<new> (constructor)

 takes no arguments.

B<quote>

 get/set quote.

B<source>

 get/set source (where the quote came from -- author, etc.).

B<timeout>

 get/set timeout (number of seconds before giving up).

B<build_dictionary>

 Build a huge hash, using either a dictionary like /usr/share/dict/words
 or a specially-formatted patterns file, which takes a lot less time to
 process.

B<write_patterns>

 Read in a dictionary file, like /usr/share/dict/words, and write out
 a specially-formatted patterns file, which takes a lot less time to
 process.

B<solve>

 Do the dirty work.  Assign solution variables for later access via
 the solution() method.

B<solution>

 Obtain the solution for either the quote or the source.  Specify which
 one you want with an argument of "quote" or "source".

See the README for the introduction.

=head1 BUGS

 Things seem to be coming out in lower-case.  Weird.
 Doesn't support contractions (like "Doesn't").
 Assumes no words will contain "|" character.

=head1 TODO

 Lots of general cleanup, mostly bad OO style Adam is chastizing me for.
 Add clearer documentation.
 Add support for contractions.
 Add more tests.
 Fix bugs.
 Enhance interface.
 Optimize algorithm.
 Fix typos that I haven't bothered to look for.

=head1 CREDITS

 Thanks to Darren Key <emdeeki@yahoo.com> for helping launch this idea.
 Thanks to Peter Kioko <peterkioko@hotmail.com> for the optimized
   mind-bending algorithm.
 Thanks to Adam Foxson <afoxson@pobox.com> for making this CPANable
   and for numerous other cleanups.

=head1 AUTHOR

Bob O'Neill, E<lt>bobo@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>.

=cut
