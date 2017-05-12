package Gapp::Moose::Meta::Attribute::Trait::GappTextTagTable;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappTextTagTable::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::TextTagTable' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappTextTagTable;
{
  $Moose::Meta::Attribute::Custom::Trait::GappTextTagTable::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappTextTagTable' };
1;
