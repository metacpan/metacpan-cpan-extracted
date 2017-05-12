package My::Test::Plugin::Some::Printer;
use warnings;
use strict;
use parent 'Hook::Modular::Plugin';

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'init.greet'   => $self->can('do_greet'),
        'output.print' => $self->can('do_print'),
    );
}

# Dispatch the rule on any hook, not just the first registered one. This
# prevents any of the plugin's hooks to run.
sub dispatch_rule_on { 1 }

sub indent {
    my $self = shift;
    $self->conf->{indent} || 0;
}

sub indent_char {
    my $self = shift;
    $self->conf->{indent_char} || '';
}

sub text {
    my $self = shift;
    $self->conf->{text} || '';
}

sub do_print {
    my ($self, $context, $args) = @_;
    $args->{result}{text} ||= '';
    $args->{result}{text} .= sprintf "%s%s\n",
      ($self->indent_char x $self->indent), $self->text;
}

sub do_greet {
    my ($self, $context, $args) = @_;
    $args->{result}{text} ||= '';
    $args->{result}{text} .= sprintf "%s says hello\n", ref $self;
}
1;
