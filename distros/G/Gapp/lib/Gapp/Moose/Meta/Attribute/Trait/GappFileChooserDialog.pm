package Gapp::Moose::Meta::Attribute::Trait::GappFileChooserDialog;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappFileChooserDialog::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::FileChooserDialog' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappFileChooserDialog;
{
  $Moose::Meta::Attribute::Custom::Trait::GappFileChooserDialog::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappFileChooserDialog' };
1;
