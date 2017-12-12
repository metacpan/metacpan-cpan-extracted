use strict;
use Test::Lib;
use Test::Most;

{
    package Person;
    use Mic ();

    our $Error;
    
    eval { 
        Mic->assemble({
            interface => { 
                object => {
                    greet => {},
                    name => {},
                },
                class => { new => {} }
            },
            implementation => 'PersonImpl',
        });
    }
      or $Error = $@;
}

{
    package PersonImpl;

    use Mic::Impl
        has => { NAME => { reader => 'nmae' } }
    ;

    sub greet {
        my ($self) = @_;
        return "Hello ".$self->[NAME];
    }
}


package main;

like($Person::Error, qr"Interface method 'name' is not implemented.");

done_testing();
