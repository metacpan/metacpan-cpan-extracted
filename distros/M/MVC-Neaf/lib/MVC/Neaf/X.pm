package MVC::Neaf::X;

use strict;
use warnings;
our $VERSION = 0.1901;

=head1 NAME

MVC::Neaf::X - base class for Not Even A Framework extentions.

=head1 SYNOPSIS

    package MVC::Neaf::X::My::Module;
    use parent qw(MVC::Neaf::X);

    sub foo {
        my $self = shift;

        $self->my_croak("unimplemented"); # will die with package & foo prepended
    };

    1;

=head1 DESCRIPTION

Start out a Neaf extention by subclassing this class.

Some convenience methods here to help develop.

=head1 METHODS

=cut

use Carp;

=head2 new( %options )

Will happily accept any args and pack them into self.

=cut

sub new {
    my ($class, %opt) = @_;

    return bless \%opt, $class;
};

=head2 my_croak( $message )

Like croak() from Carp, but the message is prefixed
with self's package and the name of method
in which error occurred.

=cut

sub my_croak {
    my ($self, $msg) = @_;

    my $sub = [caller(1)]->[3];
    $sub =~ s/.*:://;

    croak join "", (ref $self || $self),"->",$sub,": ",$msg;
};

1;
