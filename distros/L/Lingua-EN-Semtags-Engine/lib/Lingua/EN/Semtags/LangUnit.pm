package Lingua::EN::Semtags::LangUnit;

use strict;
use warnings;
# POS - part of speech tag (Lingua::EN::Tagger style)
# POSWN - part of speech tag (WordNet style)
use constant POS2POSWN => {
	NN => 'n', # Noun
	VB => 'v', # Verb
	JJ => 'a', # Adjective
	RB => 'r'  # Adverb	
};
use constant TRUE  => 1;
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
	$self->{token} = undef;
	$self->{is_word} = FALSE;
	$self->{is_phrase} = FALSE;
	$self->{pos} = undef;
	$self->{sense} = undef;
	$self->{isas} = [];
	
	# Set the args that came from the constructor
	foreach my $arg (sort keys %args) {
		die "Unknown argument: $arg!" unless exists $self->{$arg};
		$self->{$arg} = $args{$arg};
	}
}

#============================================================
sub token { $_[0]->{token}; }
sub is_word { $_[0]->{is_word}; }
sub is_phrase { $_[0]->{is_phrase}; }
sub pos { $_[0]->{pos}; }
sub sense { defined $_[1] ? $_[0]->{sense} = $_[1] : $_[0]->{sense}; }
sub isas { @{$_[0]->{isas}}; }
sub add_isa { push @{$_[0]->{isas}}, $_[1]; }
sub poswn { $_[0]->pos =~ /^(\w\w)/ and exists POS2POSWN->{$1} ? POS2POSWN->{$1} : undef; }
#============================================================

TRUE;

__END__

=head1 NAME

Lingua::EN::Semtags::LangUnit - a DTO used by C<Lingua::EN::Semtags::Sentence> 

=head1 SYNOPSIS

  use Lingua::EN::Semtags::LangUnit;

=head1 DESCRIPTION

A DTO used by C<Lingua::EN::Semtags::Sentence> and 
C<Lingua::EN::Semtags::LangUnit>.

=head2 METHODS

=over 4

=item B<add_isa($lunit)> 

Adds C<$isa> to C<$self-E<gt>{isas}>.

=item B<is_phrase()>

Returns C<true> is this language unit is a phrase.

=item B<is_word()>

Returns true if this language unit is a word.

=item B<isas()>

Returns C<$self-E<gt>{isas}>.

=item B<pos()>

Returns C<$self-E<gt>{pos}>(a C<Lingua::EN::Tagger> part of speech tag).

=item B<poswn()>

Returns C<$self-E<gt>{pos}> converted into the C<WordNet::QueryData> style tag.

=item B<sense([$sense])>

Returns/sets C<$self-E<gt>{sense}>.

=item B<token()>

Returns C<$self-E<gt>{token}>.    

=back

=head1 SEE ALSO

L<Lingua::EN::Semtags::Engine>

=head1 AUTHOR

Igor Myroshnichenko E<lt>igorm@cpan.orgE<gt>

Copyright (c) 2008, All Rights Reserved.

This software is free software and may be redistributed and/or
modified under the same terms as Perl itself.

=cut