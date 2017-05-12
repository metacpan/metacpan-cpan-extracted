package Gapp::Meta::Attribute::Trait::GappDefault;
{
  $Gapp::Meta::Attribute::Trait::GappDefault::VERSION = '0.60';
}
use Moose::Role;

use MooseX::Types::Moose qw( ArrayRef HashRef );

before '_process_options' => sub {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    my @handles = qw( destroy hide present show show_all signal_connect signal_emit );

    if ( is_ArrayRef( $options->{handles} ) ) {
        push @{ $options->{handles} }, @handles;
    }
    elsif ( is_HashRef( $options->{handles} ) ) {
        map { $options->{handles}{$_} = $_ } @handles;
    }
    else {
        $options->{handles} = \@handles;
    }

};


package Moose::Meta::Attribute::Custom::Trait::GappDefault;
{
  $Moose::Meta::Attribute::Custom::Trait::GappDefault::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Attribute::Trait::GappDefault' };

1;
