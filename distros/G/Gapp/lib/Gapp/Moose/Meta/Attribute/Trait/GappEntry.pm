package Gapp::Moose::Meta::Attribute::Trait::GappEntry;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappEntry::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Entry' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappEntry;
{
  $Moose::Meta::Attribute::Custom::Trait::GappEntry::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappEntry' };
1;
