package Example::Delegates::BoundedQueue;

use Mic::Class
    interface => { 
        object => {
            push => {},
            pop  => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Delegates::Acme::BoundedQueue_v1',
;

1;
