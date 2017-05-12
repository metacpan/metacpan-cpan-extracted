package Gapp::Moose::Meta::Attribute::Trait::GappWidget;
{
  $Gapp::Moose::Meta::Attribute::Trait::GappWidget::VERSION = '0.60';
}
use Moose::Role;

use MooseX::Types::Moose qw( ArrayRef CodeRef HashRef Int Str Undef );

has 'gclass' => (
    is => 'rw',
    isa => 'Str',
);

has 'construct' => (
    is => 'rw',
    isa => 'ArrayRef|CodeRef|Int|Undef',
);

has 'constructor' => (
    is => 'rw',
    isa => 'Str',
    default => 'new',
);

before '_process_options' => sub {
    my ( $class, $name, $opts ) = @_;
    
    if ( $opts->{construct} ) {
        warn 'you provided a construct argument and a default' if $opts->{default};
        warn 'you provided a construct argument and a builder' if $opts->{builder};
        
        $opts->{default} = sub {
            my ( $self ) = @_;
            my $att = $self->meta->find_attribute_by_name( $name );
            
            my $wclass = $att->gclass;
            my $wmethod = $att->constructor;
            
            if ( ! $wclass ) {
                confess "Could not consruct widget '$name', you did not supply a widget class";
            }
            
            my %opts;
            for ( $att->construct ) {
                last if is_Int( $_ ) && $_;
                %opts = %$_ and last if is_HashRef( $_ );
                %opts = ( @$_ ) and last if is_ArrayRef( $_ );
                %opts = $_->( $self ) and last if is_CodeRef( $_ );
            }
            
            my $w = $wclass->$wmethod( %opts );
            
            return $w;
        };
    }
    $opts->{is} = 'ro' if ! exists $opts->{is};
    $opts->{lazy} = 1 if ! exists $opts->{lazy};
    
};

package Moose::Meta::Attribute::Custom::Trait::GappWidget;
{
  $Moose::Meta::Attribute::Custom::Trait::GappWidget::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Moose::Meta::Attribute::Trait::GappWidget' };

1;
