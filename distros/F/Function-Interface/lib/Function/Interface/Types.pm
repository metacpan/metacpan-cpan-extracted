package Function::Interface::Types;

use v5.14.0;
use warnings;

our $VERSION = "0.06";

use Type::Library -base,
    -declare => qw( ImplOf );

use Types::Standard -types;
use Class::Load qw(is_class_loaded);
use Scalar::Util qw(blessed);

__PACKAGE__->add_type({
    name   => 'ImplOf',
    parent => ClassName | Object,
    constraint_generator => sub {
        my $self = $Type::Tiny::parameterize_type;
        my @interfaces = @_;

        my $display_name = $self->name_generator->($self, @interfaces);

        my %options = (
            constraint   => sub {
                my ($package) = @_;
                for (@interfaces) {
                    return unless Function::Interface::Impl::impl_of($package, $_);
                }
                return !!1;
            },
            display_name => $display_name,
            parameters   => [@interfaces],
            message => sub {
                my $package = ref $_ ? blessed($_) : $_;
                return "$package is not loaded" if !is_class_loaded($package); 
                return sprintf '%s did not pass type constraint "%s"', Type::Tiny::_dd($_), $display_name;
            },
        );

        return $self->create_child_type(%options);
    },
});

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

Function::Interface::Types - interface types for Type::Tiny

=head1 SYNOPSIS

    use Function::Interface::Types -types;
    my $type = ImplOf['IFoo'];

    my $foo = Foo->new; # implements of 'IFoo'
    $type->check($foo); # ok

=head1 DESCRIPTION

Function::Interface::Types provides type constraints of interface package.
The following types are available.

=head2 ImplOf[`a]

C<ImplOf['IFoo', 'IBar']> allows objects or packages where implements of interface package 'IFoo' and 'IBar' both return true.

Given no parameters, just equivalent to Object or ClassName.

=head1 SEE ALSO

L<Function::Interface>
