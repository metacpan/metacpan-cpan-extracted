package Gapp::Moose::Meta::Attribute::Trait::GappRadioToolButton;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappRadioToolButton::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::RadioToolButton' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappRadioToolButton;
{
  $Moose::Meta::Attribute::Custom::Trait::GappRadioToolButton::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappRadioToolButton' };
1;
