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

package Lingua::NATools::Dict;
our $VERSION = '0.7.10';
use 5.006;
use strict;
use warnings;
require Exporter;

use Lingua::NATools;
use MLDBM;
use Fcntl;
use Storable;
use Data::Dumper;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();


sub new {
  my ($class, $filename, $size) = @_;

  my $id = Lingua::NATools::dicnew($size);
  return undef if $id < 0;

  my $self = bless +{ id => $id, filename => $filename } => $class;
  return $self;
}

sub open {
  my $filename = shift;

  $filename = shift if $filename eq "Lingua::NATools::Dict";
  my $self = {};
  return undef unless -f $filename;
  my $dic = Lingua::NATools::dicopen($filename);
  return undef if $dic < 0;
  $self->{id} = $dic;
  return bless $self #amen
}

sub close {
  my $self = shift;
  Lingua::NATools::dicclose($self->{id});
}

sub add {
  my $self = shift;
  my $other = shift;
  my $dicid = Lingua::NATools::dicadd($self->{id}, $other->{id});
  return undef if $dicid < 0;
  my $new = { id => $dicid };
  return bless $new #amen
}


sub save {
  my ($dic, $filename) = @_;
  $filename = $dic->{filename} if exists($dic->{filename}) && !$filename;
  return undef unless Lingua::NATools::dicsave($dic->{id}, $filename);
  return 1;
}

sub for_each {
  my $self = shift;
  my $sub  = shift;

  my $i = 1;
  while($i <= $self->size) {
    &{$sub}( word => $i, occ  => $self->occ($i), vals => $self->vals($i));
    $i++;
  }
}

sub exists {
  my $self = shift;
  my $id = shift;
  return 1 if $id > 0 && $id <= $self->size;
  return 0;
}

sub size {
  my $self = shift;
  return Lingua::NATools::dicgetsize($self->{id});
}

sub enlarge {
  my ($self,$nsize) = @_;
  return Lingua::NATools::dicenlarge($self->{id}, $nsize);
}

sub set_occ {
  my ($self, $wid, $occ) = @_;
  return Lingua::NATools::dicsetocc($self->{id}, $wid, $occ);
}

sub occ {
  my $self = shift;
  my $word = shift;
  return Lingua::NATools::dicgetocc($self->{id}, $word);
}

sub set_val {
  my ($self, $wid, $offset, $twid, $val) = @_;

  return Lingua::NATools::dicsetvals($self->{id}, $wid, $offset, $twid, $val);
}

sub vals {
  my $self = shift;
  my $word = shift;
  return Lingua::NATools::dicgetvals($self->{id}, $word);
}

1;
__END__

=head1 NAME

Lingua::NATools::Dict - Perl extension to encapsulate Dict interface

=head1 SYNOPSIS

  use Lingua::NATools::Dict;

  $dic = Lingua::NATools::Dict::open("file.bin");

  $dic->save($filename);
  $dic->close;

  $dic->add($dic2);

  $dic->size();

  $dic->exists($id);
  $dic->occ($id);
  $dic->vals($id);

  $dic->for_each( sub{ ... } );

=head1 DESCRIPTION

The Dict files (with extension C<.bin>) created by NATools, are
mapping from identifiers of words on one corpus, to identifiers of
words on another corpus. Thus, all operations performed by this module
uses identifiers instead of words.

You can open the dictionary using

  $dic = Lingua::NATools::Dict::open("dic.bin");

Then, all operations are available by methods, in a OO fashion. After
using the dictionary, do not forget to close it using

  $dic->close().

The C<add> method receives a dictionary object and adds it with the
current contents. Notice that both dictionaries need to be congruent
relatively to word identifiers. After adding, do not forget to save,
if you with, with

   $dic->save("new.dic.bin");

The C<size> method returns the total number of words on the corpus
(the sum of all word occurrences). To get the number of occurrences
for a specific word, use the C<occ> method, passing as parameter the
word identifier.

To check if an identifier exists in the dictionary, you can use the
C<exists> method which returns a boolean value.

The C<vals> method returns an hash of probable translations for the
identifier supplied B<< AS A ARRAY REFERENCE >>. The hash contains as
keys the identifiers of the possible translations, and as values their
probability of being a translation.

Finally, the C<for_each> method makes you able to cycle through all
word on the dictionary. It receives a funcion reference as argument.

  $dic->for_each( sub{ ... } );

Each time the function is called, the following is passed as C<@_>:

  word => $id , occ => $occ , vals => $vals

where C<$id> is the word identifier, C<$occ> the result of calling
C<occ> with that word, and C<$vals> is the result of calling C<vals>
with that word.

=head1 SEE ALSO

See perl(1) and NATools documentation.

=head1 AUTHOR

Alberto Manuel Brandao Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by NATURA Project
http://natura.di.uminho.pt

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut
