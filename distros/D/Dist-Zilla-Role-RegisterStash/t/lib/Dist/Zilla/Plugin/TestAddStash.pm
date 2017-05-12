#
# This file is part of Dist-Zilla-Role-RegisterStash
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Plugin::TestAddStash;

use Moose;
use namespace::autoclean;

use aliased 'Dist::Zilla::Stash::TestStash';

with
    'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::RegisterStash',
    ;

use Test::More;

sub before_release {
    my $self = shift @_;

    # add stash
    pass 'in before_release()';
    $self->_register_stash(
        '%TestStash' => TestStash->new(),
    );
    return;
}


__PACKAGE__->meta->make_immutable;
!!42;
__END__
