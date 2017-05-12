package Gapp::Moose::Meta::Attribute::Trait::GappFileChooserButton;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappFileChooserButton::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::FileChooserButton' if ! exists $opts->{class};
};

has 'action' => (
    is => 'rw',
    isa => 'Str',
    default => 'open',
);

has 'filters' => (
    isa => 'ArrayRef',
    default => sub { [] },
    traits => [qw( Array )],
    handles => {
        add_filter => 'push',
        filters => 'elements',
    }
);



before '_build_gobject' => sub {
    my $self = shift;
    $self->set_args( [ $self->properties->{title} ? $self->properties->{title} : '' ,
                      $self->parent ? $self->parent->gobject : undef,
                      $self->action ] );
};
   

package Moose::Meta::Attribute::Custom::Trait::GappFileChooserButton;
{
  $Moose::Meta::Attribute::Custom::Trait::GappFileChooserButton::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappFileChooserButton' };
1;
