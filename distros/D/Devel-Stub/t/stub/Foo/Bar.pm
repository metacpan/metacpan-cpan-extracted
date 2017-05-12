package Foo::Bar;
use Devel::Stub on => "t/lib";

stub woo => sub {
    "oh!";
};

stub poo => sub {
    my ($self,$p) = @_;
    if($p == 2){
        return _original(@_);
    } elsif( $p == 3){
        return $self->_original($p);        
    }
    
    "stubed!";
};

stub TAG => ["moge"],too => sub {
    "xxxx";
};

stub 
    TAG => ["tag","devel","foo"],
    too => sub {
        "tagged";
};

stub qoo => sub {
    "tagged";
}, TAG => "staging";


1;
