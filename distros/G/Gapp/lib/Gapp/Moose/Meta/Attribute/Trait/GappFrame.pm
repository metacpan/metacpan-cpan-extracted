package Gapp::Moose::Meta::Attribute::Trait::GappFrame;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappFrame::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Frame' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappFrame;
{
  $Moose::Meta::Attribute::Custom::Trait::GappFrame::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappFrame' };
1;
