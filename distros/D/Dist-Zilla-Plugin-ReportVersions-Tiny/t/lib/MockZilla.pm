use strict;
use warnings;

package  # no-index
    MockZilla;

use Test::MockObject;

# FILENAME: MockZilla.pm
# CREATED: 18/03/12 02:39:10 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Mock Dist::Zilla
#
# Code extraced from 'exclude.t' and refactored to be self-contained.

my ($prereqs, $dzil, $log);

sub set_prereqs {
    my ( $self, $pr ) = @_;
    $prereqs = $pr;
    return $self;
}

sub dzil {
    #my ($self) = @_;
    return $dzil;
}

sub logger {
    #my ($self) = @_;
    return $log;
}

sub import {
    $dzil or _setup();
    return 1;
}

sub _setup {
    my $pr = Test::MockObject->new();
    $pr->set_bound( as_string_hash => \$prereqs );

    $log = Test::MockObject->new;
    $log->set_always( log => $1 ); # FIXME What is this $1 ?

    my $logger = Test::MockObject->new;
    $logger->set_always( proxy => $log );

    my $chrome = Test::MockObject->new;
    $chrome->set_always( logger => $logger );

    $dzil = Test::MockObject->new;
    $dzil->fake_module('Dist::Zilla');
    $dzil->set_isa('Dist::Zilla');
    $dzil->set_always( prereqs => $pr );
    $dzil->set_always( chrome  => $chrome );
}

1;

