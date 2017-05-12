package Gapp::Moose::Meta::Attribute::Trait::CheckMenuItem;
{
  $Gapp::Moose::Meta::Attribute::Trait::CheckMenuItem::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::CheckMenuItem' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::CheckMenuItem;
{
  $Moose::Meta::Attribute::Custom::Trait::CheckMenuItem::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappCheckMenuItem' };
1;
