package Gapp::Moose::Meta::Attribute::Trait::GappToolPalette;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappToolPalette::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::ToolPalette' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappToolPalette;
{
  $Moose::Meta::Attribute::Custom::Trait::GappToolPalette::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappToolPalette' };
1;
