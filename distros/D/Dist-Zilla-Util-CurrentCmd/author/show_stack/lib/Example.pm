use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Example;

# ABSTRACT: An Example plugin that uses the util for debugging

# AUTHORITY

use Moose;
use Dist::Zilla::Util::CurrentCmd qw(current_cmd is_build is_install);

with 'Dist::Zilla::Role::PrereqSource';

sub register_prereqs {
  my $i = 0;
  printf "Target is %s\n", current_cmd();
  return {};
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

