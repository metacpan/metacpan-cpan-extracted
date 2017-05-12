package Lingua::FeatureMatrix;

use 5.006;
use strict;
use warnings;
use Graph::Directed;
use Carp;
##################################################################
# package globals
our $VERSION = '0.05';
##################################################################
# data methods install using Class::MM
use Class::MethodMaker
  new_with_init => 'new',
  new_hash_init => 'hash_init',
  get_set => [ qw [ _emeType _featureClassType ],
	       qw [_eme_new_opts _fclass_new_opts ] ],

  get_set => [ 'report', 'graph' ],

  get_set => 'Name',
  object => [ Graph::Directed => 'implicature_graph',],
  get_set => 'fh',
#  object_list => [ Lingua::FeatureMatrix::Implicature => 'implicatures' ],

  # Lingua::FeatureMatrix::FeatureClass (or subclass) objs
  hash => 'featureClasses',
  # Lingua::FeatureMatrix::Eme subclass objs
  hash => 'emes';

use Lingua::FeatureMatrix::Implicature;
use Lingua::FeatureMatrix::FeatureClass;
##################################################################
sub init {
  my $self = shift;
  my ($class) = ref($self);

  my (%args) = @_;

  my $file = $args{file};
  if (not defined $file) {
    croak "$class must be initialized with a 'file' => name",
      " or 'file' => filehandle key/value pair";
  }
  if (ref($file))  {
      $self->Name('');
      if (UNIVERSAL::isa($file, 'IO::Handle') or UNIVERSAL::isa($file, 'GLOB')) {
	  $self->fh($file);
      }
      else {
	  croak "file handed in is a ", ref($file),
	    " and apparently not a descendant of IO::Handle!";
      }
  }
  else {
      $self->Name( $file );
      require IO::File;
      # open the filehandle
      my $fh = IO::File->new($file) or croak "couldn't open $file: $!\n";
      $self->fh($fh);
  }



  if ($args{report}) {
    $self->report($args{report});
  }
  else {
    $self->report('');
  }

  if ($args{graph}) {
    $self->graph($args{graph});
  }
  else {
    $self->graph('down');
  }

  $self->implicature_graph( Graph::Directed->new() );
  if ($self->graph eq 'down') {
    $self->implicature_graph->set_attribute(label =>
					    'Feeding and Bleeding ' .
					    'relationships');
  }
  elsif ($self->graph eq 'up') {
    $self->implicature_graph->set_attribute(label =>
					    'Possible but ignored feeding ' .
					    'and bleeding relationships');
  }
  else {
    warn "don't know what the 'graph' parameter " .
      $self->graph() . " means\n";
  }
  $self->implicature_graph->set_attribute(ratio => 1);

  # set up to know which subclasses to use:

  # we had better find out what Eme class this is
  $self->_setEmeType($args{eme}, $args{eme_opts});

  # we might also have been instructed on a subtype of featureclass to use
  $self->_setFeatureClass($args{featureclass}, $args{featureclass_opts});

  # so far, no requirement to be able to subclass the
  # implicature. Leave it that way for now.

  # TO DO: add other more direct ways to initialize dynamically if
  # needed
  $self->_loadFile(); #$file);

  # fill out any features based on implicatures
  $self->_completeSpecifications();
}
##################################################################
sub _setEmeType {
  my $self = shift;
  my $class = ref($self);
  my $emeType = shift;
  my $eme_new_opts = shift;
  if (not defined $emeType) {
    croak "$class must be initialized with an ( " .
      "'eme' => Lingua::FeatureMatrix::Eme-subclass-name ) key-value pair";
  }

  # make sure that the class specified is loadable
#   eval "require $emeType";
#   if ($@) {
#     croak "trouble loading $emeType: $@; exiting";
#   }
  if (not $emeType->isa('Lingua::FeatureMatrix::Eme')) {
      croak "$emeType (provided as 'eme' parameter to $class)" .
	  " is not a Lingua::FeatureMatrix::Eme!\n";
  }
  if ($emeType eq 'Lingua::FeatureMatrix::Eme') {
    croak "eme parameter to Lingua::FeatureMatrix must be a *derived* " .
      "subclass, since L::FM::Eme has abstract functions\n";
  }
  if (my $error =$emeType->failsContract()) {
    croak "$emeType fails to meet Lingua::FeatureMatrix::Eme contract: ",
      $error, "\n";
  }

  $self->_emeType( $emeType );

  # TO DO: undocumented feature allows more powerful subclassing of
  # Eme objects, by passing more parameters to the Eme-building
  # routines from this class
  if (not defined $eme_new_opts) {
    $self->_eme_new_opts( [] );
  }
  elsif (ref($eme_new_opts) eq 'ARRAY') {
    # it's an arrayref. that's what we want.
    $self->_eme_new_opts( $eme_new_opts );
  }
  elsif ( not ref($eme_new_opts) ) {
    # it's a scalar. Package it up to be an arrayref anyway.
    $self->_eme_new_opts( [ $eme_new_opts ] )
  }
  else {
    croak "eme_opts parameter to ", ref($self),
      " requires arrayref or scalar, not ", ref($eme_new_opts);
  }
} # end _setEmeType
##################################################################
sub _setFeatureClass {
  # TO DO: user-document this undocumented feature, which allows
  # subclassing of the FeatureClass object. Defaults to the base class
  # if user ignores it, though.
  my $self = shift;
  my $featureclass = shift;
  my $fClass_opts = shift;
  if (not defined $featureclass) {
    $featureclass = 'Lingua::FeatureMatrix::FeatureClass';
  }

  if (not $featureclass->isa('Lingua::FeatureMatrix::FeatureClass')){
    croak "featureclass parameter '$featureclass' to ",
      ref($self), " not a Lingua::FeatureMatrix::FeatureClass " ,
	"subclass!";
  }
  $self->_featureClassType( $featureclass );

  if (not defined $fClass_opts) {
    $self->_fclass_new_opts( [] );
  }
  elsif (ref($fClass_opts) eq 'ARRAY') {
    $self->_fclass_new_opts( $fClass_opts );
  }
  elsif ( not ref($fClass_opts) ) {
    $self->_fclass_new_opts( [ $fClass_opts ] )
  }
  else {
    croak "featureclass_opts parameter to ", ref($self),
      " requires arrayref or scalar, not ", ref($fClass_opts);
  }
}
##################################################################
sub _loadFile {
  # grabs all lines from config file, strips comments and spaces
  my $self = shift;
  my $file = $self->Name();

#   open(IN,$file) or die "cannot open $file $!\n";

  my $fh = $self->fh();
  # sort data into maps, eme-specifications, and class-specifications

  while (<$fh>) {
    # clean up lines
    chomp;
    $_ = set_utf($_);
    tr/\x{FEFF}//d;
    next if /^#/; # drop comments
    s/\s//g;      # and spaces
    next if not length($_);  # and skip blank lines

    # TO DO: eval the following block, and trap errors. Report them
    # with line numbers for the user

    if (/^ \( (.+) \=\> (.+) \) $/x) {
      #  ( +vow => +son )
      #  ( +cons => *tense )
      $self->_readImplicature($1, $2);
    }
    elsif (/^class (\S+) \=\> (.+) $/x) {
      #  class AFF => [ +stop +fric ]
      $self->_readClass($1, $2);
    }
    elsif (/^ (\S+) (\[.*) $/x) {
      #  A [ +vow +low -tense ]
      $self->_readEme($1, $2);
    }
    else {
      # TO DO: document proper .dat file format
      die "datafile $file has bad format in line $., '$_'\n";
    }
  }
  close $fh or croak "couldn't close file ", $self->Name();
#  close (IN) or die "can't close file $file $!\n";
}
##################################################################
sub _readImplicature {
  my $self = shift;
  my $class = ref($self);

  my ($implier, $implicant) = @_;

  my %implier = $class->_getFeatureSet($implier);
  my %implicant = $class->_getFeatureSet($implicant);

  # TO DO: check the featureset used here against whether it's legal.

  my $implicature =
    Lingua::FeatureMatrix::Implicature->new(\%implier, \%implicant);

  $self->add_implicature($implicature);
}
##################################################################
sub _readClass {
  my $self = shift;
  my $class = ref($self);

  my ($fClassName, $req_features) = @_;

  my %required = $class->_getFeatureSet($req_features);

  my $fClassType = $self->_featureClassType();

  my $featureClass =
    $fClassType->new(name => $fClassName, features => \%required);
  $self->featureClasses( $fClassName => $featureClass );
}
##################################################################
sub _readEme {
  my $self = shift;
  my ($symbol, $features) = @_;

  if (defined $self->emes($symbol)) {
    my $eme = $self->emes($symbol);
    carp "at line $.: but $symbol previously defined as ",
      $eme->dumpFeaturesToText($eme->listUserSpecified());
  }

  my $class = ref($self);

  my (%features) = $class->_getFeatureSet($features);
  my $eme =
    $self->_emeType()->new(name => $symbol,
			   options => $self->_eme_new_opts(),
			   %features,
			  );

  $self->emes($symbol => $eme);
}
##################################################################
sub add_implicature {
  my $self = shift;
  my Lingua::FeatureMatrix::Implicature $impl = shift;
#   $self->implicature_graph(
  my (@otherIndices) =
#    map {$self->implicature_graph->get_attribute('object', $_)}
      $self->implicature_graph->vertices();
  my $insert_index = scalar (@otherIndices);

  $self->implicature_graph->add_vertex($insert_index);
  # add a bunch of details about this object:

  # machine-readable 'object'
  $self->implicature_graph->set_attribute(object => $insert_index,
					  $impl);
  # human-readable 'label'
  $self->implicature_graph->set_attribute(label => $insert_index,
					  $impl->dumpToText);

  # see how this new implicature fits into the dependency (ordering).
  foreach my $otherIdx (@otherIndices) {
    # yes, we have an n-squared scaling here. Tens of thousands of
    # rules will have problems, but hundreds should still only take
    # seconds, maximum. I hope. Don't really know how to build this
    # graph any other way... :-/

    my $other =
      $self->implicature_graph->get_attribute(object => $otherIdx);

    my (@inDeps) = $impl->dependsOn($other);
    my (@outDeps) = $other->dependsOn($impl);

    if (@inDeps) {
      if ($self->graph =~ /down/) {
	$self->implicature_graph->add_edge($otherIdx, $insert_index);
	$self->implicature_graph->set_attribute( label =>
						 $otherIdx, $insert_index,
						 (join " ", @inDeps));
      }
    }
    if (@outDeps) {
      # these are dependencies that suggest that it *could* have
      # bled/fed rules higher up in the ordering.
      if ($self->graph =~ /up/) {
	$self->implicature_graph->add_edge($insert_index, $otherIdx);
	$self->implicature_graph->set_attribute( label =>
						 $insert_index, $otherIdx,
						 (join " ", @outDeps));
      }
      if ($self->report() eq 'back-dependencies') {
	carp $impl->dumpToText(), "(implicature number $insert_index)",
	  " could have been applied before ", $other->dumpToText(),
	    " (implicature number $otherIdx)",
	      " despite their input in the other order.";
      }
    }
  } #end foreach otheridx


}
##################################################################
sub _completeSpecifications {

  my $self = shift;

#   my $ordered_impls =
#     Lingua::FeatureMatrix::Implicature->order

#    {
#     my @ordered =
#       Lingua::FeatureMatrix::Implicature->sortByRuleOrder($self->implicatures());
#     $self->implicatures_clear();
#     $self->implicatures_push(@ordered);
#   }

  my (@orderedImpls) = $self->orderImplicatures();

  foreach my $emeName (sort $self->emes_keys) {

    my $eme = $self->emes($emeName);
    # future might consider a toposort here...
    foreach my $implicature (@orderedImpls) {
      if ( $implicature->matches( $eme ) ) {
	$implicature->apply( $eme );
      }
    }

    my (@missing) = $self->emes($emeName)->listUnspecified();
    if (@missing) {
      warn $self->_emeType . " '$emeName' " .
	"(a Lingua::FeatureMatrix::Eme subclass) " .
	  "was not fully specified after application of implicatures " .
	    "(missing feature(s) [ @missing ]).\n";
    }

  }
}
#################################################################
sub _getFeatureSet {
    # returns a hash of ( feature1 => 1, feature2 => 0, feature3 => undef )
    # style data, given "[+feature1 -feature2 *feature3]" style string
    my $class = shift;
    my $featureset = shift;

    if (not defined $featureset) {
      confess;
    }

    $featureset =~ s/^\[//; # remove leading & trailing brackets
    $featureset =~ s/\]$//;

    # assumes no features use + or - within their names.
    my (@featureData) = split( /([+*-])/, $featureset);

    @featureData = grep {$_ ne ''} @featureData;

    if ( not (@featureData % 2) ) {
	# odd
    }

    @featureData = map { $_ eq '-' ? 0 : $_ } @featureData;
    @featureData = map { $_ eq '+' ? 1 : $_ } @featureData;
    @featureData = map { $_ eq '*' ? (undef $_) : $_ }  @featureData;

    # reversing the @featureData list puts keys before values, instead
    # of the linguistic standard of value/key
    # (e.g. +vow becomes vow => 1)
    # note earlier listings override later
    return reverse @featureData;
}
##################################################################
# main public access method.
sub matchesFeatureClass {
  my $self = shift;
  my ($class) = ref($self);
  my $symbol = shift;
  my $className = shift;

  my $eme = $self->emes($symbol);
  croak "unrecognized $class symbol $symbol" unless defined $eme;

  my $featureClass = $self->featureClasses($className);
  croak "unrecognized class $className" unless defined $featureClass;

  return $featureClass->matches($eme);
}
##################################################################
# public (probably debugging) method
sub listFeatureClassMembers {
    my $self = shift;
    my $className = shift;

    my $featureClass = $self->featureClasses($className);
    croak "unrecognized class $className" unless defined $featureClass;

    my @symbols;

    foreach my $symbol (sort $self->emes_keys()) {
      if ( $featureClass->matches( $self->emes($symbol) ) ) {
	push @symbols, $symbol;
      }
    }
    return @symbols;
}
##################################################################
sub orderImplicatures {
  # return "ordered" list of implicatures.
  my $self = shift;

  # "By Any Means Necessary" --Malcolm X


  return
    map {$self->implicature_graph->get_attribute('object',$_)}
      sort { $a <=> $b } $self->implicature_graph->vertices();

  # Schwartzian Transform is a good means.
#     map {$_->[0]}                  # (3) strip sort index
#       sort { $a->[1] <=> $b->[1] } # (2) sort items by the sort index
# 	map { [$_ =>               # (1) get a sort index for each
# 	       $self->implicature_graph->get_attribute('insert_index', $_)] }
# 	  $self->implicature_graph->vertices();


  # future improvements will include a toposort call.


}
##################################################################
sub findEquivalentEmes {
  my $self = shift;
  my (@symbols) = $self->emes_keys();

  # wantarray returns undef in void context
  if (not defined wantarray()) {
      carp "useless call to findEquivalentEmes() in void context";
      return; # don't bother doing any work
  }

  my %problems;
  while (@symbols) {
    my $thisSymbol = shift @symbols;
    my $thisEme = $self->emes($thisSymbol);
    foreach my $otherSymbol (@symbols) {
      if ($thisEme->isEquivalent($self->emes($otherSymbol))) {
        $problems{$thisSymbol} = $otherSymbol;
      }
      # else this eme not equivalent to any remaining eme
    } # end foreach othersymbol
  } # end while @symbols remaining

  if (wantarray()) {
    return %problems;
  }
  else {
    return (scalar(keys %problems));
  }
} #end findEquivalentEmes
##################################################################
# debugging public method
sub dumpToText {
  # debugging function
  my $self = shift;
  my $lineLength = shift;

  local $Text::Wrap::columns = (defined $lineLength ?
				  $lineLength : $Text::Wrap::columns);
  my (@text);
  # loop over emes, dumping each one into filename
  use Text::Wrap;
  foreach my $symbol (sort $self->emes_keys) {
    my $emeText = $self->emes($symbol)->dumpToText();

    my $line = $symbol . "\t" . $emeText;

    push @text, ($Text::Wrap::columns ?
		   wrap ('', "\t  ", $line) : $line);
  }

  return join ("\n", @text);
}
##################################################################
sub set_utf {
    # thanks to perlmonks' grantm
    # (http://www.perlmonks.org/index.pl?node=grantm) for saving me
    return pack "U0a*", join '', @_;
}
##################################################################
1;

__END__

=head1 NAME

Lingua::FeatureMatrix - Perl extension for configuring groups of
(e.g.) phonemes into feature groups

=head1 SYNOPSIS

  use Lingua::FeatureMatrix;

  # this example uses the module provided in the examples directory of
  # the distro; you'll want to create your own 'Eme' subclass or
  # modify 'Phone.pm' for yourself:

  use lib 'examples';
  use Phone;

  # construct a new feature-matrix from a dat file (here using dat
  # file same as example below)
  my $matrix =
    Lingua::FeatureMatrix->new(eme => Phone,
                               file => 'examples/phonematrix.dat');

  if ($matrix->matchesFeatureClass('EE', 'VOW')) {
    # EE is a "vow", bless this properly
    push @Pope::ISA, 'Catholic';
  }

  if (not $matrix->matchesFeatureClass('AA', 'AFF')) {
    # will be executed
    $deadman->walking();
  }

  if ($matrix->matchesFeatureClass('S', 'VOW')) {
    # won't happen
    map { $_->fly() } @pigs;
  }

  # silliness aside, you can also dump a filled-out matrix, with all
  # the implications spelled out, after loading it:
  print $matrix->dumpToText(), "\n";

  # you can also ask for a list of the emes that match a given object:
  print "the vowels are:\n",
    join ' ', $matrix->listFeatureClassMembers('VOW');
  print "the affricates are:\n",
    join ' ', $matrix->listFeatureClassMembers('AFF');

=head1 DESCRIPTION

C<Lingua::FeatureMatrix> is a class for managing user-defined
feature-sets.  It provides an implementation of datafile parsing that
is generic and useful for anyone defining feature sets of symbols.

If you haven't read the L</Motivation> you might want to skip down to
it.

Featuresets are a common way of describing phonetics problems,
e.g. sound change behaviors, but may be useful to people solving other
problems as well. (The included C<Letter> class may, for example, be
useful in writing ligature rules -- if you find this useful for some
other application, please contact the author.)

Users must indicate what type of C<Eme> they are working with. In
fact, users will probably want to define their own. To do this, define
a subclass of C<Lingua::FeatureMatrix::Eme> and indicate that one as
the C<eme> parameter to the C<new()> method call.

=head2 Creating your own C<Eme> type

Users should not have to provide very much to construct their own
C<Lingua::FeatureMatrix::Eme> that supports all the features you're
interested in.

See L<Lingua::FeatureMatrix::Eme> for details on what's
required to properly subclass C<Lingua::FeatureMatrix::Eme>.

If you'd rather not follow through on all the details specified there,
you can use one of the two stubby subclasses C<Phone> and C<Letter>
provided in the C<examples/> directory of this distribution as a
jumping-off point. They too are documented, and have a loose licensing
condition for your unrestricted use (see the C<README>).

=head1 Methods

=head2 Class methods

=over

=item new

Takes the following key-value named parameters:

=over

=item eme

Specifies the desired C<Lingua::FeatureMatrix::Eme> subclass to use
with this C<Lingua::FeatureMatrix>.

=item eme_opts

=item featureclass

=item featureclass_opts

=item file

=back

=back

=head2 Instance methods

TO DO: complete documentation for these methods

=over

=item matchesFeatureClass

=item listFeatureClassMembers

=item findEquivalentEmes

=item dumpToText

=item add_implicature

=item implicature_graph

=back

=head1 Tutorial

=head2 Vocabulary

To keep this system general, there are several important terms to understand:

TO DO: clarify this vocabulary intro

=over

=item eme

I use the word I<eme> to describe a single unit (one row of the
feature matrix.)

(Think I<phoneme> or I<grapheme>.)

=item implicature

Note these are language-specific. (TO DO: Give example here.)

(Think I<synchronic rule> or I<feature generalization>.)

=item feature class

(Think I<composite feature>.)

=item feature

(Think I<single bit of descriptive information>.)

=over

=item +

=item -

=item *

=back

=head2 Datafile format

You might want to begin by opening the C<phonematrix.dat> file or the
C<lettermatrix.dat> file included in the C<examples> directory of this
distribution.  These use the feature sets defined by C<Phone.pm> and
C<Letter.pm>, sample C<Eme> classes each also included in the same
directory.

First, some basic terms that make up the underlying grammar of these
datafiles:

=over

=item SIGN

Either C<+>, C<->, or C<*>, indicating the values of C<1>, C<0>, and
C<undef> respectively.

=item FEATURE

A case-sensitive text string like C<vow> indicating the name of the
C<Eme> feature. Always used with C<SIGN>.

=item FEATURESET

A complex grouping of one or more C<SIGN>C<FEATURE> pairs, surrounded
by C<[]>, like:

  [ +voice +fric +stop ]

=item PHONESYMBOL

a string of characters matching the C</\S+/> regular expression. This
is so widely accepting because of the large variety of phonetic
representation schemes available. Leaving this agnostic allows users
to use, e.g.:

(TO DO: include examples here):

=over

=item UTF-8 IPA symbols

=item Pronlex symbols

=item DARPAbet

=item SAMPA (aka IPA-for-ASCII)

=back

=back

Each line in the datafile should be considered an entire
statement. You'll find that the datafiles are made up of four kinds of
lines.  I<Comments>, I<Eme descriptions>, I<Implicatures>, and
I<feature classes>. Future versions of this module may include more
types of lines.

All lines are insensitive to whitespace, except for a I<Comment> line
(which isn't a I<Comment> at all unless there is no whitespace before
the '#').

=over

=item Comments

Any line beginning with a '#' is a comment, and the entire line is
ignored. Note if the '#' is I<not> the first character on a line, it
is not ignored.  This is the only place that whitespace is considered
in this grammar.

=item Eme descriptions

Any line which takes the form:

  PHONESYMBOL [ FEATURESET ]

For example,

  CH [ +stop +fric -voice ]
  J  [ +stop +fric +voice ]

  S [ +fric +sib +alv -voice ]
  Z [ +fric +sib +alv +voice ]

  SH [ +fric +sib +pal -voice ]
  ZH [ +fric +sib +pal +voice ]

  AA [ +low -back -front -tense ]

  IY [ +high +front +tense ]

It is acceptable, even encouraged, to "underspecify", that is, to
specify only those features which are needed to distinguish each phone
from its neighbors. If you do so, you will probably want to include
extra I<implicatures> though, since any C<Eme> that does not have all
its features specified after the I<implicatures> are processed will
invoke a C<carp>, which can get irritating.

=item Implicatures

Any line which takes the form

  ( FEATURESET => FEATURESET )

represents an I<Implicature>. The left C<FEATURESET> is called the
I<implier> and the right is called the I<implicant>.

As a special case, the C<FEATURESET>s involved may omit the C<[]> if
there is only one feature.

Implicatures allow the user to easily encode lots of different C<Eme>s
by encoding general "common sense" ideas. For example:

  ( +stop => +cons )

This means that an C<Eme> that is C<+stop> should be marked C<+cons>
by implication. (If this isn't an obvious implication, you may need
some phonology review, or you may be speaking Czech or Berber, and I
can't help you much with either problem.)

Note that more than one feature may imply the same setting, even to
the same C<Eme>. This is acceptable:

  ( +fric => +cons )
  ( +stop => +cons )

Both of these will apply to the following C<Eme> definition:

  CH [ +fric +stop -voice ]

Implicatures are one-way, or else the following wouldn't work:

  ( -tense => +vow )
  ( +tense => +vow )

(The two implications above indicate that if C<tense> is specified
I<at all>, then C<vow> should be C<+> by implication.)

An implicature need not set a single feature in the I<implicant>, nor is it
restricted to only one feature in the I<implier>.

  ( +sib => [ -voice +cons ] )
  ( [ +vow +cons ] => [ +glide ] )

Note that some implicatures can point out that a certain field had
better *not* be set (to either plus or minus); here we use the
'ungrammatical' C<*> marker:

  ( +cons => *tense )
  ( +vow => [ *stop *fric ] )

The first example above indicates that if C<cons> is true, then it is
I<ungrammatical> to specify a boolean value for C<tense>, and the
second indicates that if C<vow> is true, then it is I<ungrammatical>
to specify C<stop> or C<fric>. Note that the C<*fric> setting may not
be correct in languages other than English; that's the point of
putting all this in a configuration file.

Sometimes putting "obvious" things into implicatures can help catch
silly mistakes in your I<eme definitions>, especially when you can
specify ungrammaticality:

  # can't be both high and low (though [-high -low] is okay)
  # seems obvious here...
  ([+high] => [*low])
  ([+low] => [*high])

  # 200 lines later, by which point we've forgotten our decision
  # about the relationship between high and low...

  # the following eme definition croaks with a warning:
  EH [ +high +low -tense ]
  # should have been:
  # EH [ -high -low -tense ]

Using a C<*> value sets that C<feature> of the C<Eme> to be C<undef>,
rather than C<1> or C<0>, which is Perl's way of indicating "neither
false nor true, but the question is meaningless."

Note that for the time being, the implicatures are applied in the
order that they are submitted to the system.  Future editions may
involve automatic ordering of the implicatures (see L</Future
Improvements>).

See L<Lingua::FeatureMatrix::Implicature>.

=item Feature classes

  class AFF => [ +stop +fric ]
  class LOW_VOW => [ +low +vow ]

=back

=head2 Motivation

I need a tool that constructs objects representing the featureset of a
phoneme. The standard linguistic notation for this is (for the 'ch',
the 'eh', and the 's' sound in "chess"):

  CH [ +stop +fric -voice +palat +cons -vow ]
  EH [ +vow -cons -low -high +front -tense ]
  S  [ +cons +fric -stop +alv -voice ]

Furthermore, I may want to be able to refer to "feature classes", that
is, composite features like "affricate":

  class AFF [ +stop +fric ]

(this example would match 'CH' but not 'S' or 'EH').

To complicate things further, the list of primitive features is
linguistically controversial, the set of relevant classes varies from
language to language, even if you agree on the theoretical primitives,
and the choice of symbol set to represent the phoneme (IPA, Sampa,
DARPA-bet, etc) is varied and political.

Thus, in the finest Perl sense, TMTOWTDI.  The dimensions of
flexibility provided are:

You, the user, define what you want to be the featureset by
subclassing C<Lingua::FeatureMatrix::Eme>, distributed with this
module. An added side bonus is that you decide whether the base unit
is a C<Phone> or a C<Phoneme> (or, for that matter, a C<SoundUnit> or
a C<Letter> -- that subclass is I<your> module, and the goal is to
"[put] the focus not so much onto the problem to be solved, but rather
onto the person trying to solve the problem." (see Larry Wall's talk
on Perl and postmodernism L<http://kiev.wall.org/~larry/pm.html>).

You, the user, define what the feature set is, and you define how the
phones (er, I<emes>) distribute among those features, using the best
of I<Impatience> -- use the existing linguistic typographic
conventions, and this module takes care of constructing your objects
for you. No translating among conventions for us (that wouldn't be I<Lazy>!).

But let's go one step further. Languages include redundancy, and
sometimes it's boring (and not I<Lazy>) to have to specify yourself
that something that is C<[+stop]> is also C<[-vow +cons]>, especially
if you have to specify this for every single C<[+stop]> consonant.

So this module also introduces the concept of an I<implicature> -- you
can say, in simple, linguistically-familiar format, that

  ( [+stop] => [-vow +cons] )

and this will apply for all phones in the current dataset (unless I'm
speaking Berber, where this isn't necessarily true...). It's also I<Lazy>,
because the module also does the work of letting me know whether I
have forgotten to specify any of the features of a given phone:

  # probably missing a feature or six; would generate a warning.
  T [ +cons -vow ]

Along the way, we pick up some I<Hubris>:

=over

=item *

Doesn't apply just to phones anymore -- we can use it for letters and
ligatures, if we want.

=item *

It should be extensible to use these objects to connect to other
linguistics-style programs like C<Lingua::SoundChange>, not to
mention homebrew pronunciation algorithms like C<Lingua::Soundex>.

=back

=head1 HISTORY

=over

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Lingua::FeatureMatrix

=item 0.02

Now includes lots of error-checking code for handling implicatures
better. Still remaining, lots to do, but now can probably be
understood by somebody who hasn't read the whole code.

Also includes a lot of documentation, among which is an elaborate
L</Motivation>.

=item 0.03

=over

=item Fixes for Makefile.PL dependency

=item Added checks for Eme subclass contract conformity

=item Better/more flexible featureclass acceptance

=item Improved tests, examples

=back

=item 0.04

=over

=item improved testing

=item restructured implicatures (now stored as a Graph not a list)

=back

=item 0.05

=over

=item now can hand in a filehandle or a file to the file argument

=back

=back

If you find any bugs or need additional features, please inform the
author -- and check CPAN; this module is under development and may
have recently added the feature you need.

=head1 Further reading

For some discussion and ideas about applications of feature matrices:

=over

=item *

A phonetics description:

L<http://www.essex.ac.uk/speech/teaching-01/documents/df-theory.html>

=item *

Here's an implementation possibility:

L<http://kom.auc.dk/~tb/articles/LREC_article.pdf>

=item *

I bet Knuth's typography book might lead 

=item TO DO: add more

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

Special thanks to Dr. Kate Davis, who acted as the phonetics-theory
sounding board for this project.

=head1 Future Improvements

=over

=item add testing cases

Includes understanding why the limited test cases provided here fail.

=item connect to others

E.g. C<Lingua::SoundChange>.

=item autosort implicatures

would require building a graph and toposorting it

=item add diachronic/sound change functions

But make sure we don't rebuild the wheel.

=back

=head1 SEE ALSO

L<perl>.

L<Lingua::FeatureMatrix::Eme>.

=cut
