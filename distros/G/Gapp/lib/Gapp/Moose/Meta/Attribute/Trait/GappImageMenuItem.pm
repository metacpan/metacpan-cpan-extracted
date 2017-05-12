package Gapp::Moose::Meta::Attribute::Trait::ImageMenuItem;
{
  $Gapp::Moose::Meta::Attribute::Trait::ImageMenuItem::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::ImageMenuItem' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappImageMenuItem;
{
  $Moose::Meta::Attribute::Custom::Trait::GappImageMenuItem::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappImageMenuItem' };
1;
