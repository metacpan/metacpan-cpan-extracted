package Test::MPMinus; # $Id: MPMinus.pm 2 2013-08-07 09:50:14Z minus $
use strict;
use vars qw/$VERSION/;
$VERSION = 1.00;

use Encode; # For CTK bug fix
use File::Spec::Functions;
use File::Temp qw/ tempdir /;

my $dir = tempdir( CLEANUP => 1 );

my %cfg = (
        default => undef,
        document_root => $dir,
        dir_db        => 'db',
        auth => {
                file => catfile($dir,'foo'.$$), # ':memory:',
            },
    );

sub new {
  my $class = shift;
  return bless {}, $class;
}
sub t {
  my $self = shift;
  return "Ok"
}

sub conf {
    my $self = shift;
    return $cfg{shift || 'default'};
}

1;