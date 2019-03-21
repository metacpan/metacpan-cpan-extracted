package Function::Interface::Info::Function::Param;

use v5.14.0;
use warnings;

our $VERSION = "0.05";

sub new {
    my ($class, %args) = @_;
    bless \%args => $class;
}

sub type() { $_[0]->{type} }
sub name() { $_[0]->{name} }
sub optional() { !!$_[0]->{optional} }
sub named() { !!$_[0]->{named} }

sub type_display_name() { $_[0]->type->display_name }

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface::Info::Function::Param - information about parameters of abstract function

=head1 METHODS

=head2 new

Constructor of Function::Interface::Info::Function::Param. This is usually called at Function::Interface::info.

=head2 name -> Str

Returns parameter name of the abstract function, e.g. C<$msg>.

=head2 named -> Bool

Returns whether it is a named parameter.
For example, C<Str $a> is false, C<Str :$b> is true.

=head2 optional -> Bool

Returns whether it is a optional parameter.
For example, C<Str $a> is false, C<Str $b=> is true.

=head2 type -> Object

Returns type object of the parameter, e.g. C<Str>.

=head3 type_display_name -> Str

Returns type display name of the parameter 

=head1 SEE ALSO

L<Function::Interface::Info>

