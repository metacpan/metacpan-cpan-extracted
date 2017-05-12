package Gapp::Moose::Meta::Attribute::Trait::RadioMenuItem;
{
  $Gapp::Moose::Meta::Attribute::Trait::RadioMenuItem::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::RadioMenuItem' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::RadioMenuItem;
{
  $Moose::Meta::Attribute::Custom::Trait::RadioMenuItem::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappRadioMenuItem' };
1;
