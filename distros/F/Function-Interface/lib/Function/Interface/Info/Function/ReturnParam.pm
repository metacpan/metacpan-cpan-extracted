package Function::Interface::Info::Function::ReturnParam;

use v5.14.0;
use warnings;

our $VERSION = "0.05";

sub new {
    my ($class, %args) = @_;
    bless \%args => $class;
}

sub type() { $_[0]->{type} }
sub type_display_name() { $_[0]->type->display_name }

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface::Info::Function::ReturnParam - information about return values of abstract function

=head1 METHODS

=head2 new

Constructor of Function::Interface::Info::Function::ReturnParam. This is usually called at Function::Interface::info.

=head2 type -> Object

Returns type object of the return value, e.g. C<Str>.

=head3 type_display_name -> Str

Returns type display name of the return value

=head1 SEE ALSO

L<Function::Interface::Info>

