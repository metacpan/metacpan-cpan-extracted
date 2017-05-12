package Gapp::Moose::Meta::Attribute::Trait::GappTimeEntry;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappTimeEntry::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::TimeEntry' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappTimeEntry;
{
  $Moose::Meta::Attribute::Custom::Trait::GappTimeEntry::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappTimeEntry' };
1;
