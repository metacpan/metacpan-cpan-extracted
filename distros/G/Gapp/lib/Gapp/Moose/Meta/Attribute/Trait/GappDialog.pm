package Gapp::Moose::Meta::Attribute::Trait::GappDialog;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappDialog::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::Dialog' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappDialog;
{
  $Moose::Meta::Attribute::Custom::Trait::GappDialog::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappDialog' };
1;
