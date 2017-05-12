package TestPrompter;
use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

sub before_build
{
    my $self = shift;
    my $continue = $self->zilla->chrome->prompt_yn('hello, are you there?', { default => 0 });
}

1;
