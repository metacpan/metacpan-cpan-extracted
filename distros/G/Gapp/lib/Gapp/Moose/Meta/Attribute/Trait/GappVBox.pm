package Gapp::Moose::Meta::Attribute::Trait::GappVBox;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappVBox::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::VBox' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappVBox;
{
  $Moose::Meta::Attribute::Custom::Trait::GappVBox::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappVBox' };
1;
