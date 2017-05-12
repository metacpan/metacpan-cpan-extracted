package DustyDB::Meta::Instance;
our $VERSION = '0.06';

use Moose::Role;

use Scalar::Util qw( reftype );

=head1 NAME

DustyDB::Meta::Instance - helper for auto-vivifying model links on demand

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Do not use this class directly. Just by using L<DustyDB::Object>, you have done everything you need to work with this class.

=head1 METHODS

=head2 get_slot_value

This method has been enhanced to perform deferred loading of FK objects.

=cut

override get_slot_value => sub {
    my ($instance, $struct, $name) = @_;
    my $value = super($struct, $name);

    if (blessed $value and blessed($value)->isa('DustyDB::FakeRecord')) {
        $value = $value->vivify;
        $instance->set_slot_value($struct, $name, $value);
    }

    return $value;
};

=head2 inline_get_slot_value

This method has been enhanced to performed deferred loading of FK object in inline accessor code.

=cut

override inline_get_slot_value => sub {
    my ($instance, $struct, $name) = @_;
    my $super = super($struct, $name);

    return q#do {
        my $value = # . $super . q#;

        if (Scalar::Util::blessed($value) and Scalar::Util::blessed($value)->isa('DustyDB::FakeRecord')) {
            $value = $value->vivify;
        }

        $value;
    }#;
};

1;