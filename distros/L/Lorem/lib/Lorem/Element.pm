package Lorem::Element;
{
  $Lorem::Element::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Scalar::Util qw( refaddr );

use Lorem::Types qw( LoremDocumentObject );

with 'Lorem::Role::HasSizeAllocation';
with 'Lorem::Role::HasStyle';

has 'doc' => (
    is => 'rw',
    isa => 'Maybe[Lorem::Document]',
    weak_ref => 1,
    trigger => sub {
        my $self = shift;
        $self->_on_set_doc( @_ );
    }
);

has 'parent' => (
    is => 'rw',
    isa => LoremDocumentObject,
    trigger => sub {
        my $self = shift;
        $self->set_doc( $_[0] ? $_[0]->doc : undef );
        $self->_on_set_parent( @_ );
    },
    weak_ref => 1,
    required => 0,
);

has 'children' => (
    is  => 'ro',
    isa => 'ArrayRef',
    traits => [qw/Array/],
    default => sub { [ ] },
    handles => {
        'get_child'  => 'get',
        'delete_child' => 'delete',
        '_add_child' => 'push',
        'pop_child' => 'pop',
    }
);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

sub append_element {
    my ( $self, @elements ) = @_;
    
    for my $e ( @elements ) {
        $e->set_parent( $self );
        $self->_add_child( $e );
    }
    
    return @elements;
}

sub _on_set_parent {
    
}

sub _on_set_doc {
    
}


1;
