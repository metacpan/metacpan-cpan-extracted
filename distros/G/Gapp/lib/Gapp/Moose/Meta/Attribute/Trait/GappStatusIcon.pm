package Gapp::Moose::Meta::Attribute::Trait::GappStatusIcon;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappStatusIcon::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::StatusIcon' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappStatusIcon;
{
  $Moose::Meta::Attribute::Custom::Trait::GappStatusIcon::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappStatusIcon' };
1;
