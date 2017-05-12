package Gapp::Meta::Widget::Native::Trait::NotebookPage;
{
  $Gapp::Meta::Widget::Native::Trait::NotebookPage::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;


has 'detachable' => (
    is => 'rw',
    isa => 'Maybe[Bool]',
);

has 'menu_label' => (
    is => 'rw',
    isa => 'Maybe[Gapp::Widget]',
);

has 'position' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'reorderable' => (
    is => 'rw',
    isa => 'Maybe[Bool]',
);

has 'tab_expand' => (
    is => 'rw',
    isa => 'Maybe[Bool]',
);

has 'tab_fill' => (
    is => 'rw',
    isa => 'Maybe[Bool]',
);

has 'tab_label' => (
    is => 'rw',
    isa => 'Maybe[Gapp::Widget]',
);

has 'tab_pack' => (
    is => 'rw',
    isa => 'Maybe[Str]'
);

has 'page_name' => (
    is => 'rw',
    isa => 'Str',
    default => '',
    trigger => sub {
        my ( $self, $new, $old ) = @_;
        return if ! $self->has_gobject;
        return if ! $self->parent;
        
        if ( ! defined $self->tab_label ) {
            $self->parent->gobject->set_tab_label_text( $self->gobject, $new );
        }
        else {
            $self->tab_label->content->[0]->gobject->set_text( $new);
        }
        
        if ( ! defined $self->menu_label ) {
            $self->parent->gobject->set_menu_label_text( $self->gobject, $new );
        }
        else {
            $self->menu_label->content->[0]->gobject->set_text( $new);
        }
        
    }
);


package Gapp::Meta::Widget::Custom::Trait::NotebookPage;
{
  $Gapp::Meta::Widget::Custom::Trait::NotebookPage::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Trait::NotebookPage' };


1;