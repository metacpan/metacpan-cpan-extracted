=head1 GOBO::DBIC::GODBModel::Extension


=cut

package GOBO::DBIC::GODBModel::Extension;

use base 'DBIx::Class';
use utf8;
use strict;


# sub new {
#   my ( $class, $attrs ) = @_;

#   my $new = $class->next::method($attrs);

#   print $new . "\n";
#   sleep 2;

#   return $new;
# }


##
sub score {

  my $self  = shift;
  my $score = shift || undef;

  if( defined($score) ){
    $self->{EXTENSION_SCORE} = $score;
  }

  my $retval = 0;
  if( defined( $self->{EXTENSION_SCORE} ) ){
    $retval = $self->{EXTENSION_SCORE};
  }

  return $retval;
  #return 0;
}


1;
