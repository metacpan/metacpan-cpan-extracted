package Gapp::Meta::Widget::Native::Trait::AssistantPage;
{
  $Gapp::Meta::Widget::Native::Trait::AssistantPage::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;
use MooseX::LazyRequire;


has 'page_title' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'page_type' => (
    is => 'rw',
    isa => 'Str',
    default => '',
    lazy_required => 1,
);

has 'page_icon' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'page_num' => (
    is => 'rw',
    isa => 'Int|Undef',
);

# the validator function is valled to determine if the page is complete
# the code-ref should return true for complete, false for not
has 'validator' => (
    is => 'rw',
    isa => 'Maybe[CodeRef]',
);

# call validate to validate the page
sub validate {
    my ( $self ) = shift;
    return if ! $self->validator;
    
    my $valid = $self->validator->( $self );
    
    if ( ! $self->parent ) {
        warn qq[could not mark page ($self) as complete: ] .
             qq[you must add this page to an assistant first];
        return $valid;
    }
    
    $self->parent->gobject->set_page_complete( $self->gobject, $valid );
    return $valid;
}



package Gapp::Meta::Widget::Custom::Trait::AssistantPage;
{
  $Gapp::Meta::Widget::Custom::Trait::AssistantPage::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Trait::AssistantPage' };


1;