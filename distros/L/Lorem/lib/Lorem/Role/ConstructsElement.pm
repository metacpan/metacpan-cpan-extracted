package Lorem::Role::ConstructsElement;
{
  $Lorem::Role::ConstructsElement::VERSION = '0.22';
}

use MooseX::Role::Parameterized;
use MooseX::SemiAffordanceAccessor;

parameter name => (
    isa      => 'Str',
);

parameter class => (
    isa      => 'Str',
);

parameter method => (
    isa      => 'Str',
);

use TryCatch;

parameter function => (
    is => 'rw',
    isa => 'CodeRef',
    default => sub {
        my $p = shift;
        return sub {
            my $self = shift;
            try {
                my $new  = $p->class->new( parent => $self, @_ );
                $self->append_element( $new );
                return $new;
            }
            catch ( $e ) {
                confess $e;
            }
        }
    }
);

role {
    my $p = shift;
    
    my $constructor = $p->function;
    my $method_name;
    
    if ($p->method) {
        $method_name = $p->method;
    }
    elsif ($p->name) {
        $method_name = 'new_' . $p->name;
    }
    else {
        $p->class =~ /(\w+)$/;
        my $string = $1;
        $string =~ s/^([A-Z+])/lc $1/e;
        $string =~ s/[A-Z+]/'_' . lc($1)/e;
        $method_name = 'new_' . $string;
    }
    
    method $method_name => $constructor;
};

1;
