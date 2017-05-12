package Lingua::FreeLing3::Sentence;
use Lingua::FreeLing3::Word;
use Lingua::FreeLing3::ParseTree;
use Lingua::FreeLing3::Bindings;

use Scalar::Util 'blessed';
use warnings;
use strict;

use parent -norequire, 'Lingua::FreeLing3::Bindings::sentence';

our $VERSION = "0.03";

# XXX - Missing
#  *words_begin = *Lingua::FreeLing3::Bindingsc::sentence_words_begin;
#  *words_end = *Lingua::FreeLing3::Bindingsc::sentence_words_end;

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::Sentence - Interface to FreeLing3 Sentence object

=head1 SYNOPSIS

   use Lingua::FreeLing3::Sentence;

   # usually you don't need to construct sentences.
   # the constructor also accepts a list of Lingua::FreeLing3::Word's
   my $sentence = Lingua::FreeLing3::Sentence->new("some","sentence");

   my $size = $sentence->length; # returns 2

   # returns array of Lingua::FreeLing3::Word objects
   my @words = $sentence->words;

   # returns string with words separated by spaces
   my $string = $sentence->to_text;

   if ($sentence->is_parsed) {
      # returns Lingua::FreeLing3::ParseTree
      my $parse_tree = $sentence->parse_tree;
   }

   if ($sentence->is_dep_parsed) {
      # returns Lingua::FreeLing3::DepTree
      my $dep_tree = $sentence->dep_tree;
   }

   my $iterator = $sentence->iterator;

=head1 DESCRIPTION

This module is a wrapper to the FreeLing3 Sentence object (a list of
words, that someone has validated as a complete sentence.

=head2 C<new>

The constructor returns a new Sentence object. Can be initialized with
an array of words (strings) or an array of L<Lingua::FreeLing3::Word>
objects (or a mixture of them).

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( [ map {
        if (blessed($_) && $_->isa('Lingua::FreeLing3::Bindings::word')) {
            $_
        } elsif (not ref) {
            Lingua::FreeLing3::Word->new($_);
        } else {
            die "Invalid parameter on Sentence constructor: $_"
        }
    } @_ ] );

    return bless $self => $class #amen
}

sub _new_from_binding {
    my ($class, $sentence) = @_;
    return bless $sentence => $class #amen
}

=head2 C<length>

Returns the sentence length (number of words/tokens).

=cut

sub length { $_[0]->SUPER::size }

=head2 C<words>

Returns a list of L<Lingua::FreeLing3::Word>.

=cut

sub words {
    map {
        $_->ACQUIRE();
        Lingua::FreeLing3::Word->_new_from_binding($_)
      } @{ $_[0]->SUPER::get_words };
}

=head2 C<word>

Returns the nth word.

=cut

sub word {
    my ($self, $n) = @_;
    $n >= $self->length() and return undef;
    Lingua::FreeLing3::Word->_new_from_binding($self->SUPER::get($n));
}

=head2 C<to_text>

Returns a string with words separated by a blank space.

=cut

sub to_text {
    join " " => map { $_->get_form } @{ $_[0]->SUPER::get_words };
}

=head2 C<is_parsed>

Checks if the sentence has been parsed by a parser.

=cut

# sub is_parsed { $_[0]->SUPER::is_parsed() }

=head2 C<parse_tree>

Returns the current parse tree, if there is any.

=cut

sub parse_tree {
    return undef unless $_[0]->is_parsed;

    Lingua::FreeLing3::ParseTree->_new_from_binding($_[0]->SUPER::get_parse_tree());
}

=head2 C<is_dep_parsed>

Checks if the sentence has been parsed by a dependency parser.

=cut

sub is_dep_parsed {
    $_[0]->SUPER::is_dep_parsed();
}

=head2 C<dep_tree>

Returns the current dependency tree, if there is any.

=cut

sub dep_tree {
    return undef unless $_[0]->is_dep_parsed;
    Lingua::FreeLing3::DepTree->_new_from_binding($_[0]->SUPER::get_dep_tree());
}

# =head2 C<iterator>

# Returns a word iterator.

# =cut

# sub iterator {
#     my $self = shift;
#     return $self->SUPER::words_begin;
# }

## debug purposes
sub _dump {
    my $self = shift;
    my @words = $self->words;

    for my $w (@words) {
        my $h = $w->as_hash;
        print "$h->{form}\t$h->{lemma}\t$h->{tag}\n";
    }
}

1;

__END__

=head1 SEE ALSO

Lingua::FreeLing3(3) for the documentation table of contents. The
freeling library for extra information, or perl(1) itself.

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 by Projecto Natura

=cut


