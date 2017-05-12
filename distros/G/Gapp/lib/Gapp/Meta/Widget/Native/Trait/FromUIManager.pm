package Gapp::Meta::Widget::Native::Trait::FromUIManager;
{
  $Gapp::Meta::Widget::Native::Trait::FromUIManager::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
use MooseX::LazyRequire;

use Gapp::Types qw( GappUIManager );

has 'ui' => (
    is => 'rw',
    isa => GappUIManager,
    coerce => 1,
    lazy_required => 1,
);

has 'ui_widget' => (
    is => 'rw',
    isa => 'Str',
    lazy_required => 1,
);

around '_construct_gobject' => sub {
    my ( $orig, $self ) = @_;
    my $w = $self->ui->gobject->get_widget( $self->ui_widget );
    
    if ( ! $w ) {
        $self->meta->throw_error(
            q[could not find widget ] . $self->ui_widget . q[ in: ] .
            ( scalar @{ $self->ui->files } ?
            join ( ',' , @{ $self->ui->files } ) :
            '(no files in ui)' )
        )
    }
    else {
        $self->set_gobject( $w );
        return $w;
    }
    
};


package Gapp::Meta::Widget::Custom::Trait::FromUIManager;
{
  $Gapp::Meta::Widget::Custom::Trait::FromUIManager::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Trait::FromUIManager' };


1;