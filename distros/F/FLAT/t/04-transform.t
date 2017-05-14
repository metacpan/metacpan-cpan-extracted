use Test::More 'no_plan';

use strict;

use FLAT;

is (1,1);

SKIP: 
{ eval{ require Math::Symbolic::Transform }
  # will contain tests for FLAT::Regex::Transform if
  # Math::Symbolic::Transform is installed, if not
  # no worries - we don't want Math::Symbolic::Transform
  # to become a pre-requisite for FLAT in general. 
  # -- Begin tests below -- #
}

__END__
