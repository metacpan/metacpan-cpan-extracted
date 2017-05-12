package GappX::FormTraits::Meta::Widget::Custom::Trait::CityEntry;
{
  $GappX::FormTraits::Meta::Widget::Custom::Trait::CityEntry::VERSION = '0.300';
}

use Moose::Role;

around BUILDARGS => sub {
    my ( $orig, $class, %opts ) = @_;
    $opts{properties}{width_chars} ||= '25';
    return $class->$orig( %opts );
};


package Gapp::Meta::Widget::Custom::Trait::CityEntry;
{
  $Gapp::Meta::Widget::Custom::Trait::CityEntry::VERSION = '0.300';
}
sub register_implementation { 'GappX::FormTraits::Meta::Widget::Custom::Trait::CityEntry' };


1;