package Gapp::Moose::Meta::Attribute::Trait::GappToolItemGroup;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappToolItemGroup::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::ToolItemGroup' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappToolItemGroup;
{
  $Moose::Meta::Attribute::Custom::Trait::GappToolItemGroup::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappToolItemGroup' };
1;
