package Example::Construction::Set_v2;

use Mic::Class

    interface => { 
        object => {
            add => {},
            has => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Construction::Acme::Set_v2',
;

1;
