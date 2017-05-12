package Gapp::Moose::Meta::Attribute::Trait::GappViewport;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappViewport::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Viewport' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappViewport;
{
  $Moose::Meta::Attribute::Custom::Trait::GappViewport::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappViewport' };
1;
