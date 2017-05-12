package Gapp::Moose::Meta::Attribute::Trait::GappAssistant;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappAssistant::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Assistant' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappAssistant;
{
  $Moose::Meta::Attribute::Custom::Trait::GappAssistant::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappAssistant' };
1;
