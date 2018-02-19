package Example::Overloads::Set;

use Mic::Class
    interface => {
        object => {
            add => {},
            has => {},
            to_str => { overloads => '""' },
        },
        class => {
            new => {},
        }
    },

    implementation => 'Example::Overloads::HashSet',
    ;
1;
