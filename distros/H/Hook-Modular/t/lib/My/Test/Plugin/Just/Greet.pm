package My::Test::Plugin::Just::Greet;
use warnings;
use strict;
use parent 'Hook::Modular::Plugin';

sub register {
    my ($self, $context) = @_;
    $context->register_hook($self, 'init.greet' => $self->can('do_greet'),);
}

sub do_greet {
    my ($self, $context, $args) = @_;
    $args->{result}{text} ||= '';
    $args->{result}{text} .= sprintf "%s says hello\n", ref $self;
}
1;
