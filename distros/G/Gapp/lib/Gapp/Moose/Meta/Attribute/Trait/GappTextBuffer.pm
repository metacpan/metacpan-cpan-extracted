package Gapp::Moose::Meta::Attribute::Trait::GappTextBuffer;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappTextBuffer::VERSION = '0.60';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'Gapp::TextBuffer' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappTextBuffer;
{
  $Moose::Meta::Attribute::Custom::Trait::GappTextBuffer::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappTextBuffer' };
1;
