# Test the _max_version_from_tags function of Git::NextVersion
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88 tests => 10; # done_testing

use Dist::Zilla::Plugin::Git::NextVersion ();

#---------------------------------------------------------------------
sub t
{
  my $name = "@_";
  my $regexp = shift;
  my $expect = shift;

  undef $expect if $expect eq 'undef';

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  # This prevents RT#81061 from recurring (thanks, Matthew Horsfall):
  local $1;    # ensure version.pm exhibits its buggy behavior with $1

  is(Dist::Zilla::Plugin::Git::NextVersion::_max_version(
       Dist::Zilla::Plugin::Git::NextVersion::_versions_from_tags(
         $regexp, \@_
     )), $expect, $name);
} # end t

#---------------------------------------------------------------------
t qw{(.+) 1.00  0.1 0.23 0.99 1.00 0.975 };
t qw{v(.+) 1.00  v0.1 v0.23 v0.99 v1.00 v0.975 };
t qw{v(.+) 1.00  invalid versions ok v1.00 v0.1 validate };
t qw{v(.+) undef };
t qw{v(.+) undef  validate version verification };
t qw{v(.+) 2.010  validate version v2.010 verification v1.1234 };

# Don't use a regexp that extracts -TRIAL, but it shouldn't crash if you do:
t qw{v(.+)      1.00  v1.00 v1.02-TRIAL v0.99 };
t qw{v([\d._]+) 1.02  v1.00 v1.02-TRIAL v0.99 }; # better regexp

# Try versions with underscore:
t qw{(.+) 1.00_01  0.1 0.23 0.99 1.00 0.975 1.00001 1.00_01 0.900_01 };
t qw{v(.+) 1.00_01  v0.1 v0.23 v1.00 v1.00001 v1.00_01 v0.900_01 };

done_testing;
