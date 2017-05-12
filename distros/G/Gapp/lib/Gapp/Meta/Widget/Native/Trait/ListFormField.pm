package Gapp::Meta::Widget::Native::Trait::ListFormField;
{
  $Gapp::Meta::Widget::Native::Trait::ListFormField::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
with 'Gapp::Meta::Widget::Native::Role::FormField';


has 'value_column' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);


# returns the value of the widget
sub get_field_value {
    my $self = shift;
    
    my $model = $self->gobject->get_model;
    my $iter = $model->get_iter_first;
    
    my @values;
    while ( $iter ) {
        my $o = $model->get( $iter, $self->value_column );
        $iter = $model->iter_next( $iter );
        push @values, $o;
    }
    
    return \@values;
}

sub set_field_value {
    my ( $self, $value ) = @_;
    
    my $model = $self->gobject->get_model;
    $model->clear;
    
    if ( $value ) {
        $model->append( $_ ) for @$value;
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
      row_inserted => sub { $self->_widget_value_changed },
    );
    $self->gobject->get_model->signal_connect (
      row_deleted => sub { $self->_widget_value_changed },
    );
}


package Gapp::Meta::Widget::Custom::Trait::ListFormField;
{
  $Gapp::Meta::Widget::Custom::Trait::ListFormField::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Trait::ListFormField' };


1;