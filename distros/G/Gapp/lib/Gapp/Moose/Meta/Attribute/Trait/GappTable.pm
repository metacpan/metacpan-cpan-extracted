package Gapp::Moose::Meta::Attribute::Trait::GappTable;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappTable::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Table' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappTable;
{
  $Moose::Meta::Attribute::Custom::Trait::GappTable::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappTable' };
1;
