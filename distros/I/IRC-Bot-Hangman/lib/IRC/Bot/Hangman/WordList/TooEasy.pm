=head1 NAME

IRC::Bot::Hangman::WordList::TooEasy - A simple demo word list

=head1 SYNOPSIS

See IRC::Bot::Hangman

=head1 DESCRIPTION

This module provides a very easy to guess word list,
for demo purpose.

A word list plugin is basically a method name()
and a __DATA__ section containing the words.

=cut

package IRC::Bot::Hangman::WordList::TooEasy;
use warnings::register;
use strict;


=head1 METHODS

=head2 name()

This plugin name - 'too_easy'

=cut

sub name () { 'too_easy' }



1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut


__DATA__
train
lorry
hat
cat
pat
house
table
food
dog
food
sport
fairy
princess
girl
boy
school
pet
shop
book
cow
elephant
blue
red
black
white
purple
yellow
flat
clock