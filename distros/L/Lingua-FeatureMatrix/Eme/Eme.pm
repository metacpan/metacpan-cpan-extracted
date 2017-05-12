package Lingua::FeatureMatrix::Eme;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';
##################################################################
use Carp;
use Class::MethodMaker
  new_with_init => 'new',
  new_hash_init => 'hash_init',

  abstract => 'getFeatureNames',
  hash_of_lists => 'by_implication',
  # each key of by_implication is a feature name, each value is a
  # reference to the Implicature object that set that feature.

  get_set => 'name';

##################################################################
sub init {
  my $self = shift;
  my $class = ref($self);

  my %features = @_;
  if ($features{options}) {
    delete $features{options}; # any data here was only for the
                               # subclass
  }
  my (%defaults) = map { $_ => 'unset' } $class->getFeatureNames();

  $self->hash_init(%defaults, %features);
}
##################################################################
sub failsContract {
  my $class = shift;
  my @features;
  eval { @features = $class->getFeatureNames(); };
  if ($@) {
    return "trouble calling $class->getFeatureNames(): " . $@;
  }
  if (not @features) {
    return "No features listed!";
  }
  # check that no feature is listed twice
  my (%features);
  foreach my $feature (@features) {
    if ($features{$feature}) {
      return "listed $feature twice!"
    }
    $features{$feature}++;
  }

  # reaching here indicates that the class fulfils the contract,
  # return false value
  return '';
}
##################################################################
sub explainFeature {
  my $self = shift;
  my $feature = shift;
  if (not $self->_knowsFeature($feature)) {
    return undef;
  }
  else {
    my(@how) = map {$_->dumpToText() } $self->by_implication($feature);
    if (@how) {
      return @how;
    }
    else {
      return "by definition";
    }
  }
}
##################################################################
sub isSpecified {
  my $self = shift;
  my $featureName = shift;
  if (not $self->_knowsFeature($featureName)) {
    die "unknown feature $featureName!\n";
  }
  # undefined is a legal, specified value that indicates "ungrammatical"
  if (not defined $self->$featureName() ) {
    return 1;
  }
  # 'unset' indicates "not yet indicated"
  if ($self->$featureName() eq 'unset') {
    return 0;
  }
  # 0 and 1 are the legal values other than undef
  return ($self->$featureName() == 0 or $self->$featureName() == 1);
} # end isSpecified
##################################################################
sub listUnspecified {
  my $self = shift;
  my $class = ref($self);
  my (@unspecified) = ();
  foreach my $feature ($class->getFeatureNames()) {
    if (not $self->isSpecified($feature)) {
      push @unspecified, $feature;
    }
  }
  return @unspecified;
}
##################################################################
sub isFullySpecified {
  my $self = shift;
  return # whether
    ($self->listUnspecified() == 0);
}
##################################################################
sub listUserSpecified {
  my $self = shift;
  my $class = ref($self);

  my (@userSpecified);
  foreach my $feature ( $class->getFeatureNames() ) {
    if (not $self->by_implication_count($feature)) {
      # must have been set by user
      if (not $self->isSpecified($feature)) {
	warn $self->name .
	  " 's feature $feature never set by user or implicature\n";
      }
      else {
	push @userSpecified, $feature;
      }
    }
  }
  return @userSpecified;
}
##################################################################
sub isEquivalent {
  # returns whether this Eme is feature-equivalent to another Eme
  # passed by argument.
  my $self = shift;
  my $other = shift;

  # self and other better be same class
  my $class = ref($self);
  if (not $class eq ref($other)) {
    croak "can't call $class->isEquivalent( ) with ", ref($other),
      " object; use $class object for argument instead";
  }

 FEATURE:  foreach my $f ( $class->getFeatureNames() ) {
    # if this feature not defined in one or both of the emes in question,
    # skip the feature (they're equivalent)
    if (not defined $self->$f) {
      next FEATURE;
    }
    if (not defined $other->$f) {
      next FEATURE;
    }

    if ($self->$f eq 'unset') {
      warn "Can't test equivalence:\n" .
	"feature '$f' not yet set for symbol'" . $self->name . "'\n";
      next FEATURE;
    }
    elsif ($other->$f eq 'unset') {
      warn "Can't test equivalence:\n" .
	"feature '$f' not yet set for symbol'" . $other->name . "'\n";
      next FEATURE;
    }

    # real comparison is here (above mostly checking for user thinkos)
    if ($self->$f != $other->$f) {
	return 0; # emes are distinct in at least feature $f, not equivalent
    }
  } # end loop over features
  return 1; # couldn't find a distinction between these
} #end sub isEquivalent
##################################################################
sub _knowsFeature {
    my $class = shift;
    my $putativeFeature = shift;
    return ($class->can($putativeFeature));
}
##################################################################
sub hasFeature {
    my $self = shift;
    my $featureName = shift;
    # check feature name
    return ($self->$featureName);
}
##################################################################
sub dumpToText {
  my $self = shift;
  my $features = $self->dumpFeaturesToText( $self->getFeatureNames );
  return $features ;
}
##################################################################
sub _dumpFeature {
  # given a list, puts back into string form:
  my $class = shift;
  my $feature = shift;
  my $value = shift;
  my $symbol;
  if (not defined $value) {
    $symbol = '*';
  }
  else {
    if ($value) {
      if ($value eq 'unset') {
	$symbol = '?'; # uh-oh
      }
      else {
	$symbol = '+';
      }
    }
    else {
      $symbol = '-';
    }
  }
  return $symbol . $feature;
}
##################################################################
sub dumpFeaturesToText {
  my $self = shift;
  my $class = ref($self);
  my @features = @_;
  my @text;
  foreach my $feature (@features) {
    push @text, $class->_dumpFeature($feature, $self->$feature());
  }

  return join ' ', '[', @text, ']';
}
##################################################################
1;
__END__

=head1 NAME

Lingua::FeatureMatrix::Eme - Abstract base class contains one single
eme's features.

=head1 SYNOPSIS

TO DO:

  use Lingua::FeatureMatrix::Eme;
  blah blah blah

=head1 DESCRIPTION

This class is a container for a list of features. A
C<Lingua::FeatureMatrix> object stores a table of these.

=head1 What do I use this class for?

Use this class to build your own subtypes for use with
C<Lingua::FeatureMatrix>.  C<Lingua::FeatureMatrix::Eme> provides the
necessary base class methods to interact with
C<Lingua::FeatureMatrix>.

=head1 Methods exported

The following methods are public (and used by
C<Lingua::FeatureMatrix>):

=head2 Class methods

=over

=item new

The new() method will construct and return an object blessed into the
current class.  In addition, this method will initialize each element
of the feature list (returned from the C<getFeatureList()> method)
with the string "unset".

Arguments passed to C<new()> will be treated as a hash of I<name> =>
I<value> pairs. All keys (see exception below) will be treated as
method names, and the method will be invoked with the corresponding
value (this will ordinarily set the feature named I<key> to I<value>).

I<NOTE>: users will probably rarely invoke this method directly, since
the C<Lingua::FeatureMatrix> code builds these objects as needed while
configuring itself.

Note also that the key C<options> will be explicitly ignored if
present so that subclasses can hang any special initialization values
off that argument. This allows users to pass their special arguments
to their subclasses via the C<eme_opts> named parameter to
C<Lingua::FeatureMatrix->new()>.

=item failsContract

Lists how this class fails its own contract. By extension, indicates
how a subclass fails the contract. Handy for sanity checking.

=back

=head2 Instance methods

=over

=item ->isSpecified

returns whether the feature passed by argument is specified. Will
C<croak> if the feature specified is not supported by the class.

=item ->listUnspecified

Returns which features have never been specified. Note this is *not*
the same as those features that are C<undef>, since that C<undef> is a
value that can legitimately be specified.  See
L<Lingua::FeatureMatrix/Implicatures> for more details.

=item ->isFullySpecified

Returns whether the C<Eme> object in question has had all its features
fully specified.

=item ->isEquivalent

Returns whether the C<Eme> object is equivalent to a (different)
C<Eme> object of the same class handed in.

Rejects C<Eme> objects of different classes, and issues warnings if
any fields needed to make the decision are as yet C<unset> (though
I<undef> fields are acceptable).

=item ->listUserSpecified

Returns that list of C<feature>s that were specified by the user (not by
implication).

=item ->listImplicationSpecified

Returns that list of C<feature>s that were computed by the
implications specified while configuring the C<Lingua::FeatureMatrix>
parent object.

=item ->hasFeature

Returns feature's value. Note that I<ungrammatical> features will
return a false value.

=item ->dumpToText

Dumps textual representation of self's featureset, including the C<[]>
brackets.  Note any features that were not set by user or by
implication will be dumped as C<?>.

=item ->dumpFeaturesToText

Dumps the features passed by argument, and their value, as a text
string.

=item ->explainFeature

Given a featurename, returns a list of the text form of the
implications that were used to set that feature. If the feature does
not exist, returns undefined.

=back

=head1 Subclass requirements

Those who want to build their own subclass should build one to the
following specification.  Note that the C<Phone> and C<Letter>
subclasses provided in the C<examples/> distribution of
C<Lingua::FeatureMatrix> are good places to start.

=over

=item ->getFeatureNames

Any subclass should support a class method C<getFeatureNames> which
should return, in some interesting (and ideally reliable) order, the
list of features that are supported by the subclass.

=item feature methods

Each C<feature> listed by C<getFeatureNames> should:

=over

=item *

be an instance method of the class.

=item *

return the value of that feature when called with no argument (easily
written with C<Class::MethodMaker>).

=item *

set the value of that feature when called with an argument (easily
written with C<Class::MethodMaker>).

=item *

when called with an argument, must accept the following values:

=over

=item 0

=item 1

=item undef

=item "unset"

Ignoring or rejecting other values is acceptable.

=back

=back

=item initialization method

new() should respond as follows:

Either don't provide a new() (let superclass take care of it) or:

=over

=item *

Get your options from the C<options> key/value pair from the argument
list, then:

=item *

call SUPER::init to be sure that the C<Eme> object handles itself properly.

=back

In general, try to follow OO subclassing best practices, or use the
provided C<examples/Phone.pm> and C<examples/Letter.pm> as guides.

It is I<strongly> recommended to use C<Class::MethodMaker> to build
the C<feature> subroutines; in fact, that is all the author has tested
with.

=back

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Lingua::FeatureMatrix::Eme

=item 0.02

=over

=item Now includes the C<failsContract()> class method.

=item Now supports the C<isEquivalent()> instance method.

=back

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>.

L<Lingua::FeatureMatrix>.

=cut
