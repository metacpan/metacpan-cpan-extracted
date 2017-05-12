package Gapp::Moose::Meta::Attribute::Trait::SeparatorMenuItem;
{
  $Gapp::Moose::Meta::Attribute::Trait::SeparatorMenuItem::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::SeparatorMenuItem' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappSeparatorMenuItem;
{
  $Moose::Meta::Attribute::Custom::Trait::GappSeparatorMenuItem::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappSeparatorMenuItem' };
1;
