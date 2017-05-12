use strict;
use warnings;
use utf8;

package T::Version::Sanitized;

# ABSTRACT: Provide a vstring and get a number back

use Moose;
with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::VersionProvider';
with 'Dist::Zilla::Role::Version::Sanitize';

sub provide_version {
  return '1.2.3';
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

