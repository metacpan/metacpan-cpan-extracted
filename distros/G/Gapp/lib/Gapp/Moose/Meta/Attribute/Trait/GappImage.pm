package Gapp::Moose::Meta::Attribute::Trait::GappImage;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappImage::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Image' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappImage;
{
  $Moose::Meta::Attribute::Custom::Trait::GappImage::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappImage' };
1;
