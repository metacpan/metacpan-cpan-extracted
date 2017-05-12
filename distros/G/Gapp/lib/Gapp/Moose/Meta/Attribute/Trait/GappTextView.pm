package Gapp::Moose::Meta::Attribute::Trait::GappTextView;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappTextView::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::TextView' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappTextView;
{
  $Moose::Meta::Attribute::Custom::Trait::GappTextView::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappTextView' };
1;
