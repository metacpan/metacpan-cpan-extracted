package Lingua::CollinsParser;
our $VERSION = '0.05';
our @ISA = qw(DynaLoader);

use 5.006;
use strict;
use DynaLoader ();
use Lingua::CollinsParser::Node;

bootstrap Lingua::CollinsParser $VERSION;

my $INSTANCE;


sub new {
  # This has to be a singleton, because the underlying C code from
  # Collins keeps its state in global variables.
  return $INSTANCE if defined $INSTANCE;

  my $package = shift;

  my %defaults = (
		  beamsize  => 10_000,
		  punc_flag => 1,
		  distaflag => 1,
		  distvflag => 1,
		  npflag    => 1,
		 );
  
  my $self = bless {
		    %defaults,
		    @_,
		   }, $package;
  $self->_xs_init;
  
  # Actually set the global values in the C code
  foreach my $field (keys %defaults) {
    $self->$field($self->{$field});
  }
  
  return $INSTANCE = $self;
}

# A generic boilerplate getter/setter
sub _access {
  my ($self, $field) = (shift, shift);
  no strict 'refs';
  if (@_) {
    &{"set_$field"}(shift());
  }
  return &{"get_$field"}();
}

sub beamsize  { _access(shift, 'beamsize',  @_) }
sub punc_flag { _access(shift, 'punc_flag', @_) }
sub distaflag { _access(shift, 'distaflag', @_) }
sub distvflag { _access(shift, 'distvflag', @_) }
sub npflag    { _access(shift, 'npflag',    @_) }

1;
__END__

=head1 NAME

Lingua::CollinsParser - Head-driven syntactic sentence parser

=head1 SYNOPSIS

  use Lingua::CollinsParser;
  my $p = Lingua::CollinsParser->new();
  
  my $cp_home = '/path/to/COLLINS-PARSER';
  $p->load_grammar("$cp_home/models/model1/grammar");
  $p->load_events( "$cp_home/models/model1/events");
  
  my @words = qw(The bird flies);
  my @tags  = qw(DT NN VBZ);
  my $tree = $p->parse_sentence(\@words, \@tags);


=head1 DESCRIPTION

Syntactic parsing is the act of constructing a phrase-structure tree
(or several alternative trees) from a natural-language sentence.

There are many different ways to do this, resulting in lots of
different styles of output and using various amounts of space & time
resources.  One of the most successful recent methods was developed by
Michael Collins as part of his 1999 Ph.D. work at the University of
Pennsylvania.  It uses the notion of "head-driven" statistical models,
in which a certain word from each subtree is designated as the "head"
of that subtree.  It can be very useful to use the head words when
analyzing the tree output.

This module, C<Lingua::CollinsParser>, is a Perl wrapper around
Collins' parser.  The parser itself is written in C.

=head1 CONCURRENCY

Because the internal C code of the parser uses lots of global
variables to maintain state, it is currently impossible to create more
than one parser instance at the same time.  Therefore, the class
behaves in a "Singleton" manner, i.e. repeated calls to C<new()> will
actually return the same parser, not actually new ones.

However, if a cleanup effort is undertaken in the parser's C code in
the future, it may be possible to remove its reliance on global
variables, and the C<new()> method could start returning new instances
with each call.  Therefore, please B<don't> rely on future versions of
C<Lingua::CollinsParser> behaving as singletons.

=head1 METHODS

The following methods are available in the C<Lingua::CollinsParser>
class:

=over 4

=item new(...)

Creates a new C<Lingua::CollinsParser> object and returns it.  For
initialization, C<new()> accepts a list of key-value pairs
corresponding to the five accessor methods below (C<beamsize>,
C<punc_flag>, C<distaflag>, C<distvflag>, C<npflag>) - if present, the
accessors will be called and the corresponding values will be passed
to them.

=item beamsize( [value] )

A real number specifying the size of the "beam".  The beam XXX.
Default value is 10000.  Smaller numbers like 1000 may be used to
increase speed at a slight cost in accuracy.

=item punc_flag( [value] )

A boolean flag indicating whether to use the "punctuation constraint".
A description of this constraint comes from Collins' Ph.D. thesis:

=over 4

If for any constituent C<Z> in the chart C<< Z -> <..X Y..> >> two of
its children C<X> and C<Y> are separated by a comma, then the last
word in C<Y> must be directly followed by a comma, or must be the last
word in the sentence.  In training data 96% of commas follow this
rule.  The rule also has the benefit of improving efficiency by
reducing the number of constituents in the chart.

=back

The default is true, i.e. to use the constraint.

=item distaflag( [value] )

A boolean flag indicating whether the "adjacency condition" in the
distance measure should be used.  This is explained somewhere in
Collins' Ph.D. thesis, though I couldn't quite figure out where.
Default is true.

=item distvflag( [value] )

A boolean flag indicating whether the "verb condition" in the distance
measure should be used.  This is explained somewhere in Collins'
Ph.D. thesis, though I couldn't quite figure out where.  Default is
true.

=item npflag( [value] )

A boolean flag indicating whether noun phrases should always include
C<NP> and C<NPB> levels, or whether the extra C<NP> level may be
omitted when superfluous.  The default is to omit, i.e. the flag is
true by default.  For example, with C<npflag=1> you may get the
following structure:

  (TOP (S (NPB the man) (VP saw (NPB the dog))))

whereas with C<npflag=0> you might get the following:

  (TOP (S (NP (NPB the man)) (VP saw (NP (NPB the dog)))))

(This example comes from the README in Collins' parser distribution.)

=item load_grammar($file)

Loads a grammar file (a few sample grammar files ship with Collins'
parser distribution) into the parser.  This must be done before
calling C<parse_sentence()>.

=item load_events($file)

Loads a events file (a few sample events files ship with Collins'
parser distribution) into the parser.  This or C<undump_events_hash()>
must be done before calling C<parse_sentence()>.

=item parse_sentence(\@words, \@tags);

Invokes the parser on the given sentence.  The first argument must be
an array reference containing the words of the sentence.  The second
argument must be an array reference containing those words'
corresponding part-of-speech tags.  A C<Lingua::CollinsParser::Node>
object is returned, representing a syntax tree for the sentence.

To generate the array of part-of-speech tags, you may be interested in
C<Lingua::BrillTagger>, InXight (L<http://www.inxight.com/>), or GATE
(L<http://gate.ac.uk/>).

=item dump_events_hash($file)

It takes a really long time to call C<load_events()>, so this method
is provided to "freeze" the loaded events hash to a file, so that it
can be "thawed" out again later with C<undump_events_hash()>.  This is
much faster.  For instance, if during installation you run the
regression tests twice in a row, you'll notice that the second time is
much faster, because it dumped the hash information the first time.

=item undump_events_hash($file)

Loads an events hash from a file that was previously created using
C<dump_events_hash()>.



=back

=head1 AUTHOR

Ken Williams, ken.williams@thomson.com


=head1 COPYRIGHT

The Lingua::CollinsParser perl interface is copyright (C) 2004 Thomson
Legal & Regulatory, and written by Ken Williams.  It is free software;
you can redistribute it and/or modify it under the same terms as Perl
itself.

The Collins Parser is copyright (C) 1999 by Michael Collins - you will
find full copyright and license information in its distribution.  The
F<Parser.patch> file distributed here is granted under the same license
terms as the parser code itself.


=head1 SEE ALSO

Lingua::CollinsParser::Node

Lingua::BrillTagger

L<http://www.ai.mit.edu/people/mcollins/code.html> (The Collins Parser)

=cut
