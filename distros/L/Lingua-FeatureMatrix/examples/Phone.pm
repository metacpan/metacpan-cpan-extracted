##################################################################
# example subclass of Lingua::FeatureMatrix::Eme
package Phone;
use strict;
use warnings;
my (@featureList);

use base 'Lingua::FeatureMatrix::Eme';
BEGIN {
  # this is in a BEGIN block so that the use Class::MethodMaker in
  # Phone can install booleans appropriately.
  @featureList = (
		  qw( vow cons voice son ), # general
		  qw( fric stop liq nas ), # cons features, usually
		  qw( lab dent vel alv pal ), # position
		  qw( high low front back tense ), # vow features, usually
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

Phone -- an example 'Eme' class. See Lingua::FeatureMatrix.

=head1 DESCRIPTION

Distributed with C<Lingua::FeatureMatrix> as a sample class derived
from C<Lingua::FeatureMatrix::Eme>.

(It's a C<Phone> C<Eme>, get it?)

=head1 Altering for your own use

The most likely change you will probably want to make is to alter the
featureset supported by this file. To do so at minimal edit distance,
change the file-scoped array C<@featureList>. Make sure it is still
inside the C<BEGIN> block so that the C<Class::MethodMaker> calls will
still pick up the right values.

=head1 See Also

L<Lingua::FeatureMatrix>, which can be used to create tables of
feature behavior.

L<Lingua::FeatureMatrix::Eme>, of which this is a subclass.

L<Graph>. (a different C<Lingua::FeatureMatrix::Eme> subclass).

=head1 Author

This file began life as an example file by Jeremy Kahn C<kahn@cpan.org>.

=head1 HISTORY

This began life as a sample class distributed with
C<Lingua::FeatureMatrix>, distributed under the same terms as Perl
itself.

=head1 Copyright

You are free to copy this class and do absolutely anything with it. It
would be nice if you credited the original author, but it's not
required.

What you have made of it since then is not the responsibility of the
Management.

Note that its parent class (C<Lingua::FeatureMatrix::Eme>) is licensed
under the same terms as Perl itself.

=cut
