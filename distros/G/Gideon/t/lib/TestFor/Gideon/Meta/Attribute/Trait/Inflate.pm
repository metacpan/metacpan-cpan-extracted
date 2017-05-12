package TestFor::Gideon::Meta::Attribute::Trait::Inflate;
use Test::Class::Moose;
use MooseX::Test::Role;

with 'Test::Class::Moose::Role::AutoUse';

sub test_inflate {
    my $meta = Moose::Meta::Class->create_anon_class;

    $meta->add_attribute(
        test => (
            is       => 'rw',
            traits   => ['Gideon::Inflate'],
            inflator => sub { 'inflated' },
            deflator => sub { 'deflated' }
        )
    );

    my ($inflator) =
      map { $_->get_inflator } $meta->get_attribute('test');

    my ($deflator) =
      map { $_->get_deflator } $meta->get_attribute('test');

    is $inflator->(), 'inflated', 'Inflator Result';
    is $deflator->(), 'deflated', 'Deflator Result';
}

1;
