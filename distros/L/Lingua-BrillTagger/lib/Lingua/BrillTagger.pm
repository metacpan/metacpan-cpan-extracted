package Lingua::BrillTagger;

use 5.006;
use strict;
use DynaLoader ();

BEGIN {
  our $VERSION = '0.02';
  our @ISA = qw(DynaLoader);
  __PACKAGE__->bootstrap( $VERSION );
}

sub new {
  my $package = shift;
  my $self = bless {
		    lexicon_size => 100_000,
		    @_,
		   }, $package;
  $self->_xs_init($self->{lexicon_size});
  return $self;
}

sub load_lexicon {
  my ($self, $path) = @_;

  open my($fh), $path or die "Can't read lexicon $path: $!";
  while (<$fh>) {
    my ($word, @tags) = split;
    $self->_add_to_lexicon($word, $tags[0]);
    foreach my $tag (@tags) {
      $self->_add_to_lexicon_tags("$word $tag");
    }
  }
  return 1;
}

sub load_bigrams {
  my ($self, $path) = @_;

  open my($fh), $path or die "Can't read bigram file $path: $!";
  while (<$fh>) {
    my ($word1, $word2) = split;
    $self->_add_bigram($word1, $word2);
  }
  return 1;
}

sub load_wordlist {
  my ($self, $path) = @_;

  open my($fh), $path or die "Can't read wordlist $path: $!";
  while (<$fh>) {
    s/^\s+|\s+$//g;
    $self->_add_wordlist_word($_) if length;
  }

  $self->{have_wordlist} = 1;
  return 1;
}

sub load_lexical_rules {
  my ($self, $path) = @_;

  open my($fh), $path or die "Can't read lexical rules $path: $!";
  while (<$fh>) {
    chomp;
    my @line = split or next;
    $self->_add_lexical_rule($_);

    if ($line[1] eq 'goodright') {
      $self->_add_goodright($line[0]);
    } elsif ($line[2] eq 'fgoodright') {
      $self->_add_goodright($line[1]);
    } elsif ($line[1] eq 'goodleft') {
      $self->_add_goodleft($line[0]);
    } elsif ($line[2] eq 'fgoodleft') {
      $self->_add_goodleft($line[1]);
    }
  }
  return 1;
}

sub load_contextual_rules {
  my ($self, $path) = @_;

  open my($fh), $path or die "Can't read contextual rules $path: $!";
  while (<$fh>) {
    next unless /\S/;
    chomp;
    $self->_add_contextual_rule($_);
  }
  return 1;
}

sub tag_initial {
  my ($self, $textref) = @_;
  return [ map { /^[A-Z]/ ? 'NNP' : 'NN' } @$textref ];
}

sub tag {
  my ($self, $text, %options) = @_;
  $text = $self->tokenize($text) unless ref $text;

  my $tags = $self->tag_initial($text);

  $self->_apply_lexical_rules( $text, $tags, $self->{have_wordlist}||0 );
  $self->_default_tag_finish( $text, $tags );


  # Brill uses these fake "STAART" tags to delimit the start & end of sentence.
  push @$text, "STAART", "STAART";
  unshift @$text, "STAART", "STAART";
  push @$tags, "STAART", "STAART";
  unshift @$tags, "STAART", "STAART";

  $self->_apply_contextual_rules( $text, $tags );

  shift @$tags; shift @$tags;
  shift @$text; shift @$text;
  pop @$tags; pop @$tags;
  pop @$text; pop @$text;

  return $text, $tags;
}

my %trans = (chr(145) => "`",
	     chr(146) => "'",
	     chr(147) => "``",
	     chr(148) => "''",
	    );
my $trans_re = join '', keys %trans;

sub tokenize {
  (my $self, local $_) = @_;

  # Normalize all whitespace
  s/\s+/ /g;

  # Fix curly quotes
  s/([$trans_re])/ $trans{$1} /og;


  # The following is patterned after a 'sed' script by Robert
  # MacIntyre, University of Pennsylvania, late 1995.  Found at
  # http://www.cis.upenn.edu/~treebank/tokenizer.sed .


  # Attempt to get correct directional quotes
  s{\"\b} { `` }g;
  s{\b\"} { '' }g;
  s{\"(?=\s)} { '' }g;
  s{\"} { `` }g;

  # Isolate ellipses
  s{\.\.\.}   { ... }g;
  
  # Isolate any embedded punctuation chars
  s{([,;:\@\#\$\%&])} { $1 }g;
  
  # Assume sentence tokenization has been done first, so split FINAL
  # periods only.
  s/ ([^.]) \.  ([\]\)\}\>\"\']*) [ \t]* $ /$1 .$2 /gx;

  # however, we may as well split ALL question marks and exclamation points,
  # since they shouldn't have the abbrev.-marker ambiguity problem
  s{([?!])} { $1 }g;

  # parentheses, brackets, etc.
  s{([\]\[\(\)\{\}\<\>])} { $1 }g;

  s/(-{2,})/ $1 /g;

  # Add a space to the beginning and end of each line, to reduce
  # necessary number of regexps below.
  s/$/ /;
  s/^/ /;

  # possessive or close-single-quote
  s/\([^\']\)\' /$1 \' /g;

  # as in it's, I'm, we'd
  s/\'([smd]) / \'$1 /ig;

  s/\'(ll|re|ve) / \'$1 /ig;
  s/n\'t / n\'t /ig;

  s/ (can)(not) / $1 $2 /ig;
  s/ (d\')(ye) / $1 $2 /ig;
  s/ (gim)(me) / $1 $2 /ig;
  s/ (gon)(na) / $1 $2 /ig;
  s/ (got)(ta) / $1 $2 /ig;
  s/ (lem)(me) / $1 $2 /ig;
  s/ (more)(\'n) / $1 $2 /ig;
  s/ (\'t)(is|was) / $1 $2 /ig;
  s/ (wan)(na) / $1 $2 /ig;

  # Now just split on whitespace
  return [ split ];
}

sub DESTROY {
  my $self = shift;
  $self->_xs_destroy;
}

1;
__END__

=head1 NAME

Lingua::BrillTagger - Natural-language tokenizing and part-of-speech tagging

=head1 SYNOPSIS

  use Lingua::BrillTagger;
  my $t = Lingua::BrillTagger->new;
  
  # Load tagger information
  $t->load_lexicon($path);
  $t->load_bigrams($path);
  $t->load_lexical_rules($path);
  $t->load_contextual_rules($path);
  
  # Tag a sentence
  my $tagged = $t->tag($string);
  my $tagged = $t->tag(\@tokens);
  
  # Tokenize a sentence
  my $tokens = $t->tokenize($string);

=head1 DESCRIPTION

Part-of-speech tagging is the act of assigning a part-of-speech label
(noun, verb, etc.) to each token of a natural-language sentence.

There are many different ways to do this, resulting in lots of
different styles of output and using various amounts of space & time
resources.  One of the most successful recent methods was developed by
Eric Brill as part of his 1993 Ph.D. work at the University of
Pennsylvania: L<"http://www.cs.jhu.edu/~brill/dissertation.ps">.  It
uses the notion of "transformation-based error-driven" learning, in
which a sequence of transformational rules is learned to transform a
naive part-of-speech tagging into a good tagging.

This module, C<Lingua::BrillTagger>, is a Perl wrapper around
Brill's tagger.  The tagger itself is written in C.

=head1 METHODS

The following methods are available in the C<Lingua::BrillTagger>
class:

=over 4

=item new(...)

Creates a new C<Lingua::BrillTagger> object and returns it.  For
initialization, C<new()> accepts a C<lexicon_size> parameter which
should be a good guess integer of how many words are in your lexicon.
It does not need to be precise, as it's just used to set the number of
buckets in the lexicon hash (since it's not a perl hash but a custom
Brill thingy, it really must be set to something reasonable).  The
default is 100,000.

=item load_lexicon($path)

Loads a F<LEXICON> file, in the format described in the F<README.LONG>
file from the Brill tagger distribution.  In a nutshell, the format of
each line is "token tag1 tag2 ... tagn", where tag1 is the most likely
tag for the given token.  Calling this method is mandatory before
tagging.

=item load_bigrams($path)

Loads a F<BIGRAMS> file, in the format described in the F<README.LONG>
file from the Brill tagger distribution.  Calling this method is
optional.

=item load_wordlist($path)

Loads any extra words besides those in C<LEXICON>.  Calling this
method is optional.

=item load_lexical_rules($path)

Loads a F<LEXICALRULEFILE> file, in the format described in the
F<README.LONG> file from the Brill tagger distribution.  Calling this
method is mandatory before tagging.

=item load_contextual_rules($path)

Loads a F<CONTEXTUALRULEFILE> file, in the format described in the
F<README.LONG> file from the Brill tagger distribution.  Calling this
method is mandatory before tagging.

=item tag($string)

=item tag(\@tokens)

Invokes the tagging algorithm on a single sentence, and returns a
two-element list containing a reference to an array of tokens, and a
reference to a corresponding array of tags.  The input may be
specified as a string, in which case it will first be passed to the
C<tokenize()> method; alternatively the input may be given as a
reference to an array of tokens.

=item tokenize($string)

Runs a standard tokenization algorithm for English language free-text
and returns the result as an array reference.  The input should be
specified as a string.


=back

=head1 CONCURRENCY

The Lingua::BrillTagger code will allow you to create more than one
tagger object in the same perl script, by calling C<new()> more than
once.  There should be no problems in the Perl code with doing this,
but because Brill's underlying C code was originally intended to run
in a batch-mode with a single instance of the tagger, it may not work
well in concurrency situations.  If you run into problems, let me
know, especially if you can give me a patch to fix it.

=head1 AUTHOR

Ken Williams, <kwilliams@cpan.org>

=head1 COPYRIGHT

The Lingua::BrillTagger perl interface is copyright (C) 2004 Thomson
Legal & Regulatory, and written by Ken Williams.  It is free software;
you can redistribute it and/or modify it under the same terms as Perl
itself.

The Brill Tagger is copyright (C) 1993 by the Massachusetts Institute
of Technology and the University of Pennsylvania - you will find full
copyright and license information in its distribution.  The
Tagger.patch file distributed here is granted under the same license
terms as the tagger code itself.



=head1 SEE ALSO

L<Lingua::CollinsParser>, L<perl>.

=cut
