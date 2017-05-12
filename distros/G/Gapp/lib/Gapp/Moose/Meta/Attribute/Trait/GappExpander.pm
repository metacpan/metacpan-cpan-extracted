package Gapp::Moose::Meta::Attribute::Trait::GappExpander;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappExpander::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Expander' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappExpander;
{
  $Moose::Meta::Attribute::Custom::Trait::GappExpander::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappExpander' };
1;
