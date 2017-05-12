package Gapp::Moose::Meta::Attribute::Trait::GappComboBox;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappComboBox::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::ComboBox' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappComboBox;
{
  $Moose::Meta::Attribute::Custom::Trait::GappComboBox::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappComboBox' };
1;
