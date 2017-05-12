package Lingua::FeatureMatrix::Implicature;

use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '0.01';

use Class::MethodMaker
  new_with_init => 'new',

  # use get_set so we can initialize to undef without warning
  get_set => [ qw [ implier implicant ] ];

#  hash => [ qw [ implier implicant ] ];
use Lingua::FeatureMatrix::Eme;
##################################################################
sub init {
  my $self = shift;
  my %implier = %{shift @_};
  my %implicant = %{shift @_};

  {
    # these two calls *should* allow undef to be a value...
    $self->implier(\%implier);
    $self->implicant(\%implicant);
  }

#   foreach my $key ($self->implier_keys) {
#     if (not defined $self->implier($key)) {
#       warn "shouldn't specify * for features in implier\n"

}
##################################################################
sub matches {
  my $self = shift;
  my Lingua::FeatureMatrix::Eme $eme = shift;
  # returns whether the eme passed in by argument matches the implier

 FEATURE:
  foreach my $feature ( keys %{$self->implier()} ) {
    if (not $eme->can($feature)) {
      warn ref($eme) . " doesn't know about feature $feature\n";
      next FEATURE;
    }
    if (not defined $self->implier()->{$feature}) {
      if (not defined $eme->$feature) {
	next FEATURE; # we're okay -- both underspecified
      }
      else {
	return 0; # implier requires "unspecified", eme has specified
                  # it
      }
    }
    if (defined $self->implier()->{$feature} and not defined $eme->$feature) {
      return 0; # implier requires, eme has explicitly unspecified
    }
    if ($eme->$feature eq 'unset') {
      return 0; # doesn't match if not yet set. Is this the right
                # behavior?
    }
    if ($self->implier()->{$feature} != $eme->$feature) {
      # both defined, but different signs
      return 0;
    }
  }
  return 1;
}
##################################################################
sub dependsOn {
  # check to see if $other's implicant shares any features with
  # $self's implier. e.g.

  #   other [ +high ] => [ +vow ]
  #   self [ +vow ] => [ +voice ]

  # since [vow] is in other's implicant, and in self's implier, self
  # *does* depend on other

  my $self = shift;
  my Lingua::FeatureMatrix::Implicature $other = shift;

  my @dependencies;
  foreach my $feature( keys %{$self->implier} ) {
    if (defined $other->implicant->{$feature}) {
      my $action;
      if ($other->implicant->{$feature} == $self->implier->{$feature}) {
	$action = 'feeds';
      }
      else {
	$action = 'bleeds';
      }
      # should this test "exists"?
      push @dependencies, "$action ($feature)";
    }
  }
  return @dependencies;
}
##################################################################
sub dumpToText {
  my $self = shift;

  my (@implier, @implicant);
  foreach (sort keys %{$self->implier()}) {
    push @implier,
      Lingua::FeatureMatrix::Eme->_dumpFeature($_,
					       $self->implier->{$_});
  }
  foreach (sort keys %{$self->implicant()}) {
    push @implicant,
      Lingua::FeatureMatrix::Eme->_dumpFeature($_,
					       $self->implicant->{$_});
  }
  return join (' ', '[', @implier, ']', '=>', '[', @implicant, ']');
}
##################################################################
sub apply {
  my $self = shift;
  my Lingua::FeatureMatrix::Eme $eme = shift;
  # modifies the eme passed in according to the implicant
  foreach my $feature( keys %{$self->implicant} ) {
    # issues warnings if implicated field already populated?
    my $val = $self->implicant->{$feature};

    my $isProblem;
    if (defined $eme->$feature() and $eme->$feature eq 'unset') {
    }
    elsif (not defined $eme->$feature()) {
      if (defined $val) {
	$isProblem = 1;
      }
      else {
	$isProblem = 0;
      }
    }
    else {
      # defined $eme->$feature()
      if (not defined $val) {
	$isProblem = 1;
      }
      else {
	# both defined
	$isProblem = ($eme->$feature != $val);
      }
    }
    if ($isProblem) {
      croak "implicature ", $self->dumpToText,
	" wanted to assign new value '",
	  (defined $val ? $val : 'undef'),
	    "' to $feature but eme '",
	      $eme->name(),
		"' already had value '",
		  (defined $eme->$feature ? $eme->$feature : 'undef'),
		    "' at $feature!\n";
    }
    elsif (defined $isProblem) {
#       my $implier = $eme->by_implication($feature);
      if (not $eme->by_implication_count($feature)) {
	warn (join '', "Implicature '", $self->dumpToText,
	      "' and eme '", $eme->name(), "' definition are ",
	      "mutually redundant with respect to the '$feature' feature\n");
      }
    }

    $eme->$feature($val);

    $eme->by_implication_push($feature => $self);
  }
}
##################################################################
sub sortByRuleOrder {
  my $class = shift;
  my @implicatures = @_;


  foreach my $implicature (@implicatures) {

    # look for match from current implicant to another rule's implier.
    foreach my $otherImplicature (@implicatures) {
      # skip self!
      next if ($implicature == $otherImplicature);

      # if current implicant matches other implicature's implier,
      # current implicature must come first.

      # JGK: we should draw a directed arc between current and other;
      # then do a topological sort.
    }
  }
  my @sorted;



#  ...
  return @sorted;
}

1;
__END__


=head1 NAME

Lingua::FeatureMatrix::Implicature - Owns a single implicature within
a Lingua::FeatureMatrix.

=head1 DESCRIPTION

Handles a single implicature from a set of known features to provide
new information for other features.

=head1 Methods

=head2 Class Methods

=over

=item new

=back

=head2 Instance Methods

=over

=item dependsOn

takes another C<Lingua::FeatureMatrix::Implicature> as an
argument. Returns whether the implicant (output) of the I<other>
implicature could affect the implier (input) of this one.

Used for rule-ordering.

=item matches

Takes a C<Lingua::FeatureMatrix::Eme> as an argument. Returns whether
this implicature would apply to this eme (whether it matches the implier).

=item apply

Takes a C<Lingua::FeatureMatrix::Eme> as an argument. Sets its
features according to the implicature's implicant.

=back

=head1 See Also

L<Lingua::FeatureMatrix>.

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Lingua::FeatureMatrix::Implicature

=back


=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>.

L<Lingua::FeatureMatrix>.

L<Lingua::FeatureMatrix::Eme>.

=cut
