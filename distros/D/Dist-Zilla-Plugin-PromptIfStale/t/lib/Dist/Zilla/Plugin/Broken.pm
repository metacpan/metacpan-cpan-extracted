package BrokenPlugin;
use Moose;
with 'Dist::Zilla::Role::Plugin';

sub register_component { die 'oh noes!' }
1;
