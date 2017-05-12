package Gapp::Moose::Meta::Attribute::Trait::GappActionGroup;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappActionGroup::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::ActionGroup' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappActionGroup;
{
  $Moose::Meta::Attribute::Custom::Trait::GappActionGroup::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappActionGroup' };
1;
