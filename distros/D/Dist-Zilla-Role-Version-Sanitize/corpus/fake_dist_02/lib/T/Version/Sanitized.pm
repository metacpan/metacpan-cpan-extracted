use strict;
use warnings;
use utf8;

package T::Version::Sanitized;

# ABSTRACT: Provide a number and get a vstring back

use Moose;
with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::VersionProvider';
with 'Dist::Zilla::Role::Version::Sanitize';

sub provide_version {
  return '1.200300';
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

