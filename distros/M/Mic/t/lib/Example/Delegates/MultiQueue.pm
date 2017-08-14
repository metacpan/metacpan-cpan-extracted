package Example::Delegates::MultiQueue;

use Mic::Class
    interface => { 
        object => {
            multi_push => {},
            multi_pop  => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Delegates::Acme::MultiQueue',
;

1;
