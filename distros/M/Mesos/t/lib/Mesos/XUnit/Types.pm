package Mesos::XUnit::Types;
use Mesos::Types qw(FrameworkInfo);
use Type::Params qw(validate);
use Test::Class::Moose;

sub test_coercions {
    my ($test) = @_;

    my $framework_constructor = {
        user => "test-user",
        name => "test-name",
    };
    my ($coerced_framework) = validate([$framework_constructor], FrameworkInfo);
    isa_ok $coerced_framework, 'Mesos::FrameworkInfo', 'coerced FrameworkInfo';
}

1;
