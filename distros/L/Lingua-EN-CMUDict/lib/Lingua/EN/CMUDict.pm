package Lingua::EN::CMUDict;

use 5.012003;
use strict;
use warnings;
use DB_File;
use File::ShareDir ':ALL';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::EN::CMUDict ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';


# Preloaded methods go here.

sub new {
	my $class = shift;
	my $self = {};

	bless $self,$class;

	my %args = @_;
	foreach my $el (keys %args) {
		$self->{$el} = $args{$el};
	}

	$self->_read_cmu_file();
	return $self;
}

sub rhymes {
	my $self = shift;
	my $word = shift;
	return undef if (!defined $self->{words});

	$word = uc($word);
	return undef if (!defined $self->{words}->{$word});
	my @syls = split(/ - /,$self->{words}->{$word});
	my $syl = pop(@syls);
	my @res;
	foreach my $el (keys %{$self->{words}}) {
		if ($self->{words}->{$el} =~ /$syl$/ && $el ne $word) {
			push @res,$el;
		}
	}
	return @res if wantarray;
	
	return $res[int(rand(scalar(@res)))];
}

sub number_of_syllables {
	my $self = shift;
	my $word = shift;

	return undef if (!defined $self->{words});
	if ($word =~ /\s+/) {
		my @words = split(/\s+/,$word);
		my $sum = 0;
		foreach my $el (@words) { $sum += $self->number_of_syllables($el); }
		return $sum;
	}
	$word = uc($word);

	if (defined $self->{words}->{$word}) {
		return scalar(split(/ - /,$self->{words}->{$word}));
	}
	#check for plurality
	if ($word =~ /s$/i) {
		$word =~ s/s$//i;
		if (defined $self->{words}->{$word}) {
			return scalar(split(/ - /,$self->{words}->{$word}));
		}
	}
	return undef;
}

sub get_word {
	my $self = shift;

	my $word = shift;

	$word = uc($word);

	return $self->{words}->{$word}; 
}

sub _read_cmu_file {
	my $self = shift;

	my %words;
	if (defined $self->{cmufile}) {
		tie %words, 'DB_File', $self->{cmufile}, O_RDONLY, 0644, $DB_HASH || die $self->{cmufile}," ",$!;
	}
	else {
	 	tie %words, 'DB_File', dist_file('Lingua-EN-CMUDict', 'cmusyldict.db'), O_RDONLY, 0644, $DB_HASH;
	}	

	$self->{words} = \%words;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::EN::CMUDict - Perl extension for utilizing the CMU dictionary file

=head1 SYNOPSIS

  use Lingua::EN::CMUDict;
  my $obj = new Lingua::EN::CMUDict;
  print $obj->number_of_syllables("test");

=head1 DESCRIPTION

This version of the CMU Pronouncing dictionary was generated from the original dictionary and designed to syllabify it.  The paper I<On the Syllabification of Phonemes> by Susan Bartlett, Grzegorz Kondrak and Colin Cherry (NAACL-HLT 2009) covers the methods used to generate the dictionary.

=head2 EXPORT

None by default.

=head1 METHODS

=head2 new(cmudict=>I<file>)

Creates a new object, populating it with the cmusyldict db file.  If the cmudict argument is passed with a filename as the argument, that file is used.  If you do not use that argument, the default cmusyldict db file installed with the module is used.

=head2 rhymes(word)

In the case of an array being returned, returns all rhymes to the given word.  In a scalar context, returns a single rhyme.

=head2 number_of_syllables(word)

Returns the number of syllables in the word.  Many pluralities do not add syllable counts and are therefore not in the original database.  This code tries to be intelligent by looking for those and returning the number of syllables.  Also, if  a sentence is passed in, returns the number of syllables in the sentence.  Doesn't currently deal with punctuation very well.

=head2 get_word(word)

Returns the pronunciation for the word with syllable boundaries.


=head1 SEE ALSO

Lingua::EN::Phoneme -- another way of accessing the CMU Pronunciation dictionary.


=head1 AUTHOR

Leigh Metcalf, E<lt>leigh@fprime.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Leigh Metcalf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
