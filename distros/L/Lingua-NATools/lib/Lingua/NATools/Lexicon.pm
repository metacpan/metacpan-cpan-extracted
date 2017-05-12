# NATools - Package with parallel corpora tools
# Copyright (C) 2002-2012  Alberto Simões
#
# This package is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

package Lingua::NATools::Lexicon;
our $VERSION = '0.7.10';
use 5.006;
use strict;
use warnings;

use Lingua::NATools;
use MLDBM;
use Fcntl;
use Storable;
use Data::Dumper;


=head1 NAME

Lingua::NATools::Lexicon - Encapsulates NATools Lexicon files

=head1 SYNOPSIS

  use Lingua::NATools::Lexicon;

  $lex = Lingua::NATools::Lexicon->new("file.lex");

  $word = $lex->word_from_id(2);

  $id = $lex->id_from_word("cavalo");

  @ids = $lex->sentence_to_ids("era uma vez um gato maltez");

  $sentence = $lex->ids_to_sentence(10,2,3,2,5,4,3,2,5);

  $lex->size;

  $lex->id_count(2);

  $lex->close;

=head1 DESCRIPTION

This module encapsulates the NATools Lexicon files, making them
accessible using Perl. The implementation is based on OO
philosophy. First, you must open a lexicon file using:

 $lex = Lingua::NATools::Lexicon->new("lexicon.file.lex");

When you have all done, do not forget to close it. This makes some
memory frees, and is welcome for the process of opening new lexicon
files.

 $lex->close;

Lexicon files map words to identifiers and vice-versa. Its usage is
simple: use

  $lex->id_from_word($word)

to get an id for a word. Use

  $lex->word_from_id($id)

to get back the word from the id. If you need to make big quantities
of conversions to construct or parse a sentence use C<ids_to_sentence>
or C<sentence_to_ids> respectively.

=head2 C<new>

This is the C<Lingua::NATools::Lexicon> constructor. Pass it a
I<lexicon> file.  These files usually end with a C<.lex> extension:

   my $lexicon = Lingua::NATools::Lexicon->new("file.lex");

=cut

sub new {
    my ($class, $filename) = @_;
    return undef unless -f $filename;

    my $wlid = Lingua::NATools::wlopen($filename);
    return undef if $wlid < 0;

    return bless +{ id => $wlid } => $class # amen
}

=head2 C<save>

This method saves the current lexicon object in the supplied file:

   $lexicon->save("/there/lexicon.lex");

=cut

sub save {
    my ($self, $filename) = @_;
    Lingua::NATools::wlsave($self->{id}, $filename);
}

=head2 C<close>

Call this method to close a Lexicon. This is important to free resources
(both memory and lexicons, as there is a limited number of open lexicons
at a time).

   $lexicon->close;

=cut

sub close {
    my $self = shift;
    Lingua::NATools::wlclose($self->{id});
}

=head2 C<word_from_id>

This method is used to convert one I<word-id> to a I<word>:

   my $word = $lexicon->word_from_id ($word_id);

=cut

sub word_from_id {
    my ($self, $id) = @_;
    return Lingua::NATools::wlgetbyid($self->{id}, $id);
}

=head2 C<ids_to_sentence>

This method calls C<word_from_id> for each passed parameter.
Thus, it receives a list of word identifiers, and returns the
corresponding string. Words are separated by a space character.

   my $sentence = $lexicon->ids_to_sentence(1,3,5,2,3,6);

=cut

sub ids_to_sentence {
    # We will need something more to handle correct cases
    my $self = shift;
    return join(" ",map { $self->word_from_id($_) } @_);
}

=head2 C<id_from_word>

This method is used to convert one I<word> to its corresponding
identifier (I<word-id>).

    my $word_id = $lexicon->id_from_word( $word );

=cut

sub id_from_word {
    my ($self, $word) = @_;
    return Lingua::NATools::wlgetbyword($self->{id}, lc($word));
}

=head2 C<sentence_to_ids>

This method calls C<id_from_word> for each word from a sentence. Note
that the method does not perform the common tokenization task. It just
splits the sentence by the space character. You must preprocess the
string using a NLP tokenizer.

The method returns a reference to the list of identifiers.

  my $wid_list = $lexicon->sentence_to_ids("a sentence");

=cut

sub sentence_to_ids {
    my ($self, $sentence) = @_;
    my @words = split /\s+/, $sentence;
    @words = map { $self->id_from_word($_) } @words;
    return \@words;
}

=head2 C<id_count>

This method returns the number of occurrences for a specific word.
Note that the word must be supplied as its identifier, and not the
string itself.

  my $count = $lexicon->id_count( 45 );

=cut

sub id_count {
    my ($self, $id) = @_;
    return Lingua::NATools::wlcountbyid($self->{id}, $id);
}

=head2 C<occurrences>

This method returns the size of the corpus (number of tokens) that
originated the lexicon: it sums up occurrences for each word, and
returns the total value.

   my $total = $lexicon->occurrences;

=cut

sub occurrences {
    my $self = shift;
    my $size = Lingua::NATools::wloccs($self->{id});
    return $size?$size:undef;
}

=head2 C<size>

This method returns the number of different words (types) from the corpus
that originated the lexicon.

  my $size = $lexicon->size;

=cut

sub size {
    my $self = shift;
    my $size = Lingua::NATools::wlgetsize($self->{id});
    return $size?$size:undef;
}

=head2 C<add_word>

This method adds a new word to the lexicon file. The word will be created 
with an occurrence count of 1.

B<Note that lexicon files can't be created from scratch using this module.
The module is intended to manipulate already created lexicon files. A
standard lexicon file doesn't have space for new words. You need to
enlarge it before. Use the C<size> method to know the current size, and
the C<enlarge> method to add some empty space.>

   $lexicon->add_word("dog");

=cut

sub add_word {
    my ($self, $word) = @_;
    return Lingua::NATools::wladdword($self->{id}, lc($word));
}

=head2 C<set_id_count>

After creating a new word (or in an old word...) you might want to change
its occurrence. Call this method for that. Pass it the word identifier and
the new occurrence count.

B<This method is benevolent and let you set a negative occurrence count. 
Setting an occurrence count to 0 will not delete the word entry.>

   $lexicon->set_id_count( $wid, ++$count);

=cut

sub set_id_count {
    my ($self, $id, $count) = @_;
    return Lingua::NATools::wlsetcountbyid($self->{id}, $id, $count);
}

=head2 C<enlarge>

This method creates extra space for new words. You do not need to know
its current size, just the number of words you need to add. Pass that as
the argument to the method. The returning object should accomodate that
more words. Also, try to call this method as few times as possible.
First calculate the amount of words you need, then enlarge the Lexicon.

   $lexicon->enlarge( 100 ); # 100 more words

=cut

sub enlarge {
    my ($self, $extrasize) = @_;
    return Lingua::NATools::wlenlarge($self->{id}, $extrasize);
}



1;
__END__



=head1 SEE ALSO

See perl(1) and NATools documentation.

=head1 AUTHOR

Alberto Manuel Brandao Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by NATURA Project

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut
