package Gapp::Moose::Meta::Attribute::Trait::GappScrolledWindow;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappScrolledWindow::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::ScrolledWindow' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappScrolledWindow;
{
  $Moose::Meta::Attribute::Custom::Trait::GappScrolledWindow::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappScrolledWindow' };
1;
