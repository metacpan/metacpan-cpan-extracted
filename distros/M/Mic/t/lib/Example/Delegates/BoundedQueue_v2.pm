package Example::Delegates::BoundedQueue_v2;

use Mic::Class
    interface => { 
        object => {
            push  => {},
            q_pop => {},
            q_size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Delegates::Acme::BoundedQueue_v2',
;

1;
