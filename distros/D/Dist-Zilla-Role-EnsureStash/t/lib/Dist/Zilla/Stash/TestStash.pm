#
# This file is part of Dist-Zilla-Role-EnsureStash
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Stash::TestStash;

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::Stash';

__PACKAGE__->meta->make_immutable;
!!42;
__END__
