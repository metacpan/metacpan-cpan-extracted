package Lingua::FeatureMatrix::FeatureClass;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.01';
use Carp;
##################################################################
use Class::MethodMaker
  new_with_init => 'new',
  get_set => 'name',
  hash => 'features';
##################################################################
sub init {
  my $self = shift;
  my %args = @_;

  $self->name( $args{name} );
  if (not defined $self->name()) {
    croak "Could not initialize ", ref($self), ":",
      " missing 'name' parameter";
  }

  if (not defined $args{features}) {
    croak "can't initialize ", ref($self), ":",
      " missing 'features' parameter!";
  }
  if (ref($args{features} ne 'HASH') ) {
    croak "'features' parameter value not a hashref";
  }
  $self->features(%{$args{features}});
}
##################################################################
sub matches {
    my $self = shift;
    my $eme = shift;

    foreach my $feature ($self->features_keys) {
      if (not $eme->isSpecified($feature)) {
	warn "feature $feature not specified for " . $eme->name;
	return 0;
      }
      if (not defined $eme->$feature) {
	return 0; # underspecified -- must be okay
      }
      if ($eme->$feature ne $self->features($feature)) {
	return 0;
      }
    }
    return 1;
}
##################################################################
sub dumpToText {
    my $self = shift;
    my $fh = shift;
}
sub dumpToC {
    my $self = shift;
    my $fh = shift;
}
sub dumpToBinary {
    my $self = shift;
    my $fh = shift;
}
##################################################################
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Lingua::FeatureMatrix::FeatureClass - A piece of
Lingua::FeatureMatrix.

=head1 DESCRIPTION

This class represents a composite featureset.

See L<Lingua::FeatureMatrix>.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Lingua::FeatureMatrix::FeatureClass

=back


=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>.

L<Lingua::FeatureMatrix>.

L<Lingua::FeatureMatrix::Eme>.

=cut
