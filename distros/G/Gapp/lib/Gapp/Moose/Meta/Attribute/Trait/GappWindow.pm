package Gapp::Moose::Meta::Attribute::Trait::GappWindow;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappWindow::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Window' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappWindow;
{
  $Moose::Meta::Attribute::Custom::Trait::GappWindow::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappWindow' };
1;
