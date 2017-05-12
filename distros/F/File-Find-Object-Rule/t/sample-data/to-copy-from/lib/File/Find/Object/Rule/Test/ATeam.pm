package File::Find::Object::Rule::Test::ATeam;
use strict;
use File::Find::Object::Rule;
use base 'File::Find::Object::Rule';

sub File::Find::Object::Rule::ba {
    my $self = shift()->_force_object;
    $self->exec( sub { die "I pity the fool who uses this in production" });
}

1;
