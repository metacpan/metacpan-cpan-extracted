package Gapp::Moose::Meta::Attribute::Trait::GappFileFilter;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappFileFilter::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::FileFilter' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappFileFilter;
{
  $Moose::Meta::Attribute::Custom::Trait::GappFileFilter::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappFileFilter' };
1;
