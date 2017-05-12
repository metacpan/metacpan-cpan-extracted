package TestApp::Action::Composed;

use Form::Factory::Processor;

with qw(
    TestApp::Action::Role::PartOne
    TestApp::Action::Role::PartTwo
);

sub run {
    my $self = shift;

    $self->result->content->{something} 
        = join ',', $self->part_one, $self->part_two;
    $self->success('yay!');
}

1;
