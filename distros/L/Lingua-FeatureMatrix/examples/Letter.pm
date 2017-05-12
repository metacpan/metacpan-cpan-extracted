##################################################################
# example subclass of Lingua::FeatureMatrix::Eme
package Letter;
use strict;
use warnings;
my (@featureList);

use base 'Lingua::FeatureMatrix::Eme';
BEGIN {
  # this is in a BEGIN block so that the use Class::MethodMaker in
  # Phone can install booleans appropriately.
  @featureList = (
		  qw( riser faller ), # general
		  qw( vow cons ),
		  qw( capital ),
		  qw ( em en ell ), # widths
		  );
}
##################################################################
use Class::MethodMaker
    get_set => [ @featureList ];
##################################################################
sub getFeatureNames {
  return @featureList;
}
##################################################################
1;

=head1 NAME

Letter -- contains features to describe a single letter

=head1 SYNOPSIS

  use Letter; # a sample derived class from Lingua::FeatureMatrix
  my $matrix = Lingua::FeatureMatrix->new(file => 'lettermatrix.dat',
                                          eme => 'Letter');

  $matrix->matchesFeatureClass('d', 'RISER'); # true
  $matrix->matchesFeatureClass('l', 'FULLWIDTH'); # false

=head1 DESCRIPTION

=head1 HISTORY

Long and tortured.

=back

=cut
