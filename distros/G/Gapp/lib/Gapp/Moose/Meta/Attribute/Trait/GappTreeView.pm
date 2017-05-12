package Gapp::Moose::Meta::Attribute::Trait::GappTreeView;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappTreeView::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::TreeView' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappTreeView;
{
  $Moose::Meta::Attribute::Custom::Trait::GappTreeView::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappTreeView' };
1;
