package Gapp::Moose::Meta::Attribute::Trait::GappListStore;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappListStore::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::ListStore' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappListStore;
{
  $Moose::Meta::Attribute::Custom::Trait::GappListStore::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappListStore' };
1;
