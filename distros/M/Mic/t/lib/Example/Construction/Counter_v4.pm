package Example::Construction::Counter_v4;

use Mic::Class
    interface => { 
        object => {
            next => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Construction::Acme::Counter_v2';

1;
