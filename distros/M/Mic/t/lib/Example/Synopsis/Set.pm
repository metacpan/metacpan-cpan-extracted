# The evolution of a simple Set class

package Example::Synopsis::Set;

use Mic::Class
    interface => {
        object => {
            add => {},
            has => {},
        },
        class => {
            new => {},
        }
    },

    implementation => 'Example::Synopsis::ArraySet',
    ;
1;
