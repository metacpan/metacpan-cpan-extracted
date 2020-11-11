# NATools - Package with parallel corpora tools
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

package Lingua::NATools::NATDict;
our $VERSION = '0.7.12';
use 5.006;
use strict;
use warnings;

use Lingua::NATools;
use MLDBM;
use Fcntl;
use Storable;
use Data::Dumper;


sub open {
  my $class = shift;

  die "NATDict was called\n";

  my $filename = shift;
  my $self = {};
  return undef unless -f $filename;

  my $dic = Lingua::NATools::nat_dict_open($filename);
  return undef if $dic < 0;

  $self->{id} = $dic;

  # Get language names into cache
  $self->{source_language} = Lingua::NATools::nat_dict_source_lang($self->{id});
  $self->{target_language} = Lingua::NATools::nat_dict_target_lang($self->{id});

  # Define which is the source and target languages;
  $self->{lang}{$self->{source_language}} = 0;
  $self->{lang}{$self->{target_language}} = 1;

  return bless $self, $class # amen
}

sub close {
  my $self = shift;
  Lingua::NATools::nat_dict_free($self->{id});
}

sub languages {
  my $self = shift;
  return ($self->{source_language}, $self->{target_language})
}

sub get_params {
  my $self = shift;
  my $lang = shift;
  my $word = shift || undef;

  unless ($word) { $word = $lang; $lang = $self->{source_language} }

  $lang = $self->{lang}{$lang} || 0;

  return ($self,$lang,$word);
}

sub word_from_id {
  my ($self,$lang,$word) = get_params(@_);

  return Lingua::NATools::nat_dict_word_from_id($self->{id}, $lang, $word);
}

sub id_from_word {
  my ($self,$lang,$word) = get_params(@_);

  return Lingua::NATools::nat_dict_id_from_word($self->{id}, $lang, $word);
}

sub word_count_by_id {
  my ($self,$lang,$wid) = get_params(@_);

  return Lingua::NATools::nat_dict_word_count($self->{id}, $lang, $wid);
}

sub word_vals_by_id {
  my ($self,$lang,$wid) = get_params(@_);

  return Lingua::NATools::nat_dict_getvals($self->{id}, $lang, $wid);
}



1;
__END__

=head1 NAME

Lingua::NATools::NATDict - Perl extension to encapsulate a NATools Dictionary

=head1 SYNOPSIS

  use Lingua::NATools::NATDict;

  my $dictionary = Lingua::NATools::NATDict->open("dict.ntd");

  my ($src_lng, $tgt_lng) = $dictionary->languages;

  my $word = $dictionary->word_from_id($src_lng, 2);

  my $id = $dictionary->id_from_word($src_lng, $word);

  my $count = $dictionary->word_count_by_id($tgt_lng, $wid);

  my $data = $dictionary->get_vals_by_id($tgt_lng, $wid);

  $dictionary->close;

=head1 DESCRIPTION

This module encapsulates a NATools Dictionary.

=head2 C<open>

The basic C<Lingua::NATools::NATDict> constructor is the C<open> method. You must
call it with the filename of the file to open. It returns the NATools
Dictionary object.

=head2 C<close>

Closes the NATools Dictionary. Current version of the C/Perl interface
can handle a limited number of NATools Dictionaries opened at the same
time, so to close dictionaries when they are not needed is a good
practice.

=head2 C<languages>

Returns a pair (list with two values) with the names of the languages
in the corpus. You should use these strings in calls to
C<Lingua::NATools::NATDict> methods that require a language identifier.

=head2 C<word_from_id>

This method is used to retrieve the word identified by some integer.
The method is called with the language being queried and the integer
identifier. It returns the word string.

=head2 C<id_from_word>

This method is used to retrieve a word identifier.
The method is called with the language being queried and the word
searched. It returns the word integer identifier.

=head2 C<word_count_by_id>

This method retrieves the occurrence count for a word in the specified
language. Notice that the method is expecting a word identifier and
not the proper word.

=head2 C<get_vals_by_id>

This method retrieves the probable translations for a word in the specified
language. Notice that the method is expecting a word identifier and
not the proper word.

The returned object is a reference to an array with the form
C<<(wid,prob,wid,prob,...)>> where C<<wid>> is the probable
translation word identifier in the other language, and C<<prob>> is
the probability, between 0 and 1.


=head1 SEE ALSO

See perl(1) and NATools documentation.

=head1 AUTHOR

Alberto Manuel Brandao Simoes, C<< <ambs@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by NATURA Project
http://natura.di.uminho.pt

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut
