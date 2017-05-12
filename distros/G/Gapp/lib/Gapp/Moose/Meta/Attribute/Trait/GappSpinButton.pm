package Gapp::Moose::Meta::Attribute::Trait::GappSpinButton;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappSpinButton::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::SpinButton' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappSpinButton;
{
  $Moose::Meta::Attribute::Custom::Trait::GappSpinButton::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappSpinButton' };
1;
