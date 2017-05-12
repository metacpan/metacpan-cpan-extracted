package File::Find::Rule::Test::ATeam;
use strict;
use File::Find::Rule;
use base 'File::Find::Rule';

sub File::Find::Rule::ba {
    my $self = shift()->_force_object;
    $self->exec( sub { die "I pity the fool who uses this in production" });
}

1;
