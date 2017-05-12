package Gapp::Meta::Widget::Native::Role::FormField;
{
  $Gapp::Meta::Widget::Native::Role::FormField::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
with 'Gapp::Meta::Widget::Native::Role::FormElement';

# the field name to use when storing the value
has 'field' => (
    is => 'rw',
    isa => 'Maybe[Str]',
    default => undef,
);

# is true if the widget is currently being updated
# used to prevent recursive updates
has 'is_updating' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

# called after a fields value is changed
has 'on_change' => (
    is => 'rw',
    isa => 'CodeRef|Undef',
);

# block the on_change handler
has 'block_on_change' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


sub _widget_value_changed {
    my ( $self ) = @_; # $self = the form field
    return if $self->is_updating;
    
    my $form = $self->form;
    
    if ( $form && $self->field ) {
        $self->widget_to_stash( $form->stash );
        
        if ( $self->field && $form->sync && $form->context ) {
            $form->context->modify( $self->field, $form->stash->fetch( $self->field ) )
        }
    }
    if ( ! $self->block_on_change && ! $self->is_updating ) {
        $self->on_change->( $self ) if $self->on_change;
    }
    
}

before _apply_signals => sub {
    my ( $self ) = @_;
    $self->_connect_changed_handler if $self->can('_connect_changed_handler');
};

sub update {
    my ( $self ) = @_;
    $self->set_is_updating( 1 );
    $self->stash_to_widget( $self->form->stash ) if $self->field;
    $self->set_is_updating( 0 );
}


sub enable {
    my ( $self ) = @_;
    $self->gobject->set_sensitive( 1 );
}

sub disable {
    my ( $self ) = @_;
    $self->gobject->set_sensitive( 0 );
}



package Gapp::Meta::Widget::Custom::Trait::FormField;
{
  $Gapp::Meta::Widget::Custom::Trait::FormField::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Role::FormField' };


1;