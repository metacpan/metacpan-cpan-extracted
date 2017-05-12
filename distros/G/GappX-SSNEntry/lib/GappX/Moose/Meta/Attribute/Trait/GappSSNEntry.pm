package GappX::Moose::Meta::Attribute::Trait::GappSSNEntry;
{
  $GappX::Moose::Meta::Attribute::Trait::GappSSNEntry::VERSION = '0.02';
}
use Moose::Role;

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    $opts->{gclass} = 'GappX::SSNEntry' if ! exists $opts->{class};
};

package Moose::Meta::Attribute::Custom::Trait::GappSSNEntry;
{
  $Moose::Meta::Attribute::Custom::Trait::GappSSNEntry::VERSION = '0.02';
}
sub register_implementation { 'GappX::Moose::Meta::Attribute::Trait::GappSSNEntry' };
1;
