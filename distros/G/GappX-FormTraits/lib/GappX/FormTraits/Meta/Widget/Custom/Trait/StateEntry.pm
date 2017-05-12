package GappX::FormTraits::Meta::Widget::Custom::Trait::StateEntry;
{
  $GappX::FormTraits::Meta::Widget::Custom::Trait::StateEntry::VERSION = '0.300';
}

use Moose::Role;

around BUILDARGS => sub {
    my ( $orig, $class, %opts ) = @_;
    $opts{properties}{width_chars} ||= '2';
    return $class->$orig( %opts );
};


package Gapp::Meta::Widget::Custom::Trait::StateEntry;
{
  $Gapp::Meta::Widget::Custom::Trait::StateEntry::VERSION = '0.300';
}
sub register_implementation { 'GappX::FormTraits::Meta::Widget::Custom::Trait::StateEntry' };


1;