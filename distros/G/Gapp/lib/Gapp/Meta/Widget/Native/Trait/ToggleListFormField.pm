package Gapp::Meta::Widget::Native::Trait::ToggleListFormField;
{
  $Gapp::Meta::Widget::Native::Trait::ToggleListFormField::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
with 'Gapp::Meta::Widget::Native::Role::FormField';


has 'value_column' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'toggle_column' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

has 'equality_func' => (
    is => 'rw',
    isa => 'CodeRef',
    default => sub { sub { $_[0] } },
);


# returns the value of the widget
sub get_field_value {
    my $self = shift;
    
    my $model = $self->gobject->get_model;
    my $iter = $model->get_iter_first;
    
    my @values;
    while ( $iter ) {
        if ( $model->get( $iter, $self->toggle_column ) ) {
            my $o = $model->get( $iter, $self->value_column );
            push @values, $o;
        }
        $iter = $model->iter_next( $iter );
    }
    
    return \@values;
}

sub set_field_value {
    my ( $self, $value ) = @_;
    
    my $model = $self->gobject->get_model;
    my $iter = $model->get_iter_first;
    
    my %values;
    for ( @{$value} ) {
        $values{$self->equality_func->( $_ )} = $_;
    }
    
    my @values;
    while ( $iter ) {
        
        my $check = $model->get( $iter, $self->value_column );
        
        if ( $values{$self->equality_func->( $check )} ) {
            $model->set( $iter, $self->toggle_column => 1 );
        }
        
        $iter = $model->iter_next( $iter );
    }
}

sub widget_to_stash {
    my ( $self, $stash ) = @_;
    $stash->store( $self->field, $self->get_field_value );
}

sub stash_to_widget {
    my ( $self, $stash ) = @_;
    $self->set_field_value( $stash->fetch( $self->field ) );
}

sub _connect_changed_handler {
    my ( $self ) = @_;
    
    $self->gobject->get_model->signal_connect (
      row_changed => sub { $self->_widget_value_changed },
    );
}


package Gapp::Meta::Widget::Custom::Trait::ToggleListFormField;
{
  $Gapp::Meta::Widget::Custom::Trait::ToggleListFormField::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Trait::ToggleListFormField' };


1;