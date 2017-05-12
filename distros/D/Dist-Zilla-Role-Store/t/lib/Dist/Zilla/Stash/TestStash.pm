#
# This file is part of Dist-Zilla-Role-Store
#
# This software is Copyright (c) 2014 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Stash::TestStash;

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

with 'Dist::Zilla::Role::Store';

__PACKAGE__->meta->make_immutable;
!!42;
__END__
