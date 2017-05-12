package Gapp::Moose::Meta::Attribute::Trait::GappLabel;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappLabel::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Label' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappLabel;
{
  $Moose::Meta::Attribute::Custom::Trait::GappLabel::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappLabel' };
1;
