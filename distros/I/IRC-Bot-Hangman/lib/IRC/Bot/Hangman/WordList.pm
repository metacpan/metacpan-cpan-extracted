=head1 NAME

IRC::Bot::Hangman::WordList - Word list plugin engine

=head1 SYNOPSIS

  use IRC::Bot::Hangman::WordList;
  $words = IRC::Bot::Hangman::WordList->load( 'too_easy' );
  print $words->[3];

=head1 DESCRIPTION

This module loads the word list plugins
and provide a list based on a name

=cut

package IRC::Bot::Hangman::WordList;
use warnings::register;
use strict;
use Carp qw( carp croak );
use Module::Find qw( useall );

our %WORDLISTS = map { $_->name => $_ } useall( __PACKAGE__ );



=head2 load( plugin name )

Returns a word list loaded
from a specific plugin

=cut

sub load {
  my $class  = shift;
  my $name   = shift;
  my $module = $WORDLISTS{$name};
  unless ($module) {
    carp "$name is not a registered word list, try " . join(' or ', keys %WORDLISTS);
    return;
  }

  $class->word_list( $module );
}


=head2 word_list

Loads the word list

=cut

sub word_list {
  my $self   = shift;
  my $module = shift;
  my $fh = "${module}::DATA";
  my @words;
  while (<$fh>) {
    chomp;
    push @words, $_ if $_;
  }
  \@words;
}


1;


=head1 AUTHOR

Pierre Denis <pierre@itrelease.net>

http://www.itrelease.net/

=head1 COPYRIGHT

Copyright 2005 IT Release Ltd - All Rights Reserved.

This module is released under the same license as Perl itself.

=cut