package Gapp::Moose::Meta::Attribute::Trait::GappDateEntry;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappDateEntry::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::DateEntry' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappDateEntry;
{
  $Moose::Meta::Attribute::Custom::Trait::GappDateEntry::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappDateEntry' };
1;
