package GappX::FormTraits::Meta::Widget::Custom::Trait::EmailEntry;
{
  $GappX::FormTraits::Meta::Widget::Custom::Trait::EmailEntry::VERSION = '0.300';
}

use Moose::Role;

around BUILDARGS => sub {
    my ( $orig, $class, %opts ) = @_;
    $opts{properties}{width_chars} ||= '60';
    return $class->$orig( %opts );
};


package Gapp::Meta::Widget::Custom::Trait::EmailEntry;
{
  $Gapp::Meta::Widget::Custom::Trait::EmailEntry::VERSION = '0.300';
}
sub register_implementation { 'GappX::FormTraits::Meta::Widget::Custom::Trait::EmailEntry' };


1;