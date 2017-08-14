package Example::Construction::Counter;

use Mic::Class
    interface => { 
        object => {
            next => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Construction::Acme::Counter';

1;
