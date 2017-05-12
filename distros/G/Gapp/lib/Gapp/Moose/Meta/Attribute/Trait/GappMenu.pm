package Gapp::Moose::Meta::Attribute::Trait::GappMenu;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappMenu::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Menu' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappMenu;
{
  $Moose::Meta::Attribute::Custom::Trait::GappMenu::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappMenu' };
1;
