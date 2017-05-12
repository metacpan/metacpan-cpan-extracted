package Form::Factory::Test::Result;

use Test::Class::Moose::Role;

use Test::More;
use Test::Moose;

has result_class => (
    is        => 'ro',
    isa       => 'ClassName',
    required  => 1,
    lazy      => 1,
    default   => sub { },
);

has result => (
    is        => 'ro',
    required  => 1,
    lazy      => 1,
    default   => sub { shift->result_class->new },
);

sub basic_result_checks : Tests(2) {
    my $self = shift;
    my $result = $self->result;

    does_ok($result, 'Form::Factory::Result');

    can_ok($result, qw(
        is_valid is_validated
        is_success is_outcome_known 
        content messages

        is_failure
        all_messages regular_messages field_messages
        info_messages warning_messages error_messages
        regular_info_messages regular_warning_messages regular_error_messages
        field_info_messages field_warning_messages field_error_messages
    ));
};

1;
