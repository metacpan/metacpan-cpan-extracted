package inc::Foo;
use Moose;
with 'Dist::Zilla::Role::BeforeBuild';
sub before_build { 1 }
1;
