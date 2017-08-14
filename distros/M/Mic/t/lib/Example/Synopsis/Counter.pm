package Example::Synopsis::Counter;

use Mic::Class
    interface => { 
        object => {
            next => {},
        },
        class => { new => {} }
    },
    implementation => 'Example::Synopsis::Acme::Counter';

1;
