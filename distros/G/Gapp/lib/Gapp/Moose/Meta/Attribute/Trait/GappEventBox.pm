package Gapp::Moose::Meta::Attribute::Trait::GappEventBox;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappEventBox::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::EventBox' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappEventBox;
{
  $Moose::Meta::Attribute::Custom::Trait::GappEventBox::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappEventBox' };
1;
